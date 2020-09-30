//
//  MindCloud.swift
//  Mind
//
//  Created by Anton Evstigneev on 14.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire



let sharedManager: Session = {
    let configuration = URLSessionConfiguration.default
    configuration.waitsForConnectivity = true
    
    let manager = Session(configuration: configuration, startRequestsImmediately: true)
    return manager
}()



class MindCloud {
    
    class var isUserAuthorized: Bool {
        return UserDefaults.standard.object(forKey: "isAuthorized") as! Bool
    }
    
    class var isConnectedToInternet: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
    
//    static let url = "http://3.130.38.239:8080" // aws
    static let url = "http://192.168.1.2:8000" // localhost
    static let token = UserDefaults.standard.object(forKey: "authorizationToken") as! String
    static let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json",
    ]
    
    typealias RequestCompletion = (ThoughtData?, Bool) -> ()
    

    static func processThought(content: String, completion: @escaping RequestCompletion) {
        
        let parameters: [String: Any] = [
            "content": content,
        ]
        
        let request = sharedManager.request("\(url)/api/data",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: nil).validate()
        
        getThoughtDataResponse(from: request) { (responseData, success) in
            completion(responseData, success)
        }
    }
    
    
    static func postThought(content: String, timestamp: Int64, completion: @escaping RequestCompletion) {
        
        let parameters: [String: Any] = [
            "content": content,
            "timestamp": timestamp,
        ]
        
        let request = sharedManager.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) { (responseData, success) in
           completion(responseData, success)
        }
    }


    static func updateThought(id: String, upd: [String: Any], completion: @escaping RequestCompletion) {
        
        let parameters: [String: Any] = [
            "id": id,
            "upd": upd,
        ]
        
        let request = sharedManager.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) { (responseData, success) in
//           debugPrint(responseData)
           completion(responseData, success)
        }
    }

    
    static func deleteThought(id: String, completion: @escaping RequestCompletion) {
        
        let parameters: [String: Any] = [
            "id": id,
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        
        let request = sharedManager.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) { (responseData, success) in
           completion(responseData, success)
        }
    }
    

    static func createAccout(email: String, password: String, publicKey: String, encryptedPrivateKey: String, iv: String) {
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "publicKey": publicKey,
            "encryptedPrivateKey": encryptedPrivateKey,
            "iv": iv,
        ]

        AF.request("\(url)/api/user",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: nil).responseData(completionHandler: { response in
                     
            switch response.result {
            case .success:
                if let code = response.response?.statusCode{
                    switch code {
                    case 200...299:
                        //save token
                        self.getAuthorizationToken(email: email, password: password) { (token, success) in
                            if (success) {
                             UserDefaults.standard.set(token, forKey: "authorizationToken")
                            }
                        }
                    default:
                     let error = NSError(domain: response.debugDescription, code: code, userInfo: response.response?.allHeaderFields as? [String: Any])
                        print(error)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    )}
    
    
    static func getAuthorizationToken(email: String, password: String, completion: @escaping (String, Bool) -> ()) {
        var token: String = ""
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
        ]
        
        sharedManager.request("\(url)/api/token",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: nil).responseJSON { response in
                    
            debugPrint(response)
            switch response.result {
                case .success:
                let data = response.value as! [String: Any]
                token = data["token"] as? String ?? ""
                UserDefaults.standard.set(token, forKey: "authorizationToken")
                UserDefaults.standard.set(true, forKey: "isAuthorized")
                print(token)
                completion(token, true)
                    break
                case .failure(let error):
                    print(error)
                    completion("", false)
            }
        }
    }
    
    
    static func getThoughtDataResponse(from request: DataRequest, completion: @escaping RequestCompletion) {
        request.responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let thoughtData = try JSONDecoder().decode(ThoughtData.self, from: data)
                    completion(thoughtData, true)
                } catch {
                    completion(nil, false)
                }
            case .failure(let error):
                print("❗️ERROR")
                print(error.localizedDescription)
            }
        }
    }
    
}


