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
    var emojiEmbeddings = getEmojiEmbeddings()
    
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
            
            let keywords = getKeywords(from: entryText, count: 8)
            let keywordsEmbeddings = self.bert.getKeywordsEmbeddings(keywords: keywords)
            let keywordsWithEmojis = self.getKeywordsWithEmojis(keywords, keywordsEmbeddings)
            let itemEmbedding = self.bert.getTextEmbedding(text: entryText)
            let itemContent = self.replaceWordsWithKeywords(entryText, keywords, keywordsWithEmojis)
            
            self.item.content = itemContent
            self.item.keywordsEmbeddings = keywordsEmbeddings
            self.item.keywords = keywordsWithEmojis
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
    
    func getKeywordsWithEmojis(_ keywords: [String], _ keywordsEmbeddings: [[Float]]) -> [String] {
        var keywordsWithEmojis: [String] = []
        for (index, keywordEmbedding) in keywordsEmbeddings.enumerated() {
            var scores: [(emoji: String, score: Float)] = []
            for (index, emojiEmbedding) in emojiEmbeddings.enumerated() {
                let score = SimilarityDistance(A: keywordEmbedding, B: emojiEmbedding)
                let emoji = getEmoji(index)
                scores.append((emoji: emoji, score: score))
            }
            scores = scores.sorted {$0.1 > $1.1}
            keywordsWithEmojis.append(scores[0].emoji + keywords[index])
            print("keyword: '\(keywords[index])', predicted emoji: \(scores[0].emoji), score: \(scores[0].score)")
        }
        return keywordsWithEmojis
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



