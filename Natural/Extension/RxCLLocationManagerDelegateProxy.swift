//
//  RxCLLocationManagerDelegateProxy.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/07.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    
    //https://github.com/ReactiveX/RxSwift/blob/main/RxExample/Extensions/RxCLLocationManagerDelegateProxy.swift 에 있는 init메소드와 registerKnownImplementations 메소드가 하나로 합쳐진 형태
    static func registerKnownImplementations() {
        self.register { locationManager -> RxCLLocationManagerDelegateProxy in
            RxCLLocationManagerDelegateProxy(parentObject: locationManager, delegateProxy: self)
        }
    }
    
    //currentDelegate와 setCurrentDelegate 메소드는 https://github.com/ReactiveX/RxSwift/blob/main/RxExample/Extensions/RxCLLocationManagerDelegateProxy.swift 의 extension CLLocationManager: HasDelegate { public typealias Delegate = CLLocationManagerDelegate } 로 대체 될 수 있다. -> object로 delegate에 직접 접근이 불가능한 NMFMapView CameraDelegate같은 경우에 유용하려나?
    static func currentDelegate(for object: CLLocationManager) -> CLLocationManagerDelegate? {
        object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: CLLocationManagerDelegate?, to object: CLLocationManager) {
        object.delegate = delegate
    }
    
    internal lazy var didUpdateLocationsSubject = PublishSubject<[CLLocation]>()
    internal lazy var didFailWithErrorSubject = PublishSubject<Error>()
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        _forwardToDelegate?.locationManager?(manager, didUpdateLocations: locations)
        didUpdateLocationsSubject.onNext(locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _forwardToDelegate?.locationManager(manager, didFailWithError: error)
        didFailWithErrorSubject.onNext(error)
    }
    
    deinit {
        self.didUpdateLocationsSubject.on(.completed)
        self.didFailWithErrorSubject.on(.completed)
    }
}
