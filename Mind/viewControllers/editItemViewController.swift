//
//  editItemViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 25.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class editItemViewController: UIViewController, UITextViewDelegate {
    
    let bert = BERT()
    
    var item: Item!
    
    // Outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textInputView: UITextView!
    
    // Constraints
    @IBOutlet weak var doneButtonBC: NSLayoutConstraint!
    @IBOutlet weak var textInputViewBC: NSLayoutConstraint!
    
    // Actions
    @IBAction func doneButtonTouchDownInside(_ sender: Any) {
        updateItemData()
        performSegue(withIdentifier: "unwindToHome", sender: self)
    }
    @IBAction func editButtonTouchDown(_ sender: UIButton) {
        sender.animateButtonDown()
    }
    @IBAction func editButtonTouchUpOutside(_ sender: UIButton) {
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
        
        var itemContentText = item.content!.components(separatedBy: CharacterSet.symbols).joined()
        itemContentText = itemContentText.replacingOccurrences(of: "  ", with: " ")
        itemContentText = itemContentText.replacingOccurrences(of: "\u{2139}", with: "")
//        let emojis: Array<Character> = emojiDict.flatMap { $0.emoji }
//        itemContentText.removeAll(where: { emojis.contains($0) })
    
        // textInput initial setup
        textInputView.delegate = self
        textInputView.text = itemContentText
        textInputView.tintColor = UIColor(named: "content")

        // sendButton initial setup
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2.0
        doneButton.clipsToBounds = true
        doneButton.isEnabled = true
        doneButton.isHidden = false
        doneButton.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
 
    
    func updateItemData() {
        guard let entryText = textInputView?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        
        let itemEditing = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: itemEditing) {
            
            let keywords = getKeywords(from: entryText, count: 7)
            let keywordsEmbeddings = self.bert.getKeywordsEmbeddings(keywords: keywords)
            let keywordsWithEmojis = getKeywordsWithEmojis(keywords, keywordsEmbeddings)
            let itemEmbedding = self.bert.getTextEmbedding(text: entryText)
            let itemContent = self.replaceWordsWithKeywords(entryText, keywords, keywordsWithEmojis)
            
            self.item.content = itemContent
            self.item.keywords = keywordsWithEmojis
            self.item.keywordsEmbeddings = keywordsEmbeddings
            self.item.embedding = itemEmbedding
        
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }
        }
        itemEditing.notify(queue: .main) {
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "itemsChanged"),
            object: nil)
        }
    }
    
    func replaceWordsWithKeywords(_ text: String, _ words: [String], _ keywords: [String]) -> String {
        var replacedText = text
        for (index, word) in words.enumerated() {
            replacedText = replacedText.replacingOccurrences(of: word, with: keywords[index])
        }

        return replacedText
    }
    
    // Check if textInput is empty
    func textViewDidChange(_ textView: UITextView) {
        if isTextInputNotEmpty(textView: textInputView) {
            doneButton.show()
        } else {
            doneButton.hide()
        }
    }
    
    func isTextInputNotEmpty(textView: UITextView) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
    
    
    // Handle keyboard appearence
        @objc private func handle(keyboardShowNotification notification: Notification) {
            if let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                textInputViewBC.constant = keyboardFrame.height + 60
                doneButtonBC.constant = keyboardFrame.height + 18
            }
        }
    
        @objc private func handle(keyboardHideNotification notification: Notification) {
            if let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                doneButtonBC.constant = -keyboardFrame.height - 18
            }
        }
}



