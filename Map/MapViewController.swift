//
//  MapViewController.swift
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

    var markers: [NMFMarker] = []      //지도에 표시되어 있는 마커 저장용
    
    lazy var clothesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(systemName: "person.fill")!)
    }()
    lazy var batteryImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(systemName: "minus.plus.batteryblock.fill")!)
    }()
    lazy var lampImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(systemName: "lightbulb.fill")!)
    }()
    lazy var medicinesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(systemName: "pills.fill")!)
    }()
    lazy var unknownImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(systemName: "questionmark")!)
    }()
    
    @IBOutlet weak var mapView: NMFMapView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        viewModel.centerCoord
            .take(1)
            .bind { coord in
                self.mapView.latitude = coord.latitude
                self.mapView.longitude = coord.longitude
                //사용자의 마지막 위치가 띄워지도록 설정. 기존에는 moveCamera with CameraUpdate를 사용하였지만 굳이 그럴 필요가 없어서 변경
            }.disposed(by: disposeBag) //1번만 실행되고 끝나므로 retain cycle은 고려하지 않음.
        
        mapView.addCameraDelegate(delegate: self)
        
        viewModel.markers  //on ConcurrentDispatchQueue
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] _ in
                //지도에 추가된 마커 속성은 메인쓰레드에서 다뤄야 함.
                //지도에 추가되어있는 마커 삭제
                self?.markers.forEach { existingMarker in
                    existingMarker.mapView = nil    //마커를 지도에서 삭제합니다.
                }
                self?.markers.removeAll()   //리스트 비우기
            })
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .do(onNext: { [weak self] markerList in
                print(markerList)
                //새로 받아온 마커 리스트를 NMFMarker객체로 바꿉니다.(별도의 쓰레드에서 수행합니다.)
                markerList.forEach { [weak self] markerInfo in
                    
                    guard let self = self else {
                        return
                    }
                    
                    var image: NMFOverlayImage
                    switch markerInfo.type {
                    case .clothes:
                        image = self.clothesImage
                    case .battery:
                        image = self.batteryImage
                    case .fluorescentLamp:
                        image = self.lampImage
                    case .medicines:
                        image = self.medicinesImage
                    case .unknown:
                        image = self.unknownImage
                    }
                    
                    let newMarker = NMFMarker(position: NMGLatLng(lat: markerInfo.latitude, lng: markerInfo.longitude), iconImage: image)
                    self.markers.append(newMarker)
                }
            })
            .asSignal(onErrorJustReturn: [])    //main thread
            .emit(onNext: { [weak self] _ in
                print("작동")
                print(self?.markers)
                self?.markers.forEach({ [weak self] marker in
                    marker.mapView = self?.mapView          //지도에 나타내기
                })
                
                self?.loadingIndicator.stopAnimating()
                
            }).disposed(by: disposeBag)
    }
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {     //카메라 움직임이 끝난 뒤 - VC가 보여질 때 최초 한번은 작동합니다.(앱을 처음 실행하든 아니든), 중심좌표 변동에 대해서만 작동한다. 회전, 확대, 축소에 대해서는 작동하지 않음. 하지만 보통은 지도 확대/축소 시 미세하게나마 중심좌표가 변동된다.
        //직접적인 rx바인딩이 되지 않아서 수동설정(?) - mapView의 latitude, longitude를 zoomLevel과 함께 직접적으로 이용하거나 특정 NMGLatLngBounds를 이용해볼 수도 있을까?
        
        //보면은 viewDidLoad에서 lat,lng 세팅(동기식) 이후에 delegate를 설정했는데도 이 메소드는 최초에 무조건 한번 작동 한다.
        //VC가 최초 로드될 때 이 메소드가 무조건 한번 실행되는 방식이 아니었다면 구현 방식이 더 복잡해졌을 것이다. (반드시 이동이 발생한 경우에만 작동하는 것이었다면)
        //왜냐하면 최초 지도화면에 마커를 띄워줘야 하는 문제때문에.
        //(만약 최초 로드 시 작동 안했다면)가장 처음 화면에 띄워줄 마커를 가져오기 위해 VC 최초 생성시에만 작동하도록 flag를 두고 viewWillAppear(또는 그 이후 LifeCycle메소드)에 take(1)로 중심 좌표와 반경을 구해 viewModel에 넘기는 코드가 별도로 필요했을 것. (mapView projection을 통해 화면 bounds와 CGPoint 조합하여 좌표를 구하는 방식이 필요했을 수도 있는데 그러면 뷰가 언제 완전히 그려지는지도 고려했어야 했을 것... 전체적인 순서가 굉장히 복잡해진다. )
        //Android SDK에는 onMapReady()라는 메소드가 존재하기는 했음.
        loadingIndicator.startAnimating()
        
        let bounds: NMGLatLngBounds = mapView.contentBounds
        viewModel.northEastCoord.accept(CLLocationCoordinate2D(latitude: bounds.northEastLat, longitude: bounds.northEastLng))
        
        let lat = mapView.cameraPosition.target.lat
        let lng = mapView.cameraPosition.target.lng
        viewModel.centerCoord.accept(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        
        print("zoomLevel: \(mapView.zoomLevel)")
    }
    
    deinit {
        disposeBag = DisposeBag()
    }
}

