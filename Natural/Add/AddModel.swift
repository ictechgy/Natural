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
    private var clientId: String?
    private var clientSecret: String?
    
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
            let coords = URLQueryItem(name: "coords", value: "\(longitude),\(latitude)")    //경도-위도 순서로
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
    
    private func parseReverseGeoResult(target: ReverseGeocodeResult)-> AddressInfo {
        
        if target.status.code == 3 {    //검색은 정상적으로 수행됐으나 결과 값이 존재하지 않는 경우
            return AddressInfo(roadNameAddress: "", landLodNumberAddress: "")
        }
        
        //status code가 0인 경우(한 개 이상의 결과를 받아온 상태)
        
        var roadAddr: String = ""
        var addr: String = ""
        var legalAddr: String = ""
        var admAddr: String = ""
        
        //target 내 result 순서는 도로명,지번,법정동,행정동 순서
        target.results.forEach { result in  //result로 넘어오는 것은 도로명,지번,법정동,행정동에 해당하는 정보를 가진 각각의 개별 프로퍼티
            
            let prefix: String = conformToForm(str: result.region.area1.name) + conformToForm(str: result.region.area2.name)
                + conformToForm(str: result.region.area3.name) + conformToForm(str: result.region.area4.name)
            //행정구역 단위명칭 prefix값
            
            switch result.name {
            case "roadaddr":
                roadAddr = prefix + conformToForm(str: result.land?.name) + conformToForm(str: result.land?.number1) + conformToForm(str: result.land?.addition0.value)
                //도로명 + 건물번호 + 건물이름
            case "addr":
                if let number1 = result.land?.number1 ,let number2 = result.land?.number2, !number2.isEmpty {
                    addr = prefix + number1 + "-" + number2
                }else {
                    addr = prefix + conformToForm(str: result.land?.number1)
                }
                //토지 본번호 + 토지 부번호(부번호 없는 경우도 있음)
            case "legalcode":
                legalAddr = prefix
            case "admcode":
                admAddr = prefix
            default:
                return
            }
        }
        
        //해안선, 신규택지의 경우 도로명이나 지번주소가 없을 수 있습니다. 이 경우 법정동이나 행정동을 사용합니다. (법정동이 있다면 법정동 먼저)
        if roadAddr.isEmpty {
            roadAddr = legalAddr.isEmpty ? admAddr : legalAddr
        }
        if addr.isEmpty {
            addr = legalAddr.isEmpty ? admAddr : legalAddr
        }
        
        return AddressInfo(roadNameAddress: roadAddr, landLodNumberAddress: addr)
    }
    
    //각각의 구역단위 명칭 사이에 띄어쓰기를 넣어주기 위한 메소드
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
    }
    
    func addData(<#parameters#>) -> <#return type#> {
        <#function body#>
    }
    
    enum AddError: Error {
        case keyAcquisitionError
        case urlError
        case retrieveDataError
    }
}
