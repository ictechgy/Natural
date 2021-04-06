//
//  UIImagePickerController+UINavigationController+Rx.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/05.
//

import Foundation
import RxSwift
import RxCocoa

/*
 찾아본 내용에 대한 정리.
 1. UIImagePickerController의 delegate는 UIImagePickerControllerDelegate와 UINavigationControllerDelegate를 모두 채택하여야 한다.
 UIImagePickerController의 delegate는 weak var delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? { get set } 으로 되어있는데, 프로퍼티의 클래스타입이 &로 묶여 2개가 함께 있는 것은 처음본다.
 2. UIImagePickerController의 rx에는 UINavigationControllerDelegate 메소드인 willShow와 didShow에 대한 ControlEvent가 이미 구현되어 있다.
 (UINavigationControllerDelegate에 대한 DelegateProxy가 이미 구현되어 있다는 뜻?)
 3. RxSwift Github - RxExample 에 CLLocationManager, UIImagePickerController에 대한 Reactive Extension 예시 및 사용 예시가 작성되어 있다.
 해당 Reactive Extension들은 기본적으로 추가되어있는 것이 아니었다. CLLocationManager에 대한 Extension의 경우 내가 구현한 것과는 좀 다르다. (didUpdateLocations, didFailWithError를 DelegateProxy 자체 내부 프로퍼티를 통해 처리하느냐, Extension 프로퍼티로서 처리하느냐의 차이?) UIImagePickerController에 대한 Rx Extension의 경우 proxy register 부분이 AppDelegate에 있다는 점과 RxCreate Extension이 추가적으로 있다는 점은 특이하다. 해당 Example들을 사용해보는 것도 좋을 것 같다.
 - 참고 링크 -
 https://github.com/ReactiveX/RxSwift/tree/main/RxExample/Extensions
 https://github.com/ReactiveX/RxSwift/tree/main/RxExample/RxExample/Examples/ImagePicker
 https://github.com/ReactiveX/RxSwift/blob/main/RxExample/RxExample/iOS/AppDelegate.swift
 */

class RxUIImagePickerControllerDelegateProxy: 
