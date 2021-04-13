//
//  UIImagePickerController+Rx.swift
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
 (UINavigationControllerDelegate에 대한 DelegateProxy가 이미 구현되어 있다는 뜻? - 찾아보니 RxNavigationControllerDelegateProxy라는 클래스가 존재한다. 아마 이걸 별도로? 이용하는 방식인 듯?)
 3. RxSwift Github - RxExample 에 CLLocationManager, UIImagePickerController에 대한 Reactive Extension 예시 및 사용 예시가 작성되어 있다.
 해당 Reactive Extension들은 기본적으로 추가되어있는 것이 아니었다. CLLocationManager에 대한 Extension의 경우 내가 구현한 것과는 좀 다르다. (didUpdateLocations, didFailWithError를 DelegateProxy 자체 내부 프로퍼티를 통해 처리하느냐, Extension 프로퍼티로서 처리하느냐의 차이?) UIImagePickerController에 대한 Rx Extension의 경우 proxy register 부분이 AppDelegate에 있다는 점과 RxCreate Extension이 추가적으로 있다는 점은 특이하다. 해당 Example들을 사용해보는 것도 좋을 것 같다.
 - 참고 링크 -
 https://github.com/ReactiveX/RxSwift/tree/main/RxExample/Extensions
 https://github.com/ReactiveX/RxSwift/tree/main/RxExample/RxExample/Examples/ImagePicker
 https://github.com/ReactiveX/RxSwift/blob/main/RxExample/RxExample/iOS/AppDelegate.swift
 */

extension Reactive where Base: UIImagePickerController {
    
    /*
     //처음에 생각했던 delegate 프로퍼티 형태
    var delegate: DelegateProxy<UIImagePickerController, UIImagePickerControllerDelegate & UINavigationControllerDelegate> {
        RxUIImagePickerControllerDelegateProxy.proxy(for: self.base)
    }
     */
    
    //delegate 프로퍼티는 이미 존재한다. (UINavigationController의 UINavigationControllerDelegateProxy관련 Extension에 의해)
    //해당 delegate는 DelegateProxy<UINavigationController, UINavigationControllerDelegate> 타입인데 어떻게 여기서 UIImagePickerControllerDelegate로서의 역할도 수행하게 되는 걸까? 아마도 delegate(proxy)를 만들 때(register) UINavigationController인자에 imagePickerController를 넘겨줘서 그런 거일 듯? 실제로 UIImagePickerController는 UINavigationController를 채택하여 구현되어 있다.(Reactive가 extension되어있는 특정 클래스를 채택하면 extension도 같이 딸려오는 듯)
    
    /**
      Reactive wrapper for `delegate` message.
    */
     public var didFinishPickingMediaWithInfo: Observable<[UIImagePickerController.InfoKey : AnyObject]> {
         return delegate
             .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:)))
             .map { parameters in
                 return try castOrThrow(Dictionary<UIImagePickerController.InfoKey, AnyObject>.self, parameters[1])
             }
     }

     /**
      Reactive wrapper for `delegate` message.
     */
     public var didCancel: Observable<Void> {
         return delegate
             .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerControllerDidCancel(_:)))
             .map { _ in
                return ()
             }
     }
}

private func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }

    return returnValue
}
