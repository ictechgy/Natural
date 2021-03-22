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
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var roadAddressField: UITextField!
    @IBOutlet weak var numberAddressField: UITextField!
    @IBOutlet weak var detailAddressField: UITextField!
    @IBOutlet weak var characterField: UITextField!
    @IBOutlet weak var manageField: UITextField!
    @IBOutlet weak var addButton: UIButton!

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
        
        viewModel.addButtonEnabled.distinctUntilChanged()
            .bind(to: addButton.rx.isEnabled)
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
