//
//  DetailViewController.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/14.
//

import UIKit
import RxSwift
import RxCocoa

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var roadAddressLabel: UILabel!
    @IBOutlet weak var numberAddressLabel: UILabel!
    @IBOutlet weak var detailAddressLabel: UILabel!
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var manageLabel: UILabel!
    @IBOutlet weak var informerLabel: UILabel!
    
    var viewModel: MapViewModel!
    var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        viewModel.markerImage
            .asDriver()
            .drive(onNext: { [weak self] image in
                self?.imageView.image = image
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedMarker
            .asDriver()
            .drive(onNext: { [weak self] markerInfo in
                
                self?.typeLabel.text = markerInfo.type.rawValue
                self?.roadAddressLabel.text = markerInfo.roadNameAddress
                self?.numberAddressLabel.text = markerInfo.landLodNumberAddress
                self?.detailAddressLabel.text = markerInfo.detailAddress
                self?.characterLabel.text = markerInfo.characteristics
                self?.manageLabel.text = markerInfo.managementEntity
                self?.informerLabel.text = markerInfo.informerNickname
                
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
