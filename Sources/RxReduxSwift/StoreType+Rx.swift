//
//  StoreType+Rx.swift
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

import ReduxSwift
import RxSwift

extension Store: ReactiveCompatible {
}

public extension Reactive where Base: StoreType {

    private var stateObservable: Observable<Base.S> {
        let object = objc_getAssociatedObject(
            self,
            &RxStoreAssociatedObjectKey.stateObservable
        )
        if let observable = object as? Observable<Base.S> {
            return observable
        }
        let observable = Observable<Base.S>.create { [weak base = base] observer in
            let subscriber = AnonymousSubscriber<Base.S> {
                observer.on(.next($0))
            }
            base?.subscribe(subscriber)
            return Disposables.create {
                base?.unsubscribe(subscriber)
            }
        }
        .startWith(base.state)

        objc_setAssociatedObject(
            self,
            &RxStoreAssociatedObjectKey.stateObservable,
            observable,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return observable
    }

    public func dispatch() -> AnyObserver<Action> {
        return AnyObserver { [weak base = base] event in
            if case let .next(action) = event {
                base?.dispatch(action)
            }
        }
    }

    public var state: Observable<Base.S> {
        return stateObservable
    }
}

private struct RxStoreAssociatedObjectKey {
    static var stateObservable: UInt8 = 0
}
