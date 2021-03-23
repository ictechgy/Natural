//
//  AddViewModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/16.
//

import Foundation
import RxSwift
import RxCocoa
import NMapsMap

class AddViewModel {
    
    let kindOfMarkers = ["헌 옷 수거함", "폐건전지 수거함", "폐형광등 수거함", "폐의약품 수거함"]
    
    var typeRelay: BehaviorRelay = BehaviorRelay(value: "")
    var roadAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var numberAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var detailAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var characterRelay: BehaviorRelay = BehaviorRelay(value: "")
    var manageRelay: BehaviorRelay = BehaviorRelay(value: "")
    
    var roadAddressEnabled: BehaviorRelay = BehaviorRelay(value: false)
    var numberAddressEnabled: BehaviorRelay = BehaviorRelay(value: false)
    var addressFetched: BehaviorRelay = BehaviorRelay(value: false)
    var addButtonEnabled: BehaviorRelay = BehaviorRelay(value: false)
    
    var disposeBag = DisposeBag()
    
    init(position: NMGLatLng) {
        
        //position을 가지고 주소 값 가져오기
        AddModel.shared.coordToAddr(latitude: position.lat, longitude: position.lng)
            .take(1)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [weak self] addressInfo in
                self?.roadAddressRelay.accept(addressInfo.roadNameAddress)
                self?.numberAddressRelay.accept(addressInfo.landLodNumberAddress)
            }, onDisposed: { [weak self] in
                self?.roadAddressEnabled.accept(true)
                self?.numberAddressEnabled.accept(true)
                self?.addressFetched.accept(true)
                //onCompleted가 됐든 Error가 됐든 위의 세 스트림에는 값을 넣어준다.
            })
            .disposed(by: disposeBag)
        //문제는.. VC의 viewDidLoad 에서 Address 데이터를 한번 subscribe할 때 제대로 된 값이 미리 도착해 있을 것이냐는 것.. 양방향 바인딩하면 좋은데..
        //-> onDisposed에서 쓰일 BehaviorRelay들을 추가적으로 둠으로써 해결
    }
    
    
}
