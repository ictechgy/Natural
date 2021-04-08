//
//  RxUIImagePickerControllerDelegateProxy.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/08.
//

import Foundation
import RxSwift
import RxCocoa

class RxUIImagePickerControllerDelegateProxy: DelegateProxy<UIImagePickerController, UIImagePickerControllerDelegate & UINavigationControllerDelegate>, DelegateProxyType, UIImagePickerControllerDelegate {
    
    static func registerKnownImplementations() {
        
    }
    
    static func currentDelegate(for object: UIImagePickerController) -> (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? {
        object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?, to object: UIImagePickerController) {
        object.delegate = delegate
    }
    
    
    
    
}
