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
        
        typeField.rx.text.orEmpty
            .bind(to: viewModel.typeRelay)
            .disposed(by: disposeBag)
        
        roadAddressField.rx.text.orEmpty
            .bind(to: viewModel.roadAddressRelay)
            .disposed(by: disposeBag)
        
        numberAddressField.rx.text.orEmpty
            .bind(to: viewModel.numberAddressRelay)
            .disposed(by: disposeBag)
        
        detailAddressField.rx.text.orEmpty
            .bind(to: viewModel.detailAddressRelay)
            .disposed(by: disposeBag)
        
        characterField.rx.text.orEmpty
            .bind(to: viewModel.characterRelay)
            .disposed(by: disposeBag)
        
        manageField.rx.text.orEmpty
            .bind(to: viewModel.manageRelay)
            .disposed(by: disposeBag)
        
        viewModel.addButtonEnabled
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
