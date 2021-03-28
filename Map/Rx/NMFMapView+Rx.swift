//
//  NMFMapView+Rx.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/25.
//

import Foundation
import RxSwift
import RxCocoa
import NMapsMap

//기존 NMFMapViewDelegate가 NMFMapViewTouchDelegate, NMFMapViewCameraDelegate, NMFMapViewOptionDelegate로 세분화되었다. (NMFMapViewDelegate deprecated)

//MARK:- Proxy
class RxNMFMapViewTouchDelegateProxy: DelegateProxy<NMFMapView, NMFMapViewTouchDelegate>, DelegateProxyType, NMFMapViewTouchDelegate {
    
    static func registerKnownImplementations() {
        self.register { mapView -> RxNMFMapViewTouchDelegateProxy in
            RxNMFMapViewTouchDelegateProxy(parentObject: mapView, delegateProxy: self)
        }
    }
    
    static func currentDelegate(for object: NMFMapView) -> NMFMapViewTouchDelegate? {
        object.touchDelegate
    }
    
    static func setCurrentDelegate(_ delegate: NMFMapViewTouchDelegate?, to object: NMFMapView) {
        object.touchDelegate = delegate
    }
    
    
}

class RxNMFMapViewCameraDelegateProxy: DelegateProxy<NMFMapView, NMFMapViewCameraDelegate>, DelegateProxyType, NMFMapViewCameraDelegate {
    
    private static weak var cameraDelegate: NMFMapViewCameraDelegate?    //delegate 별도로 참조
    
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

//MARK:- Extension
//Extension에서 (delegate 'proxy'를 통해 Observable을 반환하는) 연산 프로퍼티를 참조 했을때에야 비로소 Delegate Proxy 인스턴스가 생성되고 delegate 관계가 맺어지는건가?
extension Reactive where Base: NMFMapView {
    
    var touchDelegate: DelegateProxy<NMFMapView, NMFMapViewTouchDelegate> {
        return RxNMFMapViewTouchDelegateProxy.proxy(for: self.base)
    }
    
    var cameraDelegate: DelegateProxy<NMFMapView, NMFMapViewCameraDelegate> {
        return RxNMFMapViewCameraDelegateProxy.proxy(for: self.base)
    }
    
    ///지도에서 오버레이가 아닌 부분 터치 시 호출
    ///스트림에 실리는 값은 터치된 부분의 지도 상 위경도 좌표 값. 타입캐스팅에 실패할 경우 (0, 0)이 실립니다.
    var didTapMap: Observable<NMGLatLng> {
        return touchDelegate.methodInvoked(#selector(NMFMapViewTouchDelegate.mapView(_:didTapMap:point:)))
            .map { parameters in
                return parameters[1] as? NMGLatLng ?? NMGLatLng(lat: 0, lng: 0)
            }
    }
    
    ///카메라 이동이 끝난 경우 호출 됨
    ///스트림에 실리는 값은 없습니다.
    var mapViewCameraIdle: Observable<Void> {
        return cameraDelegate.methodInvoked(#selector(NMFMapViewCameraDelegate.mapViewCameraIdle(_:)))
            .map { _ in
                return      //파라미터로는 NMFMapView가 있는데 굳이 스트림에 싣지 않아도 된다.
            }
    }
    
    //이곳의 Observable 연산 프로퍼티 스트림들은 끝나는 시점이 정해지지 않은 스트림들인 것으로 보인다. (onDisposed 시점이 정해지지 않음)
    
}
