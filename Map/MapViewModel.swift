//
//  MapViewModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/24.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

let seoulCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.564, longitude: 127.001)    //서울특별시 중심좌표

class MapViewModel {
    
    //input
    var centerCoord: BehaviorRelay<CLLocationCoordinate2D> = BehaviorRelay(value: CLLocationCoordinate2D(latitude: seoulCoord.latitude, longitude: seoulCoord.longitude))   //기본 좌표 - 서울시
    var northEastCoord: PublishRelay<CLLocationCoordinate2D> = PublishRelay()  //검색 제한범위 - 북동쪽 좌표이용 예정
    //지도좌표 중심을 기준으로 radius 검색을 수행할 것인데, View의 크기 자체는 변하지는 않지만 지도 축적이나 지역위치에 따라 좌표값은 계속 바뀌므로 Observable로 두었다. (같은 축적이라고 하더라도 위도에 따라 경도의 차이는 발생한다. 같은 경도 차이여도 저위도로 갈 수록 같은 위도 내 길이는 길어짐.)
    
    //output
    var markers: BehaviorRelay<[MarkerInfo]> = BehaviorRelay(value: [])
    var markerImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)    //BottomSheetView, DetailVC Image용
    var selectedMarker: BehaviorRelay<MarkerInfo> = BehaviorRelay(value: MarkerInfo.getDummyMarker()) //BottomSheetView, DetailVC에서 사용 할 것으로서 dummy값으로 채워놓았다.
    
    //마지막 위치 저장용
    let latitudeKey = "latitude"
    let longitudeKey = "longitude"
    var latitude: Double?
    var longitude: Double?
    
    var disposeBag: DisposeBag = DisposeBag()
    
    init() {
        getLastLocation()
        
        //좌표 변동 값 지속 갱신
        centerCoord.bind(onNext: { [unowned self] coord in
            self.latitude = coord.latitude
            self.longitude = coord.longitude
        }).disposed(by: disposeBag)

        
        //중심 좌표값과 반경을 기준으로 데이터 가져오기
        //VC의 CameraIdle은 좌표값이 변경됐을 때만 콜백되므로 중심좌표가 변하지 않는 줌 확대/축소/회전에는 아래 스트림이 작동하지 않는다. (사람이 실제로 조작할 때에는 중심좌표가 보통은 변하므로 이부분은 신경쓰지 않아도 된다.)
        //VC NaverMapView가 제공하는 '현재 내 위치 버튼'을 누르면 CameraIdle은 무조건 작동하는 것으로 보인다. 따라서 다른 위치 보고 있다가 위치 버튼을 눌러 내 위치를 보는 경우 마커 업데이트는 자동이다. 다만 트래킹모드만 바뀔 때는 좌표값에 실질적 변화가 없음에도 스트림이 계속 작동한다. 마음같아서는 centerCoord에 distinctUntilChanged()를 붙이고 싶지만 초기에 한번은 목록을 로드해야하는 문제때문에 쉽게 해당 Operator를 붙일 수가 없다.
        centerCoord.withLatestFrom(northEastCoord) { center, northEast -> Observable<[MarkerInfo]> in
            let distance: CLLocationDistance = CLLocation(latitude: center.latitude, longitude: center.longitude).distance(from: CLLocation(latitude: northEast.latitude, longitude: northEast.longitude))  //alternative - GFUtils.distance(from:, to:) 동일한 결과가 나옴. 단위는 meter
            let radius: Double = distance/2.0            //반경은 '중심좌표-화면 우상단 좌표'의 2분의 1 값으로 할 것이며 단위는 meter
            return MarkerModel.getMarkers(centerCoordinates: center, radiusInMeters: radius)
        }.flatMap{ $0 }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
        .catchAndReturn([])
        .bind(to: markers)
        .disposed(by: disposeBag)
        
    }
    
    //지도의 마지막 위치를 불러옵니다.
    func getLastLocation() {
        let lat = UserDefaults.standard.double(forKey: latitudeKey)
        let lng = UserDefaults.standard.double(forKey: longitudeKey)
        
        guard !lat.isZero && !lng.isZero else {   //해당 값이 없으면 0으로 나옵니다. 둘 중 하나라도 0이 나오면 기본 좌표 값 사용
            return
        }
        
        centerCoord.accept(CLLocationCoordinate2D(latitude: lat, longitude: lng))
    }
    
    //특정 마커가 선택됨 - VC의 [NMFMarker]와 VM의 [MarkerInfo]의 마커 순서는 동일하므로 index로 다룰 수 있다.
    func markerSelected(index: Int) {
        let prevImageBehavior: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
        _ = markerImage.take(1)
            .bind(to: prevImageBehavior)
        markerImage.accept(nil)  //기존 이미지는 제거, 다른 내용은 바로 새 값 세팅이 가능하므로 굳이 제거하지 않아도 된다.
        
        
        //기존에 선택되었었던 마커와 새롭게 선택된 마커가 동일하다면 BottomSheetView의 내용을 바꿀 필요가 없습니다. (이미지 로드도 불필요)
        Observable.zip(markers, selectedMarker, prevImageBehavior) { (list, prevMarker, image) -> Observable<UIImage?> in
            if (image != nil) && (list[index].id == prevMarker.id) {
                return Observable.just(image)                               //기존 이미지
            }else {
                return MarkerModel.getImage(path: list[index].photoRef)      //새로운 이미지
            }
        }.flatMap { $0 }
        .take(1)
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
        .bind(to: markerImage)
        .disposed(by: disposeBag)
        //마커를 선택하고 선택해제되는 과정에서 BottomSheetView의 ImageView는 매번 nil로 세팅된다. 따라서 이전과 동일한 마커인지와 상관없이 image는 계속 스트림으로 넘겨준다.
        
        //이전과 동일한 마커인지와 상관없이 selectedMarker도 갱신해준다. (BottomSheetView의 바인딩에 의한 동작을 위해)
        markers.map { list in
            return list[index]
        }.take(1)
        .bind(to: selectedMarker)
        .disposed(by: disposeBag)
    }
    
    deinit {
        //deinit 되기 전 유저 마지막 위치 저장
        UserDefaults.standard.setValue(latitude, forKey: latitudeKey)
        UserDefaults.standard.setValue(longitude, forKey: longitudeKey)
        
        disposeBag = DisposeBag()
    }
}
