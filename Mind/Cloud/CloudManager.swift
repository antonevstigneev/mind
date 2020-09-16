//
//  CloudManager.swift
//  Mind
//
//  Created by Anton Evstigneev on 14.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire

let sessionManager = Session()
let requestRetrier = NetworkRequestRetrier()

class Cloud {
    
    class var isUserAuthorized: Bool {
        return UserDefaults.standard.object(forKey: "isAuthorized") as! Bool
    }
    
    // for authorized request
    static let token = UserDefaults.standard.object(forKey: "privateKey") as! [UInt8]
    static let headers = ["Authorization": "Bearer \(token)"]
    
    static func processItemContent(content: String, completion: @escaping (ItemData?, Bool) -> Void) {
        
        let parameters: [String: Any] = [
            "content": content,
        ]
        
        let request = AF.request("http://3.130.38.239:8080/api/data", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        
        request.responseJSON {
            response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let itemData = try JSONDecoder().decode(ItemData.self, from: data)
                    completion(itemData, true)
                } catch {
                    completion(nil, false)
                }
            case .failure:
                print("❗️ERROR")
            }
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

        AF.request("http://3.130.38.239:8080/api/user", method: .post, parameters: parameters,encoding: JSONEncoding.default, headers: nil).responseData(completionHandler: {
            response in
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
        
        AF.request("http://3.130.38.239:8080/api/token", method: .post, parameters: parameters,encoding: JSONEncoding.default, headers: nil).responseJSON {
            response in
            
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
    
}


