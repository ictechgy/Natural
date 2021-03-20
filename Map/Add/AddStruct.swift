//
//  AddStruct.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/19.
//

import Foundation

struct ReverseGeocodeResult: Codable {
    
    var status: Status
    var results: [Result]
    
    
    struct Status: Codable {
        var code: Int
        var name: String
        var message: String
    }
    
    struct Result: Codable {
        var name: String
        var code: Code
        var region: Region
        var land: Land?
        
        struct Code: Codable {
            var id: String
            var type: String
            var mappingId: String
        }
        
        struct Region: Codable {
            var area0: Area
            var area1: Area
            var area2: Area
            var area3: Area
            var area4: Area
            
            struct Area: Codable {
                var name: String
                var coords: Coords
                var alias: String?
            }
        }
        
        struct Coords: Codable {
            var center: Center
            
            struct Center: Codable {
                var crs: String
                var x: Double
                var y: Double
            }
        }
        
        struct Land: Codable {
            var type: String
            var number1: String
            var number2: String
            var addition0: Addition
            var addition1: Addition
            var addition2: Addition
            var addition3: Addition
            var addition4: Addition
            var name: String?
            var coords: Coords
            
            struct Addition: Codable {
                var type: String
                var value: String
            }
            
        }
    }
}

struct AddressInfo {
    var roadNameAddress: String
    var landLodNumberAddress: String
    var legalAddress: String
    var administrativeAddress: String
}
