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

//UIImagePickerController를 dismiss하기 위한 메소드
func dismissViewController(_ viewController: UIViewController, animated: Bool) {
    //recursive case
    if viewController.isBeingDismissed || viewController.isBeingPresented {     //viewController가 사라지고 있거나 나타나고 있는 경우
        DispatchQueue.main.async {      //메인 쓰레드에서
            dismissViewController(viewController, animated: animated)   //이 메소드를 재귀호출 한다.
        }
        
        return
    }
    
    //base case - viewController가 being Dismissed, being Presented 상태가 아니라면 아래의 if문을 실행한다.
    if viewController.presentingViewController != nil {     //이 viewController를 present로 띄운 ViewController가 nil이 아니라면
        viewController.dismiss(animated: animated, completion: nil)     //이 ViewController를 dismiss합니다.
    }
}

extension Reactive where Base: UIImagePickerController {
    
    //parent(ViewController)에 대해 UIImagePickerController를 만들고 이를 띄운 뒤 UIImagePickerController를 Observable에 넣어 반환하는 static 메소드
    static func createWithParent(_ parent: UIViewController?, animated: Bool = true, configureImagePicker: @escaping (UIImagePickerController) throws -> Void = { x in }) -> Observable<UIImagePickerController> {
        //configureImagePicker 파라미터에는 imagePickerController에 대한 설정 closure가 들어온다. 여기서 바로 실행되는게 아니라 Observable이 subscribe되면 실행될 것이기 때문에 @escaping
        
        return Observable.create { [weak parent] observer in
            //일반적으로 VC에서는 Observable 스트림을 참조하고 Observable에 대한 subscribe 클로저에서는 VC에 대한 참조(self)를 weak로 해서 retain cycle을 방지한다. 그런데 여기서는 Observable 자체가 먼저 parent(자기 자신을 참조할 부모)를 참조하므로 weak로 약한참조를 해주는 것..?
            
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
                return Disposables.create() //왜 여기서는 dismissDisposable이 안들어가있는걸까
            }

            guard let parent = parent else {
                observer.on(.completed)
                return Disposables.create() //여기서도 dismissDisposable은 안들어가 있다.
            }

            parent.present(imagePicker, animated: animated, completion: nil)
            observer.on(.next(imagePicker))
            
            //정상적으로 다 수행된 경우에 대한 onCompleted가 명시적으로 존재하지 않는다.
            return Disposables.create(dismissDisposable, Disposables.create {
                    dismissViewController(imagePicker, animated: animated)  //이 스트림이 dispose될 때 imagePicker를 dismiss하기 위해 이렇게 둔 듯 하다.
                })
        }
    }
}
