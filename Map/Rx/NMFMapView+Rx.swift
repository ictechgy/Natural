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
