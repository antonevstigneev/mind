//
//  itemViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 31.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import Foundation
import NaturalLanguage
import Firebase


class itemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    
    // MARK: - Data
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    // MARK: - Variables
    var items: [Item] = []
    var similarItems: [Item] = []
    var selectedItem: Item!
    var favoriteButton: UIBarButtonItem!
    var lockButton: UIBarButtonItem!
    var archiveButton: UIBarButtonItem!
    var moreButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    let iconConfig = UIImage.SymbolConfiguration(weight: .medium)
    var isItemChanged: Bool = false
    
    
    // MARK: - Outlets
    @IBOutlet weak var itemContentTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneButtonBC: NSLayoutConstraint!
    
    
    // MARK: - Actions
    @IBAction func plusButtonTouchUpInside(_ sender: Any) {
        plusButton.animateButtonUp()
        performSegue(withIdentifier: "addNewItem", sender: sender)
        Analytics.logEvent("plusButton_pressed", parameters: nil)
    }
    @IBAction func plusButtonTouchDown(_ sender: UIButton) {
        plusButton.animateButtonDown()
    }
    @IBAction func plusButtonTouchUpOutside(_ sender: UIButton) {
        plusButton.animateButtonUp()
    }
    @IBAction func doneButtonTouchDownInside(_ sender: Any) {
        updateItemData()
        self.isItemChanged = true
        closeEditMode()
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
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(updateItemView),
        name: NSNotification.Name(rawValue: "itemsChanged"),
        object: nil)
    }
    
    @objc func updateItemView() {
        itemContentTextView.addHyperLinksToText(originalText: self.selectedItem.content!, hyperLinks: self.selectedItem.keywords!, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
        itemContentTextView.textColor = UIColor(named: "itemViewText")
        UIView.transition(with: self.itemContentTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
          self.itemContentTextView.linkTextAttributes = [
              NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
              NSAttributedString.Key.underlineStyle: 0,
          ]
        }, completion: nil)
    }
    
    func setupViews() {
        showItemActionButtons()
        
        // itemView initial setup
        itemContentTextView.addHyperLinksToText(originalText: self.selectedItem.content!, hyperLinks: self.selectedItem.keywords!, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
        itemContentTextView.textColor = UIColor(named: "itemViewText")
        itemContentTextView.isScrollEnabled = false
        itemContentTextView.isEditable = true
        itemContentTextView.translatesAutoresizingMaskIntoConstraints = true
        itemContentTextView.sizeToFit()
        itemContentTextView.delegate = self
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.isEditing = false
        
        // plusButton initial setup
        plusButton.layer.masksToBounds = true
        plusButton.layer.cornerRadius = plusButton.frame.size.height / 2
        
        // sendButton initial setup
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2.0
        doneButton.clipsToBounds = true
        doneButton.isEnabled = true
        doneButton.isHidden = false
        doneButton.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    func updateItemData() {
        guard let entryText = itemContentTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        // clear keywords highlight, while item embeddings and keywords are recalculating
        itemContentTextView.clearTextStyles(originalText: entryText, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
        itemContentTextView.textColor = UIColor(named: "itemViewText")
        
        let itemEditing = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: itemEditing) {
            let bert = BERT()
            let keywords = getKeywords(from: entryText, count: 10)
            let keywordsEmbeddings = bert.getKeywordsEmbeddings(keywords: keywords)
            let itemEmbedding = bert.getTextEmbedding(text: entryText)
            
            self.selectedItem.content = entryText
            self.selectedItem.keywords = keywords
            self.selectedItem.keywordsEmbeddings = keywordsEmbeddings
            self.selectedItem.embedding = itemEmbedding
        
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
    
    
    // Check if textInput is empty
    func textViewDidChange(_ textView: UITextView) {
        if isTextInputNotEmpty(textView: itemContentTextView) {
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
    }
    
    func isTextInputNotEmpty(textView: UITextView) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
    
    func showItemActionButtons() {
        favoriteButton = UIBarButtonItem(image: UIImage(systemName: "star", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(favoriteItem))
        lockButton = UIBarButtonItem(image: UIImage(systemName: "lock", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(lockItem))
        archiveButton = UIBarButtonItem(image: UIImage(systemName: "archivebox", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(archiveItem))
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(shareItem))
        deleteButton = UIBarButtonItem(image: UIImage(systemName: "trash", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(deleteItem))
        deleteButton.tintColor = UIColor.systemRed
        
        favoriteButton.applyButtonIconStyle("star", self.selectedItem.favorited)
        lockButton.applyButtonIconStyle("lock", self.selectedItem.locked)
        archiveButton.applyButtonIconStyle("archivebox", self.selectedItem.archived)
        
        if selectedItem.archived {
            navigationItem.setRightBarButtonItems([deleteButton, archiveButton, lockButton, favoriteButton],
            animated: true)
        } else {
            navigationItem.setRightBarButtonItems([moreButton, archiveButton, lockButton, favoriteButton],
            animated: true)
        }
    }
    
    func showItemCloseButton() {
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: iconConfig), style: .plain, target: self, action: #selector(closeEditMode))
        navigationItem.setRightBarButtonItems([closeButton],
        animated: true)
    }
    
    
    // MARK: - Selected Item Actions
    @objc func favoriteItem() {
        if selectedItem.favorited == true {
            selectedItem.favorited = false
        } else {
            selectedItem.favorited = true
        }
        favoriteButton.applyButtonIconStyle("star", self.selectedItem.favorited)
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    @objc func lockItem() {
        if selectedItem.locked {
            self.selectedItem.locked = false
        } else {
            let actionMessage = "This will be hidded from all places but can be found in the Locked folder"
            postActionSheet(title: "", message: actionMessage, confirmation: "Lock", success: { () -> Void in
                self.selectedItem.locked = true
            }) { () -> Void in
                print("Cancelled")
            }
        }
        lockButton.applyButtonIconStyle("lock", self.selectedItem.locked)
        NotificationCenter.default.post(name:
        NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    @objc func archiveItem() {
        if selectedItem.archived {
            self.selectedItem.archived = false
        } else {
            let actionMessage = "This will be archived but can be found in the Archived folder"
            postActionSheet(title: "", message: actionMessage, confirmation: "Archive", success: { () -> Void in
                self.selectedItem.archived = true
            }) { () -> Void in
                print("Cancelled")
            }
        }
        archiveButton.applyButtonIconStyle("archivebox", self.selectedItem.archived)
        navigationController?.popViewController(animated: true) // go back to previous viewController
        NotificationCenter.default.post(name:
        NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    @objc func deleteItem() {
        let actionTitle = "Are you sure you want to delete this?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Delete", success: { () -> Void in
            self.context.delete(self.selectedItem)
            self.navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name:
                NSNotification.Name(rawValue: "itemsChanged"), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }) { () -> Void in
            print("Cancelled")
        }
    }
    
    @objc func shareItem() {
        //
    }
    
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = UIColor(named: "background")
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(named: "content")
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return similarItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell
                
        let item = similarItems[indexPath.row]
        let content = item.content!
        
        cell.itemContentText.addHyperLinksToText(originalText: content, hyperLinks: item.keywords!, fontSize: 16, fontWeight: .regular, lineSpacing: 3.0)
        cell.itemContentText.textColor = UIColor(named: "content")!
        
        if item.favorited {
            cell.favoritedButton.isHidden = false
            cell.itemContentTextRC.constant = 35
            
        } else {
            cell.favoritedButton.isHidden = true
            cell.itemContentTextRC.constant = 16
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(keywordTapHandler(_:)))
        tap.delegate = self
        cell.itemContentText.addGestureRecognizer(tap)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(self.similarItems[indexPath.row].content!)
        selectedItem = self.similarItems[indexPath.row]
        self.performSegue(withIdentifier: "toItemViewController", sender: (Any).self)
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
        if let value = attributeValue {
            print("You tapped on keyword and the value is: \(value)")
        }
    }
    
    @objc func closeEditMode() {
        if isItemChanged == false {
            itemContentTextView.text = selectedItem.content!
            itemContentTextView.addHyperLinksToText(originalText: self.selectedItem.content!, hyperLinks: self.selectedItem.keywords!, fontSize: 21, fontWeight: .regular, lineSpacing: 4.8)
            itemContentTextView.textColor = UIColor(named: "itemViewText")
        }
        tableView.show()
        doneButton.hide()
        plusButton.show()
        showItemActionButtons()
        UIView.transition(with: self.itemContentTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
          self.itemContentTextView.linkTextAttributes = [
              NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
              NSAttributedString.Key.underlineStyle: 0,
          ]
        }, completion: nil)
        itemContentTextView.resignFirstResponder()
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? itemViewController {
            destinationVC.selectedItem = self.selectedItem
            destinationVC.items = self.items
        }
    }
        
    
    // MARK: - Fetch items data
    @objc func fetchData() {
        if selectedItem.locked || selectedItem.archived {
            similarItems = []
            tableView.isHidden = true
        } else {
            similarItems = getSimilarItems(item: self.selectedItem)
        }
        
        DispatchQueue.main.async() {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Get similar items
    func getSimilarItems(item: Item) -> [Item] {
        
        var selectedItemEmbedding: [Float] = []
        var similarItems: [Item] = []
        var scores: [Float] = []
        var topSimilarItems: [Item] = []
        
        selectedItemEmbedding = self.selectedItem.embedding!
        
        for item in self.items {
            if selectedItemEmbedding != item.embedding! {
                let distance = Distance.cosine(A: selectedItemEmbedding, B: item.embedding!)
                similarItems.append(item)
                scores.append(distance)
            }
        }
        
        let sortedSimilarItems = sortSimilarItemsByScore(similarItems, scores)
        
        if sortedSimilarItems.count > 5 {
            for i in 1...6 {
                topSimilarItems.append(sortedSimilarItems[i])
            }
        } else if sortedSimilarItems.count < 5 {
            for i in 1...sortedSimilarItems.count-1 {
                topSimilarItems.append(sortedSimilarItems[i])
            }
        } else {
            topSimilarItems = []
        }
        
        return sortedSimilarItems
    }
    
    
    func sortSimilarItemsByScore(_ items: [Item], _ scores: [Float]) -> [Item] {
        let sortedResults = zip(items, scores).sorted {$0.1 > $1.1}
        return sortedResults.map {$0.0}
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
            tableView.hide()
            showItemCloseButton()
            UIView.transition(with: self.itemContentTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
              self.itemContentTextView.linkTextAttributes = [
                  NSAttributedString.Key.foregroundColor: UIColor(named: "itemViewText")!,
                  NSAttributedString.Key.underlineStyle: 0,
              ]
            }, completion: nil)
            doneButtonBC.constant = keyboardFrame.height + 18
        }
    }

    @objc private func handle(keyboardHideNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            showItemActionButtons()
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


extension UIView {
    
    enum SeparatorPosition {
        case top
        case bottom
        case left
        case right
    }

    @discardableResult
    func addSeparator(at position: SeparatorPosition, color: UIColor, weight: CGFloat = 1.0 / UIScreen.main.scale, insets: UIEdgeInsets = .zero) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        switch position {
        case .top:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom:
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .left:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
        }
        
        return view
    }
    
}


extension UIBarButtonItem {

    func applyButtonIconStyle(_ iconName: String, _ bool: Bool) {
        let iconConfig = UIImage.SymbolConfiguration(weight: .medium)
        if bool == true {
            self.image = UIImage(systemName: iconName + ".fill", withConfiguration: iconConfig)
        } else {
            self.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        }
    }
}
