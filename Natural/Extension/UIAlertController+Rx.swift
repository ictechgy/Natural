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

    static func present(in parent: UIViewController, title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction]) -> Observable<AlertAction> {
        return Observable.create { [weak parent] observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

            actions.forEach { action in
                let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(action)     //index나 UIAlertAction 인스턴스를 스트림에 넘길 수도 있다.
                    observer.onCompleted()
                }
                alertController.addAction(alertAction)
            }
            
            guard let parent = parent else {
                observer.onCompleted()
                return Disposables.create()
            }
            parent.present(alertController, animated: true, completion: nil)
            //parent?.present(alertController, animated: true, completion: nil)로 하는 경우 parent가 없는 상황에서 스트림이 끝나지 않을 수 있음
            
            return Disposables.create {
                alertController.dismiss(animated: true, completion: nil)
            }
        }

    }

}

//또는 내가 생각해본 가능한 다른 방식(비슷하기는 하다.)
extension UIAlertController {
    //self에 별도로 UIAlertAction을 미리 추가하지 않았다고 가정
    func present(in parent: UIViewController, actions: [(title: String, style: UIAlertAction.Style)]) -> Observable<(title: String, style: UIAlertAction.Style)> {
        return Observable.create { [weak parent] emitter in
            
            actions.forEach { action in
                let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    emitter.onNext(action)  //index나 UIAlertAction 인스턴스를 스트림에 넘기는 것 가능.
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
