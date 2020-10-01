//
//  newThoughtViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 24.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import NaturalLanguage
import Alamofire


class newThoughtViewController: UIViewController, UITextViewDelegate {
    
    // Reference to NSPersistent Container context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Outlets
    @IBOutlet weak var textInputView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    // Constraints
    @IBOutlet weak var textInputViewBC: NSLayoutConstraint!
    @IBOutlet weak var sendButtonBC: NSLayoutConstraint!
    
    // Actions
    @IBAction func sendButtonTouchDownInside(_ sender: Any) {
        saveNewThought()
        emptyDraftData()
    }
    @IBAction func sendButtonTouchDown(_ sender: UIButton) {
        sender.animateButtonDown()
    }
    @IBAction func sendButtonTouchUpOutside(_ sender: UIButton) {
        sender.animateButtonUp()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        textInputView.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardShowNotification:)),
        name: UIResponder.keyboardDidShowNotification,
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardHideNotification:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)
    
        // textInput initial setup
        textInputView.text = UserDefaults.standard.value(forKey: "Draft") as? String
        textInputView.delegate = self
        textInputView.tintColor = UIColor(named: "text")
        
        // sendButton initial setup
        sendButton.layer.cornerRadius = sendButton.frame.size.height / 2.0
        sendButton.clipsToBounds = true
        if isTextInputNotEmpty(textView: textInputView) {
            sendButton.show()
        } else {
            sendButton.hide()
        }
    }
    
    
    // This function is called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! thoughtsViewController
        let indexPath = IndexPath(row: 0, section: 0)
        if destinationVC.thoughts.isEmpty == false {
            destinationVC.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    
    @objc func saveNewThought() {
        guard let entryText = textInputView?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        
        let newThought = Thought(context: self.context)
        newThought.content = entryText
        let timestamp = Date().current()
        
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"),
            object: nil)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if MindCloud.isUserAuthorized == false {
                MindCloud.processThought(content: entryText) {
                    (responseData, success) in
                    if (success) {
                        print("✅ Server processed thought data successfully.")
                        DispatchQueue.main.async {
                            newThought.keywords = responseData?.keywords
                            newThought.keywordsEmbeddings = responseData?.keywordsEmbeddings
                            newThought.embedding = responseData?.embedding
                            newThought.timestamp = Date().current()
                            print(responseData as Any)
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                        }
                    } else {
                        print("⚠️ Error occurred while processing thought data")
                    }
                }
            } else {
                MindCloud.postThought(content: entryText, timestamp: timestamp) {
                    (responseData, success) in
                    if (success) {
                        print("✅ 🔐 Authorized post thought successfully.")
                        DispatchQueue.main.async {
                            newThought.keywords = responseData?.keywords
                            newThought.keywordsEmbeddings = responseData?.keywordsEmbeddings
                            newThought.embedding = responseData?.embedding
                            newThought.timestamp = timestamp
                            newThought.id = responseData?.id
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                        }
                    } else {
                        print("⚠️ Error occurred while processing thought data")
                    }
                }
            }
        }
    }
    
    
    // Handle keyboard appearence
    @objc private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            textInputViewBC.constant = keyboardFrame.height + 60
            sendButtonBC.constant = keyboardFrame.height + 18
        }
    }

    @objc private func handle(keyboardHideNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            sendButtonBC.constant = -keyboardFrame.height - 18
        }
    }

    // Check for text limit
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textInputView!.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        if numberOfChars > 1499 {
            let alert = UIAlertController(title: "Text is too long",
                                          message: "It's recommended to input text that is less than 1500 characters.",
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

            self.present(alert, animated: true)
        }
        return numberOfChars < 1500
    }


    func textViewDidChange(_ textView: UITextView) {
        if isTextInputNotEmpty(textView: textInputView) {
            UserDefaults.standard.set(textInputView!.text, forKey: "Draft")
            UserDefaults.standard.synchronize()
            sendButton.show()
        } else {
            UserDefaults.standard.set("", forKey: "Draft")
            UserDefaults.standard.synchronize()
            sendButton.hide()
        }
    }
    
    
    func isTextInputNotEmpty(textView: UITextView) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
    
    
    func emptyDraftData() {
        UserDefaults.standard.set("", forKey: "Draft")
        UserDefaults.standard.synchronize()
    }
    
    func removeShortWords(_ word: String) -> Bool {
        return word.count > 2
    }
    
}





