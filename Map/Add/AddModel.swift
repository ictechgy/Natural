//
//  AddModel.swift
//  Natural
//
//  Created by JINHONG AN on 2021/03/18.
//

import Foundation
import RxSwift

class AddModel {
    
    static let shared: AddModel = AddModel()
    var clientId: String?
    var clientSecret: String?
    
    private init() {
        getKeys()
    }
    
    func getKeys() {
        if clientId == nil || clientSecret == nil {
            guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String],
                  let idKey = plist["ClientId"], let secretKey = plist["ClientSecret"] else {
                return
            }
            clientId = idKey
            clientSecret = secretKey
        }
    }
    
    func coordToAddr(latitude: Double, longitude: Double)-> Observable<Void> {
        getKeys()
        
        return Observable.create { emitter in
            
            guard let idValue = self.clientId, let secretValue = self.clientSecret else {
                emitter.onError(AddError.keyAcquisitionError)
                return Disposables.create()
            }
            //이 메소드를 통해 반환되는 클로저는 self에 대한 강한참조를 지니게 된다.(shared static 인스턴스에 대한 강한 참조)
            
            
            let urlSession = URLSession(configuration: .ephemeral)
            
            var urlComponents = URLComponents(string: "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc")
            let coords = URLQueryItem(name: "coords", value: "\(latitude),\(longitude)")
            let orders = URLQueryItem(name: "orders", value: "roadaddr,addr,legalcode,admcode") //결과는 도로명,지번,법정동,행정동 순서로
            let output = URLQueryItem(name: "output", value: "json")
            
            urlComponents?.percentEncodedQueryItems = [coords, orders, output]
            
            guard let url = urlComponents?.url else {
                emitter.onError(AddError.urlError)
                return Disposables.create()
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue(idValue, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
            urlRequest.addValue(secretValue, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
            
            let task = urlSession.dataTask(with: urlRequest) { data, response, error in
                
                guard let data = data else {
                    emitter.onError(error ?? AddError.retrieveDataError)
                    return
                }
                
                
                
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    enum AddError: Error {
        case keyAcquisitionError
        case urlError
        case retrieveDataError
    }
}
