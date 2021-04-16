//
//  UIAlertController+Rx.swift
//  Natural
//
//  Created by JINHONG AN on 2021/04/15.
//
// ref: https://stackoverflow.com/questions/49538546/how-to-obtain-a-uialertcontroller-observable-reactivecocoa-or-rxswift
// 위의 ref를 참고하여 만들었으며 조금 수정을 하였다.

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UIAlertController {

    struct AlertAction {
        var title: String?
        var style: UIAlertAction.Style

        static func action(title: String?, style: UIAlertAction.Style = .default) -> AlertAction {
            return AlertAction(title: title, style: style)
        }
    }

    static func present(in parent: UIViewController, title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction]) -> Observable<UIAlertAction> {
        return Observable.create { [weak parent] observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

            actions.forEach { action in
                let alertAction = UIAlertAction(title: action.title, style: action.style) { alertAction in
                    observer.onNext(alertAction)
                    observer.onCompleted()
                }
                alertController.addAction(alertAction)
            }
            
            guard let parent = parent else {
                observer.onCompleted()
                return Disposables.create()
            }
            parent.present(alertController, animated: true, completion: nil)
            
            return Disposables.create {
                alertController.dismiss(animated: true, completion: nil)
            }
        }

    }

}

//또는 내가 생각해본 가능한 다른 방식(비슷하기는 하다.)
extension UIAlertController {
    //여기서 self에 별도로 UIAlertAction은 추가하지 않았다고 가정
    func present(in parent: UIViewController, actions: [(title: String, style: UIAlertAction.Style)]) -> Observable<UIAlertAction> {
        return Observable.create { [weak parent] emitter in
            
            actions.forEach { action in
                let alertAction = UIAlertAction(title: action.title, style: action.style) {
                    emitter.onNext($0)
                    emitter.onCompleted()
                }
                self.addAction(alertAction)
            }
            
            guard let parent = parent else {
                emitter.onCompleted()
                return Disposables.create()
            }
            parent.present(self, animated: true, completion: nil)
            
            return Disposables.create {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
