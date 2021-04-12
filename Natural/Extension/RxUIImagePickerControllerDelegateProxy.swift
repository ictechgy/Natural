//
//  RxUIImagePickerControllerDelegateProxy.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/08.
//

import Foundation
import RxSwift
import RxCocoa

/*
 //처음에 생각했던 class 형태
class RxUIImagePickerControllerDelegateProxy: DelegateProxy<UIImagePickerController, UIImagePickerControllerDelegate & UINavigationControllerDelegate>, DelegateProxyType, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    static func registerKnownImplementations() {
        self.register { imagePickerController -> RxUIImagePickerControllerDelegateProxy in
            RxUIImagePickerControllerDelegateProxy(parentObject: imagePickerController, delegateProxy: self)
        }
    }
    
    static func currentDelegate(for object: UIImagePickerController) -> (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? {
        object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?, to object: UIImagePickerController) {
        object.delegate = delegate
    }
}
*/

//RxSwift Github - RxExample 참고
class RxUIImagePickerControllerDelegateProxy: RxNavigationControllerDelegateProxy, UIImagePickerControllerDelegate {
    //RxNavigationControllerDelegateProxy를 채택하고 거기에 UIImagePickerControllerDelegate에 대한 proxy기능 추가를 위해 별도 추가 채택을 한 느낌?
    
    public init(imagePicker: UIImagePickerController) {
        super.init(navigationController: imagePicker) //imagePickerController가 navigationController로서 들어간다라..
    }
    
    /*
    //RxSwift Github에 구현되어있는 위의 init과 AppDelegate에 있는 RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) } 를 아래 메소드로 통합하려 했으나 static func는 override가 불가능
    
    static func registerKnownImplementations() {
        self.register { imagePickerController -> RxUIImagePickerControllerDelegateProxy in
            RxUIImagePickerControllerDelegateProxy(navigationController: imagePickerController)
        }
    }
     
     //아마도 RxNavigationControllerDelegateProxy에는 아래와 같이 구현되어 있을 것.
     public init(navigationController: UINavigationController) {
        super.init(parentObject: navigationController, delegateProxy: RxNavigationControllerDelegateProxy.self)
     }
     
     static func registerKnownImplementations() { RxNavigationControllerDelegateProxy(navigationController: $0) }
     */
}
