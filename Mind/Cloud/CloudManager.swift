//
//  CloudManager.swift
//  Mind
//
//  Created by Anton Evstigneev on 14.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire

class CloudManager {

    func processItemContent(content: String, completion: @escaping ([String: Any]?, Bool) -> Void) {
        let parameters: [String: Any] = [
            "content": content,
        ]

        AF.request("http://3.130.38.239:8080/api/data", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON {
            response in
            switch response.result {
                case .success:
                    let itemData = response.value as! [String: Any]
                    completion(itemData, true)
                    break
                case .failure(let error):
                    print(error)
                    completion([:], false)
            }
        }
    }
    
    func createAccout(email: String, password: String, publicKey: String, encryptedPrivateKey: String, iv: String) {
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
    
    func getAuthorizationToken(email: String, password: String, completion: @escaping (String, Bool) -> Void) {
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


