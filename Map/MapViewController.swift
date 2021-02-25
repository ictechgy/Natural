//
//  ViewController.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/23.
//

import UIKit
import RxSwift
import RxCocoa
import NMapsMap

class MapViewController: UIViewController, NMFMapViewCameraDelegate {
    
    var viewModel: MapViewModel = MapViewModel()
    var disposeBag = DisposeBag()
    
    lazy var projection: NMFProjection = {
        mapView.projection
    }()

    var markers: [NMFMarker] = []      //지도에 표시되어 있는 마커 저장용
    
    @IBOutlet weak var mapView: NMFMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        viewModel.cameraCoord
            .take(1)
            .bind { coord in
                self.mapView.moveCamera(NMFCameraUpdate(scrollTo: NMGLatLng(lat: coord.latitude, lng: coord.longitude)))    //사용자의 마지막 위치가 띄워지도록 이동시킵니다.
            }.disposed(by: disposeBag) //1번만 실행되고 끝나므로 retain cycle은 고려하지 않음.
        
        mapView.addCameraDelegate(delegate: self)
        
    }
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {     //카메라 움직임이 끝난 뒤 - VC가 보여질 때 최초 한번은 작동합니다.(앱을 처음 실행하든 아니든), 중심좌표 변동에 대해서만 작동한다. 회전, 확대, 축소에 대해서는 작동하지 않음.
        //직접적인 rx바인딩이 되지 않아서 수동설정(?) - mapView의 latitude, longitude를 zoomLevel과 함께 직접적으로 이용하거나 특정 NMGLatLngBounds를 이용해볼 수도 있을까?
        let lat = mapView.cameraPosition.target.lat
        let lng = mapView.cameraPosition.target.lng
        viewModel.cameraCoord.accept(Coordinates(latitude: lat, longitude: lng))
        
        //보면은 (동기식)moveCamera 이후에 delegate를 설정했는데도 이 메소드는 최초에 무조건 한번 작동 한다.
        //VC가 최초 로드될 때 이 메소드가 무조건 한번 실행되는 방식이 아니었다면 구현 방식이 더 복잡해졌을 것이다. (반드시 이동이 발생한 경우에만 작동하는 것이었다면)
        //왜냐하면 최초 지도화면에 마커를 띄워줘야 하는 문제때문에.
        //가장 처음 화면에 띄워줄 마커를 가져오기 위해 VC 최초 생성시에만 작동하도록 flag를 두고 viewWillAppear(또는 그 이후 LifeCycle메소드)에 take(1)로 남서쪽 좌표와 북동쪽 좌표를 구해 viewModel에 넘기는 코드가 별도로 필요했을 것. (mapView projection을 통해 화면 bounds와 CGPoint 조합하여 좌표를 구하는 방식이 필요했을 텐데 그러면 뷰가 언제 완전히 그려지는지도 고려했어야 했을 것... 전체적인 순서가 굉장히 복잡해진다. )
        //Android SDK에는 onMapReady()라는 메소드가 존재하기는 했음.
    }
}

