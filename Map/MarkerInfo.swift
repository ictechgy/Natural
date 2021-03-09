//
//  MarkerInfo.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/25.
//

import Foundation

struct MarkerInfo: Codable {
    
    var id: String                      //고유 식별자
    var informerId: String              //제보자 id
    var informerNickname: String        //제보자 닉네임
    var roadNameAddress: String         //도로명 주소
    var landLodNumberAddress: String    //지번 주소
    var detailAddress: String           //상세주소
    var geoHash: String                 //GeoHash 값
    var latitude: Double                //위도
    var longitude: Double               //경도
    var managementEntity: String        //관리주체
    var photoRef: String                //사진 참조 주소
    var characteristics: String         //특징
    var type: MarkerType
    
    static func getDummyMarker()-> MarkerInfo{
        return MarkerInfo(id: "", informerId: "", informerNickname: "", roadNameAddress: "", landLodNumberAddress: "", detailAddress: "", geoHash: "", latitude: 0, longitude: 0, managementEntity: "", photoRef: "", characteristics: "", type: .unknown)
    }
}

enum MarkerType: String, Codable {
    case clothes = "헌 옷 수거함"
    case battery = "폐건전지 수거함"
    case fluorescentLamp = "폐형광등 수거함"
    case medicines = "폐의약품 수거함"
    case unknown
}
