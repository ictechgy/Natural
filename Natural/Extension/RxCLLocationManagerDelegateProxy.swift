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
    static func registerKnownImplementations() {
        self.register { locationManager -> RxCLLocationManagerDelegateProxy in
            RxCLLocationManagerDelegateProxy(parentObject: locationManager, delegateProxy: self)
        }
    }
    
    static func currentDelegate(for object: CLLocationManager) -> CLLocationManagerDelegate? {
        object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: CLLocationManagerDelegate?, to object: CLLocationManager) {
        object.delegate = delegate
    }
    
}
