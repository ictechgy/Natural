//
//  AddViewController.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/15.
//

import UIKit
import RxSwift

class AddViewController: UIViewController {
    
    var viewModel: AddViewModel!
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var roadAddressField: UITextField!
    @IBOutlet weak var numberAddressField: UITextField!
    @IBOutlet weak var detailAddressField: UITextField!
    @IBOutlet weak var characterField: UITextField!
    @IBOutlet weak var manageField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    let pickerView: UIPickerView = UIPickerView()
    var selected: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        bindAddressFieldsEnabled()
        
        viewModel.addressFetched
            .filter { $0 }
            .take(1)            //true인 경우에만 단 한번 받는다.
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] _ in
                self?.bindAddressFieldsText()
            })
            .disposed(by: disposeBag)
        
        bindOtherFields()
        setUpPickerView()
        
        bindImageView()
        bindAddButton()
    }
    
    private func bindAddressFieldsEnabled() {
        viewModel.roadAddressEnabled.distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(roadAddressField.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.numberAddressEnabled.distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(numberAddressField.rx.isEnabled)
            .disposed(by: disposeBag)
        //스트림에 에러 발생 시 일단 에딧은 가능해야 하므로 true 반환
    }
    
    private func bindAddressFieldsText() {
        //데이터가 잘 도착 한 경우 먼저 해당 데이터들을 필드에 넣어주기
        viewModel.roadAddressRelay
            .take(1)
            .asDriver(onErrorJustReturn: "")
            .drive(roadAddressField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.numberAddressRelay
            .take(1)
            .asDriver(onErrorJustReturn: "")
            .drive(numberAddressField.rx.text)
            .disposed(by: disposeBag)
        
        //이후 역으로 TextField들을 VM 프로퍼티에 바인딩
        roadAddressField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.roadAddressRelay)
            .disposed(by: disposeBag)
        
        numberAddressField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.numberAddressRelay)
            .disposed(by: disposeBag)
    }
    
    private func bindOtherFields() {
        typeField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.typeRelay)
            .disposed(by: disposeBag)
        
        detailAddressField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.detailAddressRelay)
            .disposed(by: disposeBag)
        
        characterField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.characterRelay)
            .disposed(by: disposeBag)
        
        manageField.rx.text.orEmpty.distinctUntilChanged()
            .bind(to: viewModel.manageRelay)
            .disposed(by: disposeBag)
        
    }
    
    private func setUpPickerView() {
        pickerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 220)
        
        _ = viewModel.kindOfMarkersObservable   //Observable.just
            .bind(to: pickerView.rx.itemTitles) { _, element in
                return element
            }
        pickerView.rx.itemSelected
            .subscribe(onNext: { [weak self] row, _ in
                self?.selected = self?.viewModel.kindOfMarkers[row] ?? ""   //kindOfMarkers List
            })
            .disposed(by: disposeBag)
        //selected 프로퍼티도 Observable(Relay)로 선언해서 구현 할 수도 있고.. 방법은 정말 많다.
        
        //pickerView 위에 조그맣게 보일 툴바
        let pickerToolbar: UIToolbar = UIToolbar()
        pickerToolbar.barStyle = .default
        pickerToolbar.isTranslucent = true
        pickerToolbar.backgroundColor = .lightGray
        pickerToolbar.sizeToFit()
        
        let btnOk = UIBarButtonItem(title: "확인", style: .done, target: nil, action: nil)
        btnOk.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.typeField.text = self?.selected
                self?.typeField.resignFirstResponder()
                self?.selected = ""
            })
            .disposed(by: disposeBag)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)  //여백공간
        let btnCancel = UIBarButtonItem(title: "취소", style: .done, target: nil, action: nil)
        btnCancel.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.typeField.resignFirstResponder()
                self?.selected = ""
            })
            .disposed(by: disposeBag)
        
        pickerToolbar.setItems([btnCancel, space, btnOk], animated: true)
        pickerToolbar.isUserInteractionEnabled = true
        
        typeField.inputView = pickerView
        typeField.inputAccessoryView = pickerToolbar
        
        
    }
    
    private func bindImageView() {
        
        let fromCamera = Reactive<UIAlertController>.AlertAction.action(title: "카메라", style: .default)
        let fromLibrary = Reactive<UIAlertController>.AlertAction.action(title: "사진 앨범", style: .default)
        let cancel = Reactive<UIAlertController>.AlertAction.action(title: "취소", style: .cancel)
        
        imageViewTapGestureRecognizer.rx.event  //메인 시퀀스
            .flatMapLatest { [weak self] _ -> Observable<Reactive<UIAlertController>.AlertAction> in
                
                //분기되는 시퀀스
                return UIAlertController.rx.present(in: self, title: "사진 추가하기", message: "추가 방법을 선택해주세요.", style: .actionSheet, actions: [fromCamera, fromLibrary, cancel]).take(1)     //onCompleted 시점이 존재하므로 take() operator를 쓰지 않아도 될 듯
            }
            .map { [weak self] alertAction -> Observable<UIImagePickerController>? in   //여기서 flatMap을 쓰고 예외상황 시 nil 대신에 Observable.just에 의미없는 값을 집어넣어서 반환하는 방식도 가능할 듯. 물론 반환 타입은 조금 달라져야겠지.. optional 아니게
                //alertAction 선택에 따라 시퀀스를 다시 분기.
                switch alertAction {
                case fromCamera:
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        return UIImagePickerController.rx.createWithParent(self) { picker in
                            picker.sourceType = .camera
                            picker.allowsEditing = false
                        }.take(1)       //이 시퀀스의 경우 onCompleted시점이 명확히 정해져 있지 않으므로 take(1)을 써야 할 듯.
                    }else {
                        //카메라 사용이 불가능한 경우
                        let ok = Reactive<UIAlertController>.AlertAction.action(title: "확인", style: .default)
                        _ = UIAlertController.rx.present(in: self, title: "오류 발생", message: "카메라 사용이 불가능합니다.", style: .alert, actions: [ok])
                            .take(1)
                            .subscribe(onNext: { _ in })    //별도로 할 것 없음
                    }
                case fromLibrary:
                    return UIImagePickerController.rx.createWithParent(self) { picker in
                        picker.sourceType = .photoLibrary
                        picker.allowsEditing = false
                    }.take(1)
                default:    //cancel 포함
                    break
                }
                return nil
            }
            .filter{ $0 != nil }
            .flatMap{ $0! }
            .flatMapLatest{ $0.rx.didFinishPickingMediaWithInfo.take(1) } //flatMap은 Observable이 중첩되어 내려온 경우에만 쓸 수 있는게 아니라 중첩될 것으로 예상되는 부분에서 바로 쓸 수도 있구나.
            .map{ info in
                return info[.originalImage] as? UIImage
            }
            .subscribe(onNext: { [weak self] image in
                self?.imageView.image = image
                self?.viewModel.imageRelay.accept(image) //image 데이터를 ViewModel에 같이 바로 바인딩
            })
            .disposed(by: disposeBag)
        
        //map: 스트림 데이터의 변화
        //flatMap: 스트림 데이터가 Observable<데이터>로 변화할 것인데(또는 이미 변화된 것에 대해) 이 중첩되어 안에 있는 데이터를 바로 꺼낼 것
        //flatMapLatest: flatMap과 같지만 가장 최근의 것에만 집중
        
    }
    
    private func bindAddButton() {
        
        viewModel.addButtonEnabled.distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive { [weak self] isEnabled in
                self?.addButton.isEnabled = isEnabled
                
                var bgColor: UIColor
                if isEnabled {
                    bgColor = .systemGreen
                }else {
                    bgColor = .systemGray
                }
                
                self?.addButton.backgroundColor = bgColor
            }
            .disposed(by: disposeBag)
        
        addButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.addButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


