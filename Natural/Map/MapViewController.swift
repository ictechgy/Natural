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

class MapViewController: UIViewController {
    
    //MARK:- Variables
    var viewModel: MapViewModel = MapViewModel()
    var disposeBag = DisposeBag()
    var locationManager: CLLocationManager!

    var markers: [NMFMarker] = []      //지도에 표시되어 있는 마커 저장용
    
    //이미지 프로퍼티(마커 기본)
    lazy var clothesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "clothes.png")!)
    }()
    lazy var batteryImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "battery.png")!)
    }()
    lazy var lampImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "lamp.png")!)
    }()
    lazy var medicinesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "medicines.png")!)
    }()
    lazy var unknownImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "unknown.png")!)
    }()
    
    //이미지 프로퍼티(마커가 선택된 경우)
    lazy var selectedClothesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "selectedClothes.png")!)
    }()
    lazy var selectedBatteryImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "selectedBattery.png")!)
    }()
    lazy var selectedLampImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "selectedLamp.png")!)
    }()
    lazy var selectedMedicinesImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "selectedMedicines.png")!)
    }()
    lazy var selectedUnknownImage: NMFOverlayImage = {
        return NMFOverlayImage(image: UIImage(named: "selectedUnknown.png")!)
    }()
    
    
    //NMFMapView 프로퍼티. 스토리보드에 있는 지도 뷰는 현재 NMFNaverMapView로 설정되어 있습니다.
    lazy var mapView: NMFMapView = {
        naverMapView.mapView
    }()
    
    //지도를 길게 탭했을 시 띄워질 마커 이미지
    lazy var longTappedMarkerImage: NMFOverlayImage = {
        return NMF_MARKER_IMAGE_BLUE
    }()
    
    //지도를 long press 한 경우 나타날 마커 객체
    lazy var longTappedMarker: NMFMarker = {
        let marker = NMFMarker()
        marker.iconImage = longTappedMarkerImage
        return marker
    }()
    
    //longTappedMarker와 같이 보일 infoWindow
    lazy var longTappedInfoWindow: NMFInfoWindow = {
        let window = NMFInfoWindow()
        let dataSource = NMFInfoWindowDefaultTextSource.data()
        dataSource.title = "이 위치에 수거함 추가"
        window.dataSource = dataSource
        
        window.touchHandler = { [weak self] overlay in
            //window 터치 시 AddVC로 이동
            guard let addVC: AddViewController = self?.storyboard?.instantiateViewController(identifier: "AddVC", creator: { coder in
                return AddViewController(coder: coder)
            }), let marker: NMFMarker = window.marker else {
                return false
            }
            
            addVC.viewModel = AddViewModel(position: marker.position)
            self?.navigationController?.pushViewController(addVC, animated: true)
            
            return true //이벤트 소비
        }
        
        return window
    }()
    
    //MARK: Outlet variables
    @IBOutlet weak var naverMapView: NMFNaverMapView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomSheetView: BottomSheetView!
    @IBOutlet weak var longPressRecognizer: UILongPressGestureRecognizer!
    
    //MARK:- LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpMapView()  //맵뷰에 대한 기본 설정들
        loadLastLocation()  //사용자의 마지막 위치 로드
        
        bindLocationManagerDelegates()  //CLLocationManager 객체 생성 및 Delegate 설정
        bindMapViewDelegates() //NMFMapView의 Delegate 설정
        
        bindMarkers()   //지도 위치 변경에 따라 마커 목록 업데이트 후 지도에 표시
        bindBottomSheetView()   //BottomSheetView에 대한 바인딩
        
        bindLongPressRecognizer()
    }
    
    deinit {
        disposeBag = DisposeBag()
    }
    
    //MARK:- Custom Methods
    func setUpMapView() {
        mapView.minZoomLevel = 12
        naverMapView.showCompass = true
        naverMapView.showScaleBar = true
        naverMapView.showZoomControls = false
        naverMapView.showIndoorLevelPicker = false
    }
    
    func loadLastLocation() {
        _ = viewModel.centerCoord
            .take(1)
            .bind { coord in
                self.mapView.latitude = coord.latitude
                self.mapView.longitude = coord.longitude
                //사용자의 마지막 위치가 띄워지도록 설정. 기존에는 moveCamera with CameraUpdate를 사용하였지만 굳이 그럴 필요가 없어서 변경
            }
        //1번만 실행되고 끝나므로 retain cycle은 고려하지 않아도 됨.
        
        //네이버 지도의 경우 앱 실행 시 기본적으로 이전에 보고 있던 마지막 좌표지점을 보여주는데, 위치권한이 있다면 현재 위치로 cameraUpdate를 수행해주는 것으로 보인다. (마지막 위치가 없는 경우 서울 중심이 default)
    }
    
    func bindLocationManagerDelegates() {
        
        locationManager = CLLocationManager()
        
        //위치 권한 변경에 대한 subscribe
        locationManager.rx.locationManagerDidChangeAuthorization
            .subscribe(onNext: { [weak self] in
                
                self?.naverMapView.showLocationButton = false  //내 위치 버튼 기본 값 보이지 않음으로 설정
                let alertCkKey = "AlertCkKey"
                let isWarned = UserDefaults.standard.bool(forKey: alertCkKey)       //권한 거부에 대한 경고 메시지를 기존에 띄웠는지 확인할 것입니다.
                
                switch self?.locationManager.authorizationStatus {
                case .notDetermined:    //아직 정해지지 않았다면 권한 요청창을 띄운다.
                    self?.locationManager.requestWhenInUseAuthorization()
                    UserDefaults.standard.setValue(false, forKey: alertCkKey)
                case .denied, .restricted:  //거부되었거나 제한된 상태라면 알림창을 띄운다. (최초 1회)
                    
                    if !isWarned{
                        let alertController = UIAlertController(title: "권한 거부됨", message: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 - 개인정보 보호'에서 위치 서비스를 허용하여 주십시오.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self?.present(alertController, animated: true, completion: nil)
                        
                        UserDefaults.standard.setValue(true, forKey: alertCkKey)  //alert 띄웠음을 저장
                    }
                case .authorizedAlways, .authorizedWhenInUse:
                    self?.naverMapView.showLocationButton = true
                    UserDefaults.standard.setValue(false, forKey: alertCkKey)
                case .none: //권한은 변경되었는데 self가 없다?? -> 경고 값 설정만 초기화
                    UserDefaults.standard.setValue(false, forKey: alertCkKey)
                @unknown default:
                    UserDefaults.standard.setValue(false, forKey: alertCkKey)
                    break
                }
            })
            .disposed(by: disposeBag)
        
        //권한이 이미 한번 설정되었어도 설정에 가서 변경하고 올 수 있다는 점 때문에 조금 복잡하게 작성되었다.
        //이를 테면 '허가를 했다가 설정에서 거부'를 하는 경우 location버튼은 보이면 안되고..
        //'거부를 하고 alert 본 뒤 설정에서 다른 설정을 했다가 다시 거부'를 하는 경우 다시 최초 한번 alert를 띄워야 한다던지..하는 점들 때문에.
        
        //사용자의 위치를 얻어오는데에 실패한 경우
        locationManager.rx.didFailWithError
            .subscribe(onNext: { [weak self] error in
                let alertController = UIAlertController(title: "오류 발생", message: "사용자의 위치를 불러오던 도중 문제가 발생하였습니다. 다음에 다시 시도하십시오.", preferredStyle: .alert)
                let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
                alertController.addAction(ok)
                
                self?.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
    }
    
    func bindMapViewDelegates() {
        
        //mapView 최초 로드 시, 카메라가 이동이 완료된 경우
        mapView.rx.mapViewCameraIdle
            .subscribe(onNext: { [weak self] in
                
                guard let strongSelf = self else {
                    return
                }   //카메라가 이동한 경우 해당 변동 사항을 viewModel에 반영할 때까지는 self를 붙잡고 있기.
                
                strongSelf.loadingIndicator.startAnimating()
                
                let bounds: NMGLatLngBounds = strongSelf.mapView.contentBounds
                strongSelf.viewModel.northEastCoord.accept(CLLocationCoordinate2D(latitude: bounds.northEastLat, longitude: bounds.northEastLng))
                
                let lat = strongSelf.mapView.cameraPosition.target.lat
                let lng = strongSelf.mapView.cameraPosition.target.lng
                strongSelf.viewModel.centerCoord.accept(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                
                //카메라 이동이 완료된 경우 BottomSheetView를 숨깁니다.
                strongSelf.hideViewsAfterUserInteraction()
            })
            .disposed(by: disposeBag)
        
        //오버레이가 아닌 지도부분을 터치한 경우 (BottomSheetView를 숨깁니다.)
        mapView.rx.didTapMap
            .subscribe(onNext: { [weak self] touchedCoord in
                self?.hideViewsAfterUserInteraction()
            })
            .disposed(by: disposeBag)
        
    }
    
    func hideViewsAfterUserInteraction() {
        bottomSheetView.isHidden = true
        longTappedMarker.mapView = nil
        longTappedInfoWindow.close()
    }
    
    func bindMarkers() {
        
        viewModel.markers  //on ConcurrentDispatchQueue
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] _ in
                //지도에 이미 추가되어있는 마커 속성은 메인쓰레드에서 다뤄야 함.
                //지도에 추가되어있는 마커 삭제
                self?.markers.forEach { existingMarker in
                    existingMarker.mapView = nil    //기존 마커를 지도에서 삭제합니다.
                }
                self?.markers.removeAll()   //리스트 비우기
            })
            //.filter { !$0.isEmpty } //markerList 배열이 비어있다면 여기까지만. -> ActivityIndicator때문에 일단은.. 안됨.
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .do(onNext: { [weak self] markerList in     //이것도 ViewModel에서 해줘야 하는 걸까? 여기서는 mapView 지정/해제만 해주고?
                //새로 받아온 마커 리스트를 NMFMarker객체(리스트)로 바꿉니다.(별도의 쓰레드에서 수행합니다.)
                
                //마커 기본 이미지
                let defaultOverlayImage = NMFOverlayImage()
                
                //마커가 눌렸을 때 동작할 핸들러
                //retain cycle 주의. markers 안의 각각의 마커들이 공통적으로 참조하게 될 클로저
                let markerTouchHandler: NMFOverlayTouchHandler = { [weak self] overlay in
                    guard let index = overlay.userInfo["index"] as? Int else {
                        return false    //이벤트를 소비하지 않고 지도로 전파
                    }
                    
                    self?.viewModel.markerSelected(index: index)
                    return true //이벤트 소비. 지도로 전파하지 않습니다.
                }
                
                markerList.enumerated().forEach { [weak self] index, markerInfo in
                    
                    var image: NMFOverlayImage?
                    switch markerInfo.type {
                    case .clothes:
                        image = self?.clothesImage
                    case .battery:
                        image = self?.batteryImage
                    case .fluorescentLamp:
                        image = self?.lampImage
                    case .medicines:
                        image = self?.medicinesImage
                    case .unknown:
                        image = self?.unknownImage
                    }
                    
                    let newMarker = NMFMarker(position: NMGLatLng(lat: markerInfo.latitude, lng: markerInfo.longitude), iconImage: image ?? defaultOverlayImage)
                    
                    //마커 선택 시 작동할 로직
                    newMarker.userInfo = ["index" : index]  //각 마커를 구분하는 값 설정
                    newMarker.touchHandler = markerTouchHandler
                    
                    self?.markers.append(newMarker)
                }
            })
            .asSignal(onErrorJustReturn: [])    //main thread
            .emit(onNext: { [weak self] _ in
                
                self?.markers.forEach { [weak self] marker in   //markers의 forEach를 실행시키는데 (일단 for each 실행에 들어간 것으로 가정) markers가 정말 많은 경우 이 for each에 weak self 안되어 있으면 앱을 종료해도 반복이 다 끝날 때까지 retain cycle이 유지될 것으로 보여 weak self 설정함.
                    marker.mapView = self?.mapView          //지도에 나타내기
                }
                
                self?.loadingIndicator.stopAnimating()
                
            })
            .disposed(by: disposeBag)
        
    }
    
    func bindBottomSheetView() {
        
        viewModel.markerImage   //BehaviorRelay 초기 값: nil
            .asDriver()
            .drive(onNext: { [weak self] (image: UIImage?) in
                self?.bottomSheetView.imageView.image = image
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedMarker    //BehaviorRelay 초기 값: dummy 객체
            .asDriver()
            .drive(onNext: { [weak self] markerInfo in
                
                self?.bottomSheetView.typeLabel.text = markerInfo.type.rawValue
                self?.bottomSheetView.roadNameAddress.text = markerInfo.roadNameAddress
                self?.bottomSheetView.detailAddress.text = markerInfo.detailAddress
                
                self?.bottomSheetView.isHidden = false
                
            })
            .disposed(by: disposeBag)
        
        bottomSheetView.isHidden = true //초기 상태 숨김 - 위의 selectedMarker BehaviorRelay 바인딩에 의해 bottomSheetView에 의미 없는 값이 있는 상태로 hidden이 풀리게 되지만 여기서 바로 다시 숨김 세팅(filter operator를 사용해도 되긴 함)
        
        //bottomSheetView.tapGestureRecognizer.addTarget(self, action: #selector(bottomSheetTapped(sender:))) -> Rx로 대체합니다.
        bottomSheetView.tapGestureRecognizer.rx.event
            .subscribe(onNext: { [weak self] (gestureRecognizer: UITapGestureRecognizer) in
                //마커 정보가 표시되어있는 BottomSheetView를 터치한 경우 상세화면으로 넘어갈 것임
                
                guard let self = self else {
                    return      //끝날 때까지 self를 잠시 묶어두기
                }
                
                let detailVC = (self.storyboard ?? UIStoryboard.init(name: "Main", bundle: Bundle.main)).instantiateViewController(identifier: "DetailVC") { coder in
                    return DetailViewController(coder: coder)
                }
                
                detailVC.viewModel = self.viewModel
                self.navigationController?.pushViewController(detailVC, animated: true)
                
            })
            .disposed(by: disposeBag)
        
    }
    
    func bindLongPressRecognizer() {
        //longPressRecognizer.addTarget(self, action: #selector(didTapMapLong(sender:))) -> Rx로 대체
        
        longPressRecognizer.rx.event
            .subscribe(onNext: { [weak self] gestureRecognizer in
                //지도를 꾹 누른 경우 호출
                
                guard let self = self else {
                    return      //self 잠시 붙잡기
                }
                
                self.longTappedMarker.mapView = nil
                self.longTappedInfoWindow.close()
                
                let touchedPoint: CGPoint = gestureRecognizer.location(in: gestureRecognizer.view)
                let coord: NMGLatLng = self.mapView.projection.latlng(from: touchedPoint)
                
                self.longTappedMarker.position = coord
                self.longTappedMarker.mapView = self.mapView
                self.longTappedInfoWindow.open(with: self.longTappedMarker)
                
            })
            .disposed(by: disposeBag)
        
    }
    
    //MARK: Deprecated Custom Methods
    /*
    @objc func bottomSheetTapped(sender: UITapGestureRecognizer){
        //마커 정보가 표시되어있는 BottomSheetView를 터치한 경우 상세화면으로 넘어갈 것임
        
        let detailVC = (storyboard ?? UIStoryboard.init(name: "Main", bundle: Bundle.main)).instantiateViewController(identifier: "DetailVC") { coder in
            return DetailViewController(coder: coder)
        }
        
        detailVC.viewModel = self.viewModel
        self.navigationController?.pushViewController(detailVC, animated: true)
        
    }
     
    
    @objc func didTapMapLong(sender: UILongPressGestureRecognizer) {
        //지도를 꾹 누른 경우 호출
        longTappedMarker.mapView = nil
        longTappedInfoWindow.close()
        
        let touchedPoint: CGPoint = sender.location(in: sender.view)
        let coord: NMGLatLng = mapView.projection.latlng(from: touchedPoint)
        
        longTappedMarker.position = coord
        longTappedMarker.mapView = self.mapView
        longTappedInfoWindow.open(with: longTappedMarker)
    }
    */
 
}

//MARK:- Extensions (deprecated)
/*
extension MapViewController: NMFMapViewCameraDelegate, NMFMapViewTouchDelegate {
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {     //카메라 움직임이 끝난 뒤 - VC가 보여질 때 최초 한번은 작동합니다.(앱을 처음 실행하든 아니든), 중심좌표 변동에 대해서만 작동한다. 회전, 확대, 축소에 대해서는 작동하지 않음. 하지만 보통은 지도 확대/축소 시 미세하게나마 중심좌표가 변동된다.
        //직접적인 rx바인딩(mapView의 프로퍼티들을 외부 Observable로 바인딩 할 수 없음)이 되지 않아서 수동설정(?) - mapView의 latitude, longitude를 zoomLevel과 함께 직접적으로 이용하거나 특정 NMGLatLngBounds를 이용해볼 수도 있을까?
        
        //보면은 viewDidLoad에서 마지막 위치 값 lat,lng 세팅(동기식) 이후에 delegate를 설정했는데도 이 메소드는 최초에 무조건 한번 작동 한다.
        //VC가 최초 로드될 때 이 메소드가 무조건 한번 실행되는 방식이 아니었다면 구현 방식이 더 복잡해졌을 것이다. (반드시 이동이 발생한 경우에만 작동하는 것이었다면)
        //왜냐하면 최초 지도화면에 마커를 띄워줘야 하는 문제때문에.
        //(만약 최초 로드 시 이 메소드가 작동 안했다면)가장 처음 화면에 띄워줄 마커를 가져오기 위해 VC 최초 생성시에만 작동하도록 viewDidLoad를 이용하거나, flag를 두고 viewWillAppear(또는 그 이후 LifeCycle메소드)에 take(1)로 중심 좌표와 반경을 구해 viewModel에 넘기는 코드가 별도로 필요했을 것. (아니면 이 delegate 메소드를 강제로 호출하거나..) (mapView projection을 통해 화면 bounds와 CGPoint 조합하여 좌표를 구하는 방식이 필요했을 수도 있는데 그러면 뷰가 언제 완전히 그려지는지도 고려했어야 했을 것... 전체적인 순서가 굉장히 복잡해진다. )
        //Android SDK에는 onMapReady()라는 메소드가 존재하기는 했음.
        loadingIndicator.startAnimating()
        
        let bounds: NMGLatLngBounds = mapView.contentBounds
        viewModel.northEastCoord.accept(CLLocationCoordinate2D(latitude: bounds.northEastLat, longitude: bounds.northEastLng))
        
        let lat = mapView.cameraPosition.target.lat
        let lng = mapView.cameraPosition.target.lng
        viewModel.centerCoord.accept(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        
        //카메라 이동이 완료된 경우 BottomSheetView를 숨깁니다.
        hideViewsAfterUserInteraction()
    }
    
    //오버레이가 아닌 지도부분을 터치한 경우 BottomSheetView를 숨깁니다.
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        hideViewsAfterUserInteraction()
    }
    
    func hideViewsAfterUserInteraction() {
        bottomSheetView.isHidden = true
        longTappedMarker.mapView = nil
        longTappedInfoWindow.close()
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    //CLLocationManager의 delegate가 설정되는 초기 및 권한이 변경되었을때 호출된다.(설정에서 권한을 변경하고 돌아온 경우에도 호출이 되는 것 확인)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        naverMapView.showLocationButton = false  //내 위치 버튼 기본 값 보이지 않음으로 설정
        let alertCkKey = "AlertCkKey"
        let isWarned = UserDefaults.standard.bool(forKey: alertCkKey)       //권한 거부에 대한 경고 메시지를 기존에 띄웠는지 확인할 것입니다.
        
        switch locationManager.authorizationStatus {
        case .notDetermined:    //아직 정해지지 않았다면 권한 요청창을 띄운다.
            locationManager.requestWhenInUseAuthorization()
            UserDefaults.standard.setValue(false, forKey: alertCkKey)
        case .denied, .restricted:  //거부되었거나 제한된 상태라면 알림창을 띄운다. (최초 1회)
            
            if !isWarned{
                let alertController = UIAlertController(title: "권한 거부됨", message: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 - 개인정보 보호'에서 위치 서비스를 허용하여 주십시오.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
                UserDefaults.standard.setValue(true, forKey: alertCkKey)  //alert 띄웠음을 저장
            }
        case .authorizedAlways, .authorizedWhenInUse:
            naverMapView.showLocationButton = true
            UserDefaults.standard.setValue(false, forKey: alertCkKey)
        @unknown default:
            UserDefaults.standard.setValue(false, forKey: alertCkKey)
            break
        }
    }
    //권한이 이미 한번 설정되었어도 설정에 가서 변경하고 올 수 있다는 점 때문에 조금 복잡하게 작성되었다.
    //이를 테면 '허가를 했다가 설정에서 거부'를 하는 경우 location버튼은 보이면 안되고..
    //'거부를 하고 alert 본 뒤 설정에서 다른 설정을 했다가 다시 거부'를 하는 경우 다시 최초 한번 alert를 띄워야 한다던지..하는 점들 때문에.
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alertController = UIAlertController(title: "오류 발생", message: "사용자의 위치를 불러오던 도중 문제가 발생하였습니다. 다음에 다시 시도하십시오.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
        alertController.addAction(ok)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
 */
