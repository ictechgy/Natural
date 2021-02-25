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
        
        let criteria = mapView.bounds.width/2
        let cameraPoint = projection.point(from: mapView.cameraPosition.target)
        let southWestPoint = CGPoint(x: cameraPoint.x - criteria, y: cameraPoint.y - criteria)
        let northEastPoint = CGPoint(x: cameraPoint.x + criteria, y: cameraPoint.y + criteria)
        
        
        
    }
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {     //카메라 움직임이 끝난 뒤
        //직접적인 바인딩이 되지 않아서
        let lat = mapView.cameraPosition.target.lat
        let lng = mapView.cameraPosition.target.lng
        viewModel.cameraCoord.accept(Coordinates(latitude: lat, longitude: lng))
    }
    
}

