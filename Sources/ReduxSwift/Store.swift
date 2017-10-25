//
//  Store.swift
//
//  Copyright (c) 2017 Jaesung Jung. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

public class Store<S: State>: StoreType {
    private let reducer: Reducer<S>
    private let middlewares: [Middleware<Store<S>>]
    private var subscribers: [SubscriberBox] = []

    public private(set) var state: S {
        didSet { publish(state: state) }
    }

    public init(
        initialState: S,
        reducer: @escaping Reducer<S>,
        middlewares: [Middleware<Store<S>>] = []) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }

    public func dispatch(_ action: Action) {
        let dispatch: (Action) -> Void = { [weak self] action in
            guard let `self` = self else { return }
            self.state = self.reducer(self.state, action)
        }
        // dispatch(action) -> middlewares... -> reducer
        let dispatchFunction = middlewares
            .reversed()
            .reduce(dispatch) { [weak self] next, middleware in
                return { action in
                    guard let `self` = self else { return }
                    middleware(self, action, next)
                }
            }
        dispatchFunction(action)
    }

    public func dispatch(_ thunk: ActionThunk<S>?) {
        thunk?(state, self)
    }

    public func subscribe<StoreSubscriber: Subscriber>(
        _ subscriber: StoreSubscriber)
        where StoreSubscriber.S == S  {
        subscribers.append(SubscriberBox(
            subscriber: subscriber,
            newState: subscriber.newState
        ))
        subscriber.newState(state)
    }

    public func unsubscribe<StoreSubscriber: Subscriber>(
        _ subscriber: StoreSubscriber)
        where StoreSubscriber.S == S {
        guard let index = subscribers.index(where: { $0.subscriber === subscriber }) else {
            return
        }
        subscribers.remove(at: index)
    }

    private func publish(state: S) {
        subscribers.forEach {
            $0.newState(state)
        }
    }

    private class SubscriberBox {
        let subscriber: AnyObject
        let newState: (S) -> Void

        init(subscriber: AnyObject, newState: @escaping (S) -> Void) {
            self.subscriber = subscriber
            self.newState = newState
        }
    }
}
