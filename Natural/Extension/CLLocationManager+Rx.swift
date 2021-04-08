//
//  CLLocationManager+Rx.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/27.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

/*
 NMFLocationManager가 CLLocationManagerDelegate를 채택한 것을 보고 조금 헷갈렸었으나 아래와 같이 일단 정리해보았다. (명확하지 않음)
 - NMFLocationManager는 직접 CLLocationManagerDelegate를 채택하였고 필요한 (대부분의) 메소드들을 구현해놓은 뒤 내부적으로 CLLocationManager 인스턴스를 가지고 있는다. 그리고 해당 인스턴스의 delegate로서 자기자신(self)을 지정한다.
 - NMFMapView에서 사용자의 위치 등을 필요로 할 때 이 NMFLocationManager의 sharedInstance를 통해 몇가지 요청을 하고, NMFLocationManager는 해당 요청에 처리를 시작한다. 처리는 내부 프로퍼티인 CLLocationManager 인스턴스를 이용한다. (스스로 CLLocationManagerDelegate를 채택하고 구현한 것을 이용할 것임)
 - CLLocationManagerDelegate 메소드 콜백에 따라 NMFLocationManager 스스로 결과를 받고, 이후 NMFLocationManager는 해당 결과 값을 처리한 뒤 MapView에 전달한다.
 (CLLocationManager 인스턴스는 꼭 NMFLocationManager 내부에 있을 필요는 없다. MapView가 직접적으로 CLLocationManager를 이용하고, 해당 CLLocationManager의 delegate로 NMFLocationManager가 지정되어 있어도 된다.)
 
 ** 그렇다면 궁금할 수 있다. NMFLocationManagerDelegate는 무엇인가? CLLocationManagerDelegate와 동일한 메소드들을 가지고 있는데?
    이는 다음과 같이 볼 수 있다고 생각한다. (이 또한 명확한 것은 아니다.)
 - NMFLocationManager에는 별도로 NMFLocationManagerDelegate를 지정할 수 있는데 이는 CLLocationManagerDelegate와 동일하지 않으며 부가적 요소이다.
 - 예를 들어본다면. VC가 NMFLocationManagerDelegate를 채택하고 필요한 메소드들을 구현했다고 하자. 이후 NMFLocationManager sharedInstance의 add(delegate: self)로 VC가 지정되었다.
 - MapView가 NMFLocationManager sharedInstance에 어떤 요청을 했을 때 NMFLocationManager는 내부 CLLocationManager를 통해 처리를 시작하고 결과값을 CLLocationManagerDelegate 콜백으로 받는다. 이후 NMFLocationManager는 MapView에 결과를 처리하여 보냄과 동시에 NMFLocationManagerDelegate(VC)에도 결과를 보낸다. CLLocationManagerDelegate 구현 메소드로 받은 parameter들을 그대로 NMFLocationManagerDelegate 메소드의 인자로 전송하면서 호출
 - 즉 CLLocationManagerDelegate와 NMFLocationManagerDelegate의 메소드들은 같아보이지만(실제로도 이름이나 인자, 타입 등이 동일하지만) 전혀 다른 프로토콜이다.
 
 -> 결론.
 1. 여기서 CLLocationManagerDelegateProxy를 만들든, NMFLocaitonManagerDelegateProxy를 만들든 큰 차이는 존재하지 않는다. (동일한 상황 시 똑같이 호출될 것)
 다만 NMFLocationManager으로는 NMFLocationManagerDelegate를 직접적으로 접근할 수가 없다. (add, remove 메소드만 존재)
 이에 대해 NMFMapView cameraDelegate에서 했던 것처럼 Delegate를 static 프로퍼티로 별도 접근하는 방법을 고려해볼 수도 있을 것이다.
 2. CLLocationManagerDelegateProxy를 만든다면, MapView를 가지고 있는 VC에서 CLLocationManager 객체를 만들고 이를 스트림형식으로 이용할 텐데, NMFLocationManager에 의한 CLLocationManager 하나, VC에 의한 CLLocationManager 하나, 인스턴스가 총 2개가 만들어질 수 있다.
    (기기로부터 이벤트를 받는 것은 두 인스턴스가 동일? ex. 위치 데이터, 권한 변경 등)
 */

extension Reactive where Base: CLLocationManager {
    
    /**
        Reactive wrapper for `delegate`.
        For more information take a look at `DelegateProxyType` protocol documentation.
    */
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: self.base)
    }
    
    /*
     //MARK: 내가 작성했던 프로퍼티들
    var locationManagerDidChangeAuthorization: Observable<Void> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)))
            .map { _ in
                return          //메소드 parameter로는 CLLocationManager가 있는데, 굳이 스트림에 싣지 않아도 된다.
            }
    }
    
    var didFailWithError: Observable<Error> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didFailWithError:)))
            .map { parameters in
                return parameters[1] as? Error ?? NSError()
            }
    }
     */
    
    // MARK: Responding to Location Events - 위치관련 이벤트에 응답
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didUpdateLocations: Observable<[CLLocation]> {
            RxCLLocationManagerDelegateProxy.proxy(for: base).didUpdateLocationsSubject.asObservable()
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var didFailWithError: Observable<Error> {
            RxCLLocationManagerDelegateProxy.proxy(for: base).didFailWithErrorSubject.asObservable()
        }

        #if os(iOS) || os(macOS)
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didFinishDeferredUpdatesWithError: Observable<Error?> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didFinishDeferredUpdatesWithError:)))
                .map { a in
                    return try castOptionalOrThrow(Error.self, a[1])
                }
        }
        #endif

        #if os(iOS)

        // MARK: Pausing Location Updates
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didPauseLocationUpdates: Observable<Void> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManagerDidPauseLocationUpdates(_:)))
                .map { _ in
                    return ()
                }
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var didResumeLocationUpdates: Observable<Void> {
            return delegate.methodInvoked( #selector(CLLocationManagerDelegate.locationManagerDidResumeLocationUpdates(_:)))
                .map { _ in
                    return ()
                }
        }

        // MARK: Responding to Heading Events
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didUpdateHeading: Observable<CLHeading> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateHeading:)))
                .map { a in
                    return try castOrThrow(CLHeading.self, a[1])
                }
        }

        // MARK: Responding to Region Events
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didEnterRegion: Observable<CLRegion> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didEnterRegion:)))
                .map { a in
                    return try castOrThrow(CLRegion.self, a[1])
                }
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var didExitRegion: Observable<CLRegion> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didExitRegion:)))
                .map { a in
                    return try castOrThrow(CLRegion.self, a[1])
                }
        }

        #endif

        #if os(iOS) || os(macOS)

        /**
        Reactive wrapper for `delegate` message.
        */
        @available(OSX 10.10, *)
        public var didDetermineStateForRegion: Observable<(state: CLRegionState, region: CLRegion)> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didDetermineState:for:)))
                .map { a in
                    let stateNumber = try castOrThrow(NSNumber.self, a[1])
                    let state = CLRegionState(rawValue: stateNumber.intValue) ?? CLRegionState.unknown
                    let region = try castOrThrow(CLRegion.self, a[2])
                    return (state: state, region: region)
                }
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var monitoringDidFailForRegionWithError: Observable<(region: CLRegion?, error: Error)> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:monitoringDidFailFor:withError:)))
                .map { a in
                    let region = try castOptionalOrThrow(CLRegion.self, a[1])
                    let error = try castOrThrow(Error.self, a[2])
                    return (region: region, error: error)
                }
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var didStartMonitoringForRegion: Observable<CLRegion> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didStartMonitoringFor:)))
                .map { a in
                    return try castOrThrow(CLRegion.self, a[1])
                }
        }

        #endif

        #if os(iOS)

        // MARK: Responding to Ranging Events
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didRangeBeaconsInRegion: Observable<(beacons: [CLBeacon], region: CLBeaconRegion)> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didRangeBeacons:in:)))
                .map { a in
                    let beacons = try castOrThrow([CLBeacon].self, a[1])
                    let region = try castOrThrow(CLBeaconRegion.self, a[2])
                    return (beacons: beacons, region: region)
                }
        }

        /**
        Reactive wrapper for `delegate` message.
        */
        public var rangingBeaconsDidFailForRegionWithError: Observable<(region: CLBeaconRegion, error: Error)> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:rangingBeaconsDidFailFor:withError:)))
                .map { a in
                    let region = try castOrThrow(CLBeaconRegion.self, a[1])
                    let error = try castOrThrow(Error.self, a[2])
                    return (region: region, error: error)
                }
        }

        // MARK: Responding to Visit Events
        /**
        Reactive wrapper for `delegate` message.
        */
        @available(iOS 8.0, *)
        public var didVisit: Observable<CLVisit> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didVisit:)))
                .map { a in
                    return try castOrThrow(CLVisit.self, a[1])
                }
        }

        #endif

        // MARK: Responding to Authorization Changes
        /**
        Reactive wrapper for `delegate` message.
        */
        public var didChangeAuthorizationStatus: Observable<CLAuthorizationStatus> {
            return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorization:)))
                .map { a in
                    let number = try castOrThrow(NSNumber.self, a[1])
                    return CLAuthorizationStatus(rawValue: Int32(number.intValue)) ?? .notDetermined
                }
        }
    }


    private func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
        guard let returnValue = object as? T else {
            throw RxCocoaError.castingError(object: object, targetType: resultType)
        }

        return returnValue
    }

    private func castOptionalOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T? {
        if NSNull().isEqual(object) {
            return nil
        }

        guard let returnValue = object as? T else {
            throw RxCocoaError.castingError(object: object, targetType: resultType)
        }

        return returnValue
}
