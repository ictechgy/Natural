//
//  MarkerModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/25.
//

import Foundation
import RxSwift
import Firebase

class MarkerModel {
    static let db: Firestore = Firestore.firestore()
    
    ///지정된 좌표 bounds내에 있는 마커목록을 반환합니다.
    static func getMarkers(southWest: Coordinates, northEast: Coordinates)-> Observable<[MarkerInfo]>{
        return Observable.create { emitter in
            
            
            return Disposables.create()
        }
    }
}
