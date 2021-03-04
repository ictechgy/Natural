//
//  MarkerModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/25.
//

import Foundation
import RxSwift
import Firebase
import GeoFire

class MarkerModel {
    static let db: Firestore = Firestore.firestore()
    
    ///중심 좌표와 정해진 반경(Meter) 내에 있는 마커목록을 반환합니다.
    static func getMarkers(centerCoordinates center: CLLocationCoordinate2D, radiusInMeters radius: Double)-> Observable<[MarkerInfo]>{
        return Observable.create { emitter in
            
            //FireStore에서 GeoPoint로는 근접 doc들을 가져올 수가 없다.(GeoPoint비교 시 latitude 비교 후 같은 lat 내에서 longitude비교)
            //따라서 아래와 같이 GeoHash를 이용한다.
            let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radius)
            //구글 Reference Doc에는 2번째 인자의 값이 Km로 나와있으나 실제로는 meter단위이다. 
            //얼마만큼 Bounding Box를 잘게 쪼개느냐에 따라 클라이언트/서버의 부담이 달라질 듯 하다.
            //크게 쪼개면 서버 부담은 적겠지만 그만큼 잘못된 검색결과가 많이 나올테고, 그러면 클라이언트에서 거리로 체크하는 부하가 많아지지 않을까
            
            let queries = queryBounds.compactMap { (any) -> Query? in       //최대 9쌍의 bound, 보통 4쌍 - radius를 이용해서 정사각형의 bound들을 만들어오는 듯?
                guard let bound = any as? GFGeoQueryBounds else { return nil }
                print("\(bound.startValue) and \(bound.endValue)")
                return db.collection("Markers")
                    .order(by: "geoHash")
                    .start(at: [bound.startValue])
                    .end(at: [bound.endValue])
            }
            print("geoHash: \(GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: 37.5033435, longitude: 126.9522254)))")
            var matchingDocs: [QueryDocumentSnapshot] = []
            let dispatchGroup: DispatchGroup = DispatchGroup()
            db.collection("Markers").document("T6fMgpPcCMCVp0qFHmOT").getDocument { (snapshot, error) in
                print(snapshot?.data())
            }
            db.collection("Markers").order(by: "geoHash").getDocuments { (snap, err) in
                print("test - \(snap?.count)")
            }
            for query in queries {
                dispatchGroup.enter()
                query.getDocuments { (snapshot: QuerySnapshot?, error: Error?) in   //completion callback
                    print(snapshot?.count)
                    guard let documents = snapshot?.documents else {
                        print("error")
                        dispatchGroup.leave()
                        return
                    }
                    print(documents)
                    for document in documents {
                        let lat = document.data()["latitude"] as? Double ?? 0
                        let lng = document.data()["longitude"] as? Double ?? 0
                        let coordinates = CLLocation(latitude: lat, longitude: lng)
                        let centerPoint = CLLocation(latitude: center.latitude, longitude: center.longitude)
                        
                        let distance = GFUtils.distance(from: centerPoint, to: coordinates)
                        print(distance)
                        if distance <= radius {
                            matchingDocs.append(document)
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.global()) {
                var result: [MarkerInfo] = []
                
                matchingDocs.forEach { snapshot in
                    let dictionary: [String: Any] = snapshot.data()
                    
                    let marker = MarkerInfo(
                        roadNameAddress: dictionary["roadNameAddress"] as? String ?? "",
                        landLodNumberAddress: dictionary["landLodNumberAddress"] as? String ?? "",
                        detailAddress: dictionary["detailAddress"] as? String ?? "",
                        geoHash: dictionary["geoHash"] as? String ?? "",
                        latitude: dictionary["latitude"] as? Double ?? 0,
                        longitude: dictionary["longitude"] as? Double ?? 0,
                        managementEntity: dictionary["managementEntity"] as? String ?? "",
                        photoRef: dictionary["photoRef"] as? String ?? "",
                        characteristics: dictionary["characteristics"] as? String ?? "",
                        type: MarkerType.init(rawValue: dictionary["type"] as? String ?? "") ?? .unknown
                    )
                    
                    result.append(marker)
                }
                print(result)
                emitter.onNext(result)
                emitter.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
