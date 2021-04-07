//
//  RxNMFMapViewCameraDelegateProxy.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/06.
//

import Foundation
import RxSwift
import RxCocoa
import NMapsMap

class RxNMFMapViewCameraDelegateProxy: DelegateProxy<NMFMapView, NMFMapViewCameraDelegate>, DelegateProxyType, NMFMapViewCameraDelegate {
    
    private static weak var cameraDelegate: NMFMapViewCameraDelegate?    //delegate 별도로 참조(weak)
    
    static func registerKnownImplementations() {
        self.register { mapView -> RxNMFMapViewCameraDelegateProxy in
            RxNMFMapViewCameraDelegateProxy(parentObject: mapView, delegateProxy: self)
        }
    }
    
    static func currentDelegate(for object: NMFMapView) -> NMFMapViewCameraDelegate? {
        self.cameraDelegate
        //object를 통해 CameraDelegate를 별도로 반환할 수가 없어서 static 프로퍼티로 선언해두고 사용하도록 작성을 해보았는데..
    }
    
    static func setCurrentDelegate(_ delegate: NMFMapViewCameraDelegate?, to object: NMFMapView) {
        switch delegate {   //parameter로 들어온 delegate의 값 유무에 따라
        case .none: //nil이면 현재 설정되어있는 delegate 해제
            guard let setDelegate = self.cameraDelegate else {  //설정되어있다면 self delegate이 nil이 아닐 것
                break
            }
            object.removeCameraDelegate(delegate: setDelegate)
        case .some(let delegate):   //nil이 아니면 해당 값으로 delegate 설정
            object.addCameraDelegate(delegate: delegate)
        }
        
        self.cameraDelegate = delegate      //nil로 설정 될 수도, 아닐수도.
        
        //addCameraDelegate(delegate: )로 설정 시 strong reference로 참조하게 되려나? 그러면 어디선가 removeCameraDelegate(delegate: )를 해줘야 할지도? 내부적으로 delegate가 어떻게 설정되는지 알아야 할거 같은데.. 보통은 weak ref이기는 하지만. -> 그래서 일단은 위와같이 케이스를 나누어 처리
        //어디선가 내가 따로 removeDelegate(delegate: ) 또는 setCurrentDelegate(nil, to: NMFMapView)를 호출해줘야 하려나..?
    }
    
}
