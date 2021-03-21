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
    
    
    var typeRelay: BehaviorRelay = BehaviorRelay(value: "")
    var roadAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var numberAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var detailAddressRelay: BehaviorRelay = BehaviorRelay(value: "")
    var characterRelay: BehaviorRelay = BehaviorRelay(value: "")
    var manageRelay: BehaviorRelay = BehaviorRelay(value: "")
    
    var addButtonEnabled: BehaviorRelay = BehaviorRelay(value: false)
    
    var disposeBag = DisposeBag()
    
    init(position: NMGLatLng) {
        
        //position을 가지고 주소 값 가져오기
        AddModel.shared.coordToAddr(latitude: position.lat, longitude: position.lng)
            .take(1)
            .subscribe(onNext: { addressInfo in
                
            })
            .disposed(by: disposeBag)
    }
    
    
}
