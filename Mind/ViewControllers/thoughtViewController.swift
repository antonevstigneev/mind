//
//  thoughtViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 31.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import NaturalLanguage
import Foundation

class thoughtViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    // MARK: - Data
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    // MARK: - Variables
    var thoughts: [Thought] = []
    var similarThoughts: [Thought] = []
    var selectedThought: Thought!
    var favoriteButton: UIBarButtonItem!
    var lockButton: UIBarButtonItem!
    var archiveButton: UIBarButtonItem!
    var moreButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    let iconConfig = UIImage.SymbolConfiguration(weight: .medium)
    var selectedKeyword: String = ""
    var selectedThoughtText: String = ""
    
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneButtonBC: NSLayoutConstraint!
    
    
    // MARK: - Actions
    @IBAction func doneButtonTouchDownInside(_ sender: UIButton) {
        sender.animate()
        
        // ⚠️ this should be one function
        closeEditMode()
        updateThoughtData()
    }

    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupViews()
        fetchData()
        showSimilarThoughts()
    }
    
    func setupViews() {
        showThoughtActionButtons()
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        tableView.isEditing = false
        
        // sendButton initial setup
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2.0
        doneButton.clipsToBounds = true
        doneButton.isEnabled = true
        doneButton.isHidden = false
        doneButton.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    
    @objc func updateThoughtData() {
        let entryText = getselectedThoughtText()
        
        let thoughtEditing = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: thoughtEditing) {
            let bert = BERT()
            let keywords = getKeywords(from: entryText, count: 10)
            let keywordsEmbeddings = bert.getKeywordsEmbeddings(keywords: keywords)
            let embedding = bert.getTextEmbedding(text: entryText)
            
            self.selectedThought.content = entryText
            self.selectedThought.keywords = keywords
            self.selectedThought.keywordsEmbeddings = keywordsEmbeddings
            self.selectedThought.embedding = embedding
        
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }
        }
        thoughtEditing.notify(queue: .main) {
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"),
            object: nil)
        }
    }
    
    
    func getselectedThoughtText() -> String {
        let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ThoughtTableViewCell
        let cellText = cell.thoughtContentTextView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cellText
    }

    
    func showThoughtActionButtons() {
        favoriteButton = UIBarButtonItem(image: UIImage(systemName: "star", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(favoriteAction(_:)))
        lockButton = UIBarButtonItem(image: UIImage(systemName: "lock", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(lockAction(_:)))
        archiveButton = UIBarButtonItem(image: UIImage(systemName: "archivebox", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(archiveAction(_:)))
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(moreAction(_:)))
        deleteButton = UIBarButtonItem(image: UIImage(systemName: "trash", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(deleteAction(_:)))
        deleteButton.tintColor = UIColor.systemRed
        
        favoriteButton.toggleStyle("star", self.selectedThought.favorited)
        lockButton.toggleStyle("lock", self.selectedThought.locked)
        archiveButton.toggleStyle("archivebox", self.selectedThought.archived)
        
        if selectedThought.archived {
            navigationItem.setRightBarButtonItems([deleteButton, archiveButton, lockButton, favoriteButton],
            animated: true)
        } else {
            navigationItem.setRightBarButtonItems([moreButton, archiveButton, lockButton, favoriteButton],
            animated: true)
        }
    }
    
    
    func showThoughtCloseButton() {
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(closeEditMode))
        navigationItem.setRightBarButtonItems([closeButton],
        animated: true)
    }
    
    // MARK: - Context menu
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
//            return self.createContextMenu(indexPath: indexPath)
//        }
//    }
    
    
    
    // ⚠️ (Duplicate) the same function in thoughtsViewController
    func createContextMenu(indexPath: IndexPath) -> UIMenu {
        let thought = self.similarThoughts[indexPath.row]
        var favoriteLabel: String!
        var favoriteImage: UIImage!
        var lockedImage: UIImage!
        var lockedLabel: String!
        var archivedLabel: String!
        
        if thought.favorited == true {
            favoriteLabel = "Unfavorite"
            favoriteImage = UIImage(systemName: "star.slash")
        } else {
            favoriteLabel = "Favorite"
            favoriteImage = UIImage(systemName: "star")
        }
        if thought.locked == true {
            lockedLabel = "Unlock"
            lockedImage = UIImage(systemName: "lock.slash")
        } else {
            lockedLabel = "Lock"
            lockedImage = UIImage(systemName: "lock")
        }
        if thought.archived == true {
            archivedLabel = "Unarchive"
        } else {
            archivedLabel = "Archive"
        }

        let favorite = UIAction(title: favoriteLabel, image: favoriteImage) { _ in
            self.favoriteThought(thought, indexPath)
        }
        let lock = UIAction(title: lockedLabel, image: lockedImage) { _ in
            self.lockThought(thought, indexPath)
        }
        let archive = UIAction(title: archivedLabel, image: UIImage(systemName: "archivebox")) { _ in
            self.archiveThought(thought, indexPath)
        }
        
        return UIMenu(title: "", children: [favorite, lock, archive])
    }
    
    
    func favoriteThought(_ thought: Thought, _ indexPath: IndexPath) {
        thought.toggleState(.favorited)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    
    func lockThought(_ thought: Thought, _ indexPath: IndexPath) {
        thought.toggleState(.locked)
        self.thoughts.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    
    func archiveThought(_ thought: Thought, _ indexPath: IndexPath) {
        thought.toggleState(.archived)
        self.thoughts.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    
    
    // MARK: - Selected Thought Actions
    @objc func favoriteAction(_ sender: UIBarButtonItem) {
        selectedThought.toggleState(.favorited)
        favoriteButton.toggleStyle("star", self.selectedThought.favorited)
    }

    
    @objc func lockAction(_ sender: UIBarButtonItem) {
        selectedThought.toggleState(.locked)
        lockButton.toggleStyle("lock", self.selectedThought.locked)
    }

    
    @objc func archiveAction(_ sender: UIBarButtonItem) {
        selectedThought.toggleState(.archived)
        archiveButton.toggleStyle("archivebox", self.selectedThought.archived)
    }
    

    @objc func deleteAction(_ sender: UIBarButtonItem) {
        let actionTitle = "Are you sure you want to remove this thought?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Remove", success: { () -> Void in
            self.selectedThought.remove()
            self.navigationController?.popViewController(animated: true)
        }) { () -> Void in
            print("Cancelled")
        }
    }
    
    
    @objc func moreAction(_ sender: UIBarButtonItem) {
        //
    }
     

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return similarThoughts.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedThoughtCell", for: indexPath) as! ThoughtTableViewCell
            
            let content = selectedThought.content!
            
            if selectedThought.keywords != nil {
                cell.thoughtContentTextView.highlightKeywords(originalText: content, keywords: selectedThought.keywords!, fontSize: 21, lineSpacing: 4.8)
            }
            
            cell.thoughtContentTextView.font = UIFont.systemFont(ofSize: 21)
            cell.thoughtContentTextView.textColor = UIColor(named: "title")
            
            cell.thoughtContentTextView.isEditable = true
            cell.thoughtContentTextView.isSelectable = true
            cell.thoughtContentTextView.isScrollEnabled = false
            cell.thoughtContentTextView.delegate = self
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ThoughtsTableViewCell
                    
            let thought = similarThoughts[indexPath.row]
            let content = thought.content!
        
            if selectedThought.keywords != nil {
                cell.thoughtContentText.highlightKeywords(originalText: content, keywords: thought.keywords!, fontSize: 16, lineSpacing: 3.0)
            }
            cell.thoughtContentText.font = UIFont.systemFont(ofSize: 16)
            cell.thoughtContentText.textColor = UIColor(named: "text")
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(keywordTapHandler(_:)))
            tap.delegate = self
            cell.thoughtContentText.addGestureRecognizer(tap)

            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            selectedThought = self.similarThoughts[indexPath.row]
            self.performSegue(withIdentifier: "toThoughtViewController", sender: (Any).self)
        }
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.selectedKeyword = "\(URL.absoluteString)"
        performKeywordSearch()
        return false
    }
    
        
    // Check for text limit
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        let indexPath = IndexPath(row: 0, section: 0)
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
//        let thoughtTextView = cell.thoughtContentTextView!
//
//        let newText = (thoughtTextView.text as NSString).replacingCharacters(in: range, with: text)
//        let numberOfChars = newText.count
//        if numberOfChars > 1499 {
//            let alert = UIAlertController(title: "Text is too long", message: "It's recommended to input text that is less than 1500 characters.", preferredStyle: .alert)
//
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//
//            self.present(alert, animated: true)
//        }
//        return numberOfChars < 1500
//    }
    
    
    // Check if textInput is empty
    func textViewDidChange(_ textView: UITextView) {
  
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedThoughtCell", for: indexPath) as! ThoughtTableViewCell
        
        let thoughtTextView = cell.thoughtContentTextView!
        
        if isTextInputNotEmpty(textView: thoughtTextView) {
            doneButton.show()
        } else {
            doneButton.hide()
        }
        
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        
        textView.frame = newFrame
        
        UIView.setAnimationsEnabled(false)
        /* These will causes table cell heights to be recaluclated,
         without reloading the entire cell */
        tableView.beginUpdates()
        tableView.endUpdates()
        // Re-enable animations
        UIView.setAnimationsEnabled(true)
    }
    
    
    func isTextInputNotEmpty(textView: UITextView) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showThoughtCloseButton()
        setEditThoughtTextStyle(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        setDefaultThoughtTextStyle(textView)
    }
    
    // ⚠️ (Duplicate) the same function in thoughtsViewController
    @objc func keywordTapHandler(_ sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager

        // location of tap in myTextView coordinates and taking the inset into account
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainerInset.left;
        location.y -= myTextView.textContainerInset.top;

        // character index at tap location
        let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

       // check if the tap location has a certain attribute
        let attributeName = NSAttributedString.Key.link
        let attributeValue = myTextView.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil)
        
        if let tappedKeyword = attributeValue {
            self.selectedKeyword = "\(tappedKeyword)"
            performKeywordSearch()
        }
    }
    
    
    // ⚠️ TODO: Not working, refactoring needed
    func performKeywordSearch() {
        guard let destinationVC = self.navigationController?.viewControllers[0] as? thoughtsViewController else {
            fatalError("Second VC in navigation stack is not an itemsViewController")
        }
        destinationVC.showThoughtsForSelectedKeyword(self.selectedKeyword)
        
        if let navController = self.navigationController {
            for controller in navController.viewControllers {
                if controller is thoughtsViewController {
                    navController.popToViewController(controller, animated: true)
                    NotificationCenter.default.post(name:
                    NSNotification.Name(rawValue: "thoughtKeywordClicked"),
                                                    object: nil)
                    break
                }
            }
        }
    }
    
    
    @objc func closeEditMode() {
        self.view.endEditing(true)
        doneButton.hide()
        showThoughtActionButtons()
    }
    
    
    func setDefaultThoughtTextStyle(_ textView: UITextView) {
        textView.highlightKeywords(originalText: textView.text!, keywords: self.selectedThought.keywords!, fontSize: 21, lineSpacing: 4.8)
        highlightHyperlinks(textView)
        textView.font = UIFont.systemFont(ofSize: 21.0)
        textView.textColor = UIColor(named: "title")
    }
    
    
    func setEditThoughtTextStyle(_ textView: UITextView) {
        unhighlightHyperlinks(textView)
        textView.font = UIFont.systemFont(ofSize: 21.0)
        textView.textColor = UIColor(named: "title")
    }
    
    
    func highlightHyperlinks(_ textView: UITextView) {
        UIView.transition(with: textView, duration: 0.35, options: .transitionCrossDissolve, animations: {
          textView.linkTextAttributes = [
              NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
              NSAttributedString.Key.underlineStyle: 0,
          ]
        }, completion: nil)
    }
    
    
    func unhighlightHyperlinks(_ textView: UITextView) {
        UIView.transition(with: textView, duration: 0.35, options: .transitionCrossDissolve, animations: {
          textView.linkTextAttributes = [
              NSAttributedString.Key.foregroundColor: UIColor(named: "title")!,
              NSAttributedString.Key.underlineStyle: 0,
          ]
        }, completion: nil)
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? thoughtViewController {
            destinationVC.selectedThought = self.selectedThought
            destinationVC.thoughts = self.thoughts
        }
    }
        
    
    // MARK: - Fetch thoughts data
    @objc func fetchData() {
        let request: NSFetchRequest = Thought.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            thoughts = try context.fetch(request)
            thoughts = thoughts.filter {
                $0.locked == false &&
                $0.archived == false
            }
        } catch {
            print("Fetching failed")
        }
    }
    
    
    @objc func showSimilarThoughts() {
        if selectedThought.locked || selectedThought.archived {
            similarThoughts = []
        } else {
            if selectedThought.embedding != nil {
                similarThoughts = getSimilarThoughts(thought: self.selectedThought, length: 10)
            }
        }
        if similarThoughts == [] {
            addPlaceholder()
        }
        DispatchQueue.main.async() {
            self.tableView.reloadData()
        }
    }
    
    func addPlaceholder() {
        // placeholder
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 21))
        label.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.midY - 35)
        label.textAlignment = .center
        label.textColor = UIColor(named: "text")
        label.text = "No similar thoughts found."
        self.view.addSubview(label)
    }
    
    
    // MARK: - Get similar thoughts
    func getSimilarThoughts(thought: Thought, length: Int) -> [Thought] {

        var similarThoughts: [(thought: Thought, score: Float)] = []
        let selectedThoughtEmbedding = self.selectedThought.embedding!
        
        for thought in self.thoughts {
            if thought.embedding != nil {
                if selectedThoughtEmbedding != thought.embedding! {
                    let distance = Distance.cosine(A: selectedThoughtEmbedding, B: thought.embedding!)
                    similarThoughts.append((thought: thought, score: distance))
                }
            }
        }
        
        similarThoughts = similarThoughts.sorted { $0.score > $1.score }
        
        return similarThoughts.map({ $0.thought }).slice(length: length)
    }
    
    
    func convertTimestamp(timestamp: Double) -> String {
        let x = timestamp / 1000
        let date = NSDate(timeIntervalSince1970: x)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter.string(from: date as Date)
    }
    
    
    // Handle keyboard appearence
    @objc private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
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


extension UIButton {

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        setBackgroundImage(colorImage, for: state)
    }
}


extension UIBarButtonItem {

    func toggleStyle(_ iconName: String, _ bool: Bool) {
        let iconConfig = UIImage.SymbolConfiguration(weight: .medium)
        if bool == true {
            self.image = UIImage(systemName: iconName + ".fill", withConfiguration: iconConfig)
        } else {
            self.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        }
    }
}


extension thoughtViewController {
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardShowNotification:)),
        name: UIResponder.keyboardDidShowNotification,
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardHideNotification:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)
    }
}
