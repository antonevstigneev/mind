//
//  thoughtVC.swift
//  Mind
//
//  Created by Anton Evstigneev on 31.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import Alamofire

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
    @IBAction func doneButtonTouchDownInside(_ sender: Any) {
        closeEditMode()
        updateThoughtData()
    }
    @IBAction func editButtonTouchDown(_ sender: UIButton) {
        doneButton.animateButtonDown()
    }
    @IBAction func editButtonTouchUpOutside(_ sender: UIButton) {
        doneButton.animateButtonUp()
    }
    
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupViews()
        fetchData()
        showSimilarThoughts()
    }
    
    
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
    
    
    func setupViews() {
        showThoughtActionButtons()
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.isEditing = false
        
        // sendButton initial setup
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2.0
        doneButton.clipsToBounds = true
        doneButton.isEnabled = true
        doneButton.isHidden = false
        doneButton.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    
    func updateThoughtData() {
        let entryText = getselectedThoughtText()
        
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"),
            object: nil)
        }
        
        let thoughtUpdate = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: thoughtUpdate) {
            
            if MindCloud.isUserAuthorized == false {
                MindCloud.processThought(content: entryText) {
                    (responseData, success) in
                    if (success) {
                        print("✅ Server processed thought data successfully.")
                        DispatchQueue.main.async {
                            self.selectedThought.content = entryText
                            self.selectedThought.keywords = responseData?.keywords
                            self.selectedThought.keywordsEmbeddings = responseData?.keywordsEmbeddings
                            self.selectedThought.embedding = responseData?.embedding
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                        }
                    } else {
                        print("⚠️ Error occurred while processing thought data")
                    }
                }
            } else {
                MindCloud.updateThought(id: self.selectedThought.id!, upd: ["content": entryText]) {
                    (responseData, success) in
                    if (success) {
                        print("✅ 🔐 Authorized patch thought successfully.")
                        DispatchQueue.main.async {
                            self.selectedThought.keywords = responseData?.keywords
                            self.selectedThought.keywordsEmbeddings = responseData?.keywordsEmbeddings
                            self.selectedThought.embedding = responseData?.embedding
    //                        self.selectedThought.timestamp = responseData?.timestamp! as! Int64
                            self.selectedThought.id = responseData?.id
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                        }
                    } else {
                        print("⚠️ Error occurred while processing thought data")
                    }
                }
            }
        }
        
        thoughtUpdate.notify(queue: .main) {
            NotificationCenter.default.post(name:
                NSNotification.Name(rawValue: "thoughtsLoaded"),
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
        let actionTitle = "Are you sure you want to delete this?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Delete", success: { () -> Void in
            self.selectedThought.delete()
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
            cell.thoughtContentTextView.clearTextStyles(originalText: content, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
//            cell.thoughtContentTextView.addHyperLinksToText(originalText: selectedThought.content!, hyperLinks: selectedThought.keywords!, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
            cell.thoughtContentTextView.textColor = UIColor(named: "title")
            
            cell.thoughtContentTextView.isEditable = true
            cell.thoughtContentTextView.isSelectable = true
            cell.thoughtContentTextView.isScrollEnabled = false
            cell.thoughtContentTextView.translatesAutoresizingMaskIntoConstraints = true
            cell.thoughtContentTextView.sizeToFit()
            cell.thoughtContentTextView.delegate = self
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ThoughtsTableViewCell
                    
            let thought = similarThoughts[indexPath.row]
            let content = thought.content!
            
            cell.thoughtContentText.clearTextStyles(originalText: content, fontSize: 16, fontWeight: .regular, lineSpacing: 3.0)
//            cell.thoughtContentText.addHyperLinksToText(originalText: content, hyperLinks: thought.keywords!, fontSize: 16, fontWeight: .regular, lineSpacing: 3.0)
            cell.thoughtContentText.textColor = UIColor(named: "text")
            
            if thought.favorited {
                cell.favoritedButton.isHidden = false
                cell.thoughtContentTextRC.constant = 35
                
            } else {
                cell.favoritedButton.isHidden = true
                cell.thoughtContentTextRC.constant = 16
            }
            
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
        
        if let clickedKeyword = attributeValue {
            self.selectedKeyword = "\(clickedKeyword)"
            performKeywordSearch()
        }
    }
    
    
    func performKeywordSearch() {
        guard let destinationVC = self.navigationController?.viewControllers[0] as? thoughtsViewController else {
            fatalError("Second VC in navigation stack is not an itemsViewController")
        }
        destinationVC.selectedKeyword = self.selectedKeyword
        
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
//        textView.text = self.selectedThought.content!
        textView.addHyperLinksToText(originalText: textView.text!, hyperLinks: self.selectedThought.keywords!, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
        textView.textColor = UIColor(named: "title")
        highlightHyperlinks(textView)
    }
    
    
    func setEditThoughtTextStyle(_ textView: UITextView) {
//        textView.text = self.selectedThought.content!
        textView.clearTextStyles(originalText: textView.text, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
        textView.textColor = UIColor(named: "title")
        unhighlightHyperlinks(textView)
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
            self.showSpinner()
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        } else {
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        }
        DispatchQueue.main.async() {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Get similar thoughts
    func getSimilarThoughts(thought: Thought, length: Int) -> [Thought] {

        var similarThoughts: [(thought: Thought, score: Double)] = []
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
