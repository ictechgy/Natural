//
//  MapViewModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/24.
//

import Foundation
import RxSwift
import RxCocoa

let seoulCoord: Coordinates = Coordinates(latitude: 37.564, longitude: 127.001)    //서울특별시 중심좌표

class MapViewModel {
    
    //input
    var cameraCoord: BehaviorRelay<Coordinates> = BehaviorRelay(value: Coordinates(latitude: seoulCoord.latitude, longitude: seoulCoord.longitude))   //기본 좌표 - 서울시
    var southWestCoord: PublishRelay<Coordinates> = PublishRelay()  //검색 제한범위 - 남서쪽 좌표
    var northEastCoord: PublishRelay<Coordinates> = PublishRelay()  //검색 제한범위 - 북동쪽 좌표
    //지도좌표 중심을 기준으로 직사각형모양으로 검색을 수행할 것인데, View의 크기 자체는 변하지는 않지만 지도 축적이나 지역위치에 따라 좌표값은 계속 바뀌므로 Observable로 두었다. (같은 축적이라고 하더라도 위도에 따라 경도의 차이는 발생한다. 같은 경도 차이여도 아래로 갈 수록 길이는 길어짐.)
    
    //output
    var markers: PublishRelay<[MarkerInfo]> = PublishRelay()
    
    //마지막 위치 저장용
    let latitudeKey = "latitude"
    let longitudeKey = "longitude"
    var latitude: Double?
    var longitude: Double?
    
    var disposeBag: DisposeBag = DisposeBag()
    
    init() {
        getLastLocation()
        
        //좌표 변동 값 적용하기
        cameraCoord.bind(onNext: { [unowned self] coord in
            self.latitude = coord.latitude
            self.longitude = coord.longitude
        }).disposed(by: disposeBag)

        
        //좌표값을 기준으로 데이터 가져오기(두 Observable내에 데이터가 쌍으로 다 실린 경우에만)
        Observable.zip(southWestCoord, northEastCoord) {
            MarkerModel.getMarkers(southWest: $0, northEast: $1)
        }.flatMap{$0}
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
        .catchAndReturn([])
        .bind(to: markers)
        .disposed(by: disposeBag)
    }
    
    //지도의 마지막 위치를 불러옵니다.
    func getLastLocation() {
        let lat = UserDefaults.standard.double(forKey: latitudeKey)
        let lng = UserDefaults.standard.double(forKey: longitudeKey)
        
        guard !lat.isZero && !lng.isZero else {   //해당 값이 없으면 0으로 나옵니다. 둘 다 0이 아닌 경우에만
            return
        }
        
        cameraCoord.accept(Coordinates(latitude: lat, longitude: lng))
    }
    
    deinit {
        //deinit 되기 전 유저 마지막 위치 저장
        UserDefaults.standard.setValue(latitude, forKey: latitudeKey)
        UserDefaults.standard.setValue(longitude, forKey: longitudeKey)
        
        disposeBag = DisposeBag()
    }
}
