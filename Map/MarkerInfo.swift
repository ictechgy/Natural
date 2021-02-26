//
//  MarkerInfo.swift
//  Natural
//
//  Created by JINHONG AN on 2021/02/25.
//

import Foundation

struct MarkerInfo: Codable {
    
    var roadNameAddress: String         //도로명 주소
    var landLodNumberAddress: String    //지번 주소
    var geoLocation: GeoPoint           //좌표
    var managementEntity: String        //관리주체
    var photoRef: String                //사진 참조 주소
    var characteristics: String         //특징
    var type: MarkerType
    
    struct GeoPoint: Codable {
        var latitude: Double
        var longitude: Double
    }
}

enum MarkerType: String, Codable {
    case clothes = "헌 옷 수거함"
    case battery = "폐건전지 수거함"
    case fluorescentLamp = "폐형광등 수거함"
    case medicines = "폐의약품 수거함"
    case unknown
}
