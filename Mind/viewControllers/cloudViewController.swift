//
//  cloudViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 13.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CryptoSwift
import SwiftyRSA
import Alamofire

class cloudViewController: UIViewController, UITextFieldDelegate {
    
    let isAuthorized = UserDefaults.standard.object(forKey: "isAuthorized") as! Bool
    
    // MARK: - Outlets
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var accountCredentialsView: UIView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var authorizedView: UIView!
    @IBOutlet weak var logoutButton: UIButton!

    
    // MARK: - Actions
    @IBAction func createAccountAction(_ sender: Any) {
        accountCredentialsView.isHidden = false
        submitButton.setTitle("Create Account", for: .normal)
    }
    
    @IBAction func loginAction(_ sender: Any) {
        accountCredentialsView.isHidden = false
        submitButton.setTitle("Log In", for: .normal)
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        setupAuthorizationView()
        UserDefaults.standard.set(false, forKey: "isAuthorized")
    }
    
    @IBAction func submitAction(_ sender: Any) {
        let email = emailField.text!
        let password = passwordField.text!
        
        if submitButton.currentTitle == "Create Account" {
            do {
                let keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: 1024)
                let privateKey = keyPair.privateKey
                let publicKey = keyPair.publicKey
                let UInt8PublicKey: [UInt8] = Array(try publicKey.pemString().utf8)
                let UInt8PrivateKey: [UInt8] = Array(try privateKey.pemString().utf8)
                UserDefaults.standard.set(UInt8PrivateKey, forKey: "privateKey") // save privateKey on device
                print(UserDefaults.standard.object(forKey: "privateKey") as! [UInt8])
                let encryptedPrivateKey = encryptPrivateKey(email: email, password: password, privateKey: UInt8PrivateKey)
                CloudManager().createAccout(email: email, password: password, publicKey: UInt8PublicKey.data.hexa, encryptedPrivateKey: encryptedPrivateKey!.encryptedPrivateKey.data.hexa, iv: encryptedPrivateKey!.iv.data.hexa)
                
            } catch {
                print("Error")
            }
        } else {
            self.showSpinner()
            print("Authorizing...")
            CloudManager().getAuthorizationToken(email: email, password: password) { (token, success) in
                if (success) {
                    self.removeSpinner()
                    self.setupAuthorizedView()
                    print("Success!")
                } else {
                    print("Error")
                }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if isAuthorized == false {
            setupAuthorizationView()
        } else {
            setupAuthorizedView()
        }
    }
    
    
    func setupAuthorizationView() {
        emailField.delegate = self
        passwordField.delegate = self
        createAccountButton.layer.masksToBounds = true
        createAccountButton.layer.cornerRadius = 6
        loginButton.layer.masksToBounds = true
        loginButton.layer.cornerRadius = 6
        submitButton.layer.masksToBounds = true
        submitButton.layer.cornerRadius = 6
        accountCredentialsView.isHidden = true
        authorizedView.isHidden = true
    }
    
    
    func setupAuthorizedView() {
        authorizedView.isHidden = false
        accountCredentialsView.isHidden = true
        logoutButton.layer.masksToBounds = true
        logoutButton.layer.cornerRadius = 6
    }
    
    
    func validateEmail(enteredEmail: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    
    func encryptPrivateKey(email: String, password: String, privateKey: [UInt8]) -> (iv: [UInt8], encryptedPrivateKey: [UInt8])? {
        let key: [UInt8] = (email+password).bytes.sha256()
        let iv: [UInt8]? = generateRandomBytes(count: 16)

        do {
            let aes = try AES(key: key, blockMode: CBC(iv: iv!), padding: .pkcs7)
            return (iv: iv!, encryptedPrivateKey: try aes.encrypt(privateKey))
       } catch {
            print("Decryption error: \(error) \(iv!.count) \(key.count)")
            return nil
       }
    }
    
    
    func generateRandomBytes(count: Int) -> Array<UInt8>? {

        var keyData = Data(count: count)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData.bytes
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    
    func getRandomIV(length: Int) -> String {
        let letters = "0123456789ABCDEF"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    

}


extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        return (0..<count/2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            return UInt8(self[startIndex...endIndex], radix: 16)
        }
    }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}
