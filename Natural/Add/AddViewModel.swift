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
import Firebase

class AddViewModel {
    
    let kindOfMarkers: [String] = ["헌 옷 수거함", "폐건전지 수거함", "폐형광등 수거함", "폐의약품 수거함"]
    var kindOfMarkersObservable: Observable<[String]> {
        return Observable.just(kindOfMarkers)
    }
    
    var imageRelay: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
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
    
    var latitude: Double
    var longitude: Double
    
    var disposeBag = DisposeBag()
    
    init(position: NMGLatLng) {
        
        //추가버튼을 누른 경우에도 쓰기 위해 별도 저장
        latitude = position.lat
        longitude = position.lng
        
        //position을 가지고 주소 값 가져오기
        AddModel.shared.coordToAddr(latitude: latitude, longitude: longitude)
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
        
        //addButtonEnabled 설정
        Observable.combineLatest(imageRelay, typeRelay, roadAddressRelay, numberAddressRelay) { image, type, roadAddr, numberAddr in   //필수 기입사항
            return (image != nil) && !type.isEmpty && !roadAddr.isEmpty && !numberAddr.isEmpty
        }.distinctUntilChanged()
        .bind(to: addButtonEnabled)
        .disposed(by: disposeBag)
    }
    
    func addButtonTapped() {
        //데이터를 서버에 추가
        
        //AddModel.shared.addDocData를 호출 할 때 image를 미리 넘겨놓는 방식도 가능하다.(doc데이터 추가 성공 시 image가 Observable에 실려 반환되도록 설정하면 zip operator를 중첩하지 않아도 image를 쓸 수 있음)
        Observable.zip(
            imageRelay,
            Observable.zip(typeRelay, roadAddressRelay,  numberAddressRelay, detailAddressRelay, characterRelay, manageRelay) { type, roadAddr, numberAddr, detailAddr, character, manage in //image, type, roadAddr, numberAddr에는 값이 존재할 것이고(해당 값이 존재하는 경우에만 버튼이 눌릴 수 있도록 바인딩 해둠) detailAddr, character, manage는 빈 문자열이 들어있을 수 있다.
                
                return AddModel.shared.addDocData(type: type, roadAddr: roadAddr, numberAddr: numberAddr, detailAddr: detailAddr, character: character, manage: manage, latitude: self.latitude, longitude: self.longitude)
            }
            .flatMap { $0 }
            ) { image, docResult in
            
        }
        .take(1)
        
    }
}
