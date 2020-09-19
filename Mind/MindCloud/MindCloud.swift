//
//  MindCloud.swift
//  Mind
//
//  Created by Anton Evstigneev on 14.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire

let sessionManager = Session()
let requestRetrier = NetworkRequestRetrier()


class MindCloud {
    
    class var isUserAuthorized: Bool {
        return UserDefaults.standard.object(forKey: "isAuthorized") as! Bool
    }
    
    
    static let url = "http://3.130.38.239:8080"
    static let token = UserDefaults.standard.object(forKey: "authorizationToken") as! String
    static let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json",
    ]
    
    
    static func postThought(content: String, timestamp: Int64, completion: @escaping (ThoughtData?, Bool) -> Void) {
        
        let parameters: [String: Any] = [
            "content": content,
            "timestamp": timestamp,
        ]
        
        let request = AF.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) {(responseData, success) in
//           debugPrint(responseData)
           completion(responseData, success)
        }
    }


    static func updateThought(id: String, upd: [String: Any], completion: @escaping (ThoughtData?, Bool) -> Void) {
        
        let parameters: [String: Any] = [
            "id": id,
            "upd": upd,
        ]
        
        let request = AF.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) {(responseData, success) in
           debugPrint(responseData)
           completion(responseData, success)
        }
    }

    
    static func deleteThought(id: String, completion: @escaping (ThoughtData?, Bool) -> Void) {
        
        let parameters: [String: Any] = [
            "id": id,
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        
        let request = AF.request("\(url)/api/notes",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
        
        getThoughtDataResponse(from: request) {(responseData, success) in
           completion(responseData, success)
        }
    }
    
    
    
    static func processThought(content: String, completion: @escaping (ThoughtData?, Bool) -> Void) {
        
        let parameters: [String: Any] = [
            "content": content,
        ]
        
        let request = AF.request("\(url)/api/data",
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: nil)
        
        getThoughtDataResponse(from: request) {(responseData, success) in
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
    
    
    static func getAuthorizationToken(email: String, password: String, completion: @escaping (String, Bool) -> Void) {
        var token: String = ""
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
        ]
        
        AF.request("\(url)/api/token",
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
    
    
    static func getThoughtDataResponse(from request: DataRequest, completion: @escaping (ThoughtData?, Bool) -> Void) {
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


