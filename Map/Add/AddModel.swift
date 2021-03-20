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
    
    private func getKeys() {
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
    
    func coordToAddr(latitude: Double, longitude: Double)-> Observable<AddressInfo> {
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
                
                guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    emitter.onError(error ?? AddError.retrieveDataError)
                    return
                }
                
                let decoder = JSONDecoder()
                
                do {
                    let result = try decoder.decode(ReverseGeocodeResult.self, from: data)
                    let addressInfo = self.parseReverseGeoResult(target: result)
                    emitter.onNext(addressInfo)
                    emitter.onCompleted()
                } catch {
                    emitter.onError(error)
                }
                
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    func parseReverseGeoResult(target: ReverseGeocodeResult)-> AddressInfo {
        
        var roadAddr: String = ""
        var addr: String = ""
        var legalAddr: String = ""
        var admAddr: String = ""
        
        //target 내 result 순서는 도로명,지번,법정동,행정동 순서
        target.results.forEach { result in  //result로 넘어오는 것은 도로명,지번,법정동,행정동에 해당하는 정보를 가진 각각의 개별 객체
            
            let prefix: String = conformToForm(str: result.region.area1.name) + conformToForm(str: result.region.area2.name)
                + conformToForm(str: result.region.area3.name) + conformToForm(str: result.region.area4.name)
            
            switch result.name {
            case "roadaddr":
                roadAddr = prefix + conformToForm(str: result.land?.name) + conformToForm(str: result.land?.number1) + conformToForm(str: result.land?.addition0.value)
            case "addr":
                addr = prefix +
            case "legalcode":
                legalAddr = prefix +
            case "admcode":
                admAddr = prefix +
            default:
                break
            }
        }
        
        return AddressInfo(roadNameAddress: roadAddr, landLodNumberAddress: addr, legalAddress: legalAddr, administrativeAddress: admAddr)
    }
    
    private func conformToForm(str: String?)-> String {
        switch str {
        case .none:
            return ""
        case .some(let unWrappedStr):
            switch unWrappedStr.count {
            case 0:
                return unWrappedStr
            default:
                return "\(unWrappedStr) "   //뒤에 띄어쓰기 하나 포함하여 return
            }
    }
    
    enum AddError: Error {
        case keyAcquisitionError
        case urlError
        case retrieveDataError
    }
}
