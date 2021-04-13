//
//  UIImagePickerController+RxCreate.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/13.
//
//  ref: https://github.com/ReactiveX/RxSwift/blob/main/RxExample/RxExample/Examples/ImagePicker/UIImagePickerController%2BRxCreate.swift

import Foundation
import RxSwift
import RxCocoa

func dismissViewController(_ viewController: UIViewController, animated: Bool) {
    if viewController.isBeingDismissed || viewController.isBeingPresented {
        DispatchQueue.main.async {
            dismissViewController(viewController, animated: animated)
        }
        
        return
    }

    if viewController.presentingViewController != nil {
        viewController.dismiss(animated: animated, completion: nil)
    }
}

extension Reactive where Base: UIImagePickerController {
    
    //parent(ViewController)에 대해 UIImagePickerController를 만들고 이를 띄운 뒤 Observable에 넣어 반환하는 static 메소드
    static func createWithParent(_ parent: UIViewController?, animated: Bool = true, configureImagePicker: @escaping (UIImagePickerController) throws -> Void = { x in }) -> Observable<UIImagePickerController> {
        //configureImagePicker 파라미터에는 imagePickerController에 대한 설정 closure가 들어온다. 여기서 바로 실행되는게 아니라 Observable이 subscribe되면 실행될 것이기 때문에 @escaping
        
        return Observable.create { [weak parent] observer in
            //일반적으로 VC에서는 Observable을 참조하고 Observable에 대한 subscribe 클로저에서는 VC에 대한 참조(self)를 weak로 해서 retain cycle을 방지한다. 그런데 여기서는 Observable 자체가 parent(self가 될)를 참조하므로 weak로 약한참조를 해주는 것..?
            
            let imagePicker = UIImagePickerController()
            
            let dismissDisposable = imagePicker.rx
                .didCancel
                .subscribe(onNext: { [weak imagePicker] _ in
                    guard let imagePicker = imagePicker else {
                        return
                    }
                    dismissViewController(imagePicker, animated: animated)
                })
            
            do {
                try configureImagePicker(imagePicker)
            }
            catch let error {
                observer.on(.error(error))
                return Disposables.create()
            }

            guard let parent = parent else {
                observer.on(.completed)
                return Disposables.create()
            }

            parent.present(imagePicker, animated: animated, completion: nil)
            observer.on(.next(imagePicker))
            
            return Disposables.create(dismissDisposable, Disposables.create {
                    dismissViewController(imagePicker, animated: animated)
                })
        }
    }
}
