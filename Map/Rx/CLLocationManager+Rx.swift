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

//NMFLocationManager에 대한 Reactive Extension을 할 수도 있지만 해당 Manager와 Delegate가 어차피 CLLocationManager, Delegate를 상속/채택하였으므로 CLLocation으로 작성해도 된다. 
class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    static func registerKnownImplementations() {
        <#code#>
    }
    
    static func currentDelegate(for object: CLLocationManager) -> CLLocationManagerDelegate? {
        <#code#>
    }
    
    static func setCurrentDelegate(_ delegate: CLLocationManagerDelegate?, to object: CLLocationManager) {
        <#code#>
    }
    
}

extension Reactive where Base: CLLocationManager {
    
}
