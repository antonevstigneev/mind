//
//  itemsViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 06.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import CoreML
import Foundation
import NaturalLanguage


class itemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate {
    
    // MARK: - Model
    let bert = BERT()
    
    
    // MARK: - Data
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    // MARK: - Variables
    var items: [Item] = []
    var item: Item!
    var keywordsCollection: [String] = []
    var mostFrequentKeywords: [String] = []
    let selectedAllKeyword = (title: "all", path: 0)
    var selectedKeyword: (title: String, path: Int)? = nil
    
    
    // MARK: - Outlets
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var keywordsCollectionView: UICollectionView!
    @IBOutlet weak var tableViewBC: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    
    
    // MARK: - Actions
    @IBAction func plusButtonTouchDownInside(_ sender: Any) {
        plusButton.animateButtonUp()
        performSegue(withIdentifier: "toAddItemViewController", sender: sender)
    }
    @IBAction func plusButtonTouchDown(_ sender: UIButton) {
        plusButton.animateButtonDown()
    }
    @IBAction func plusButtonTouchUpOutside(_ sender: UIButton) {
        plusButton.animateButtonUp()
    }
    
    @IBAction func keywordButtonTouchUpInside(_ sender: UIButton) {
        let keywordTitle = sender.titleLabel!.text!
        selectedKeyword = (title: keywordTitle, path: 1)
        keywordsCollection = [self.selectedAllKeyword.title]
        keywordsCollection.append(self.selectedKeyword!.title)
        keywordsCollectionView.reloadData()
        fetchDataForSelectedKeyword()
    }
    
    @IBAction func keywordsCollectionViewTouchUpInside(_ sender: UIButton) {
        let keywordTitle = sender.titleLabel!.text!
        let keywordPath = keywordsCollection.firstIndex(of: keywordTitle)!
        let pressedKeyword = (title: keywordTitle, path: keywordPath)
        
        if pressedKeyword.title != "all" {
            sender.isSelected = true
            selectedKeyword = (title: keywordTitle, path: keywordPath)
            fetchDataForSelectedKeyword()
            keywordsCollectionView.reloadData()
        } else if pressedKeyword.title == "all" {
            sender.isSelected = true
            selectedKeyword = selectedAllKeyword
            keywordsCollectionView.reloadData()
            
            if !searchBar.text!.isEmpty {
                fetchData()
                items = self.getSimilarItems(text: searchBar.text!)
                tableView.reloadData()
            } else {
                fetchData()
            }
        
        } else {
            sender.isSelected = false
            keywordsCollectionView.reloadData()
            reloadSearch()
        }
        self.animateTableView()
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        fetchData()
        tableView.reloadData()
    }
    
    // Timer
    var timer: Timer?

    let formatter: DateFormatter = {
        let tmpFormatter = DateFormatter()
        tmpFormatter.dateFormat = "HH:mm"
        return tmpFormatter
    }()
    
    
    var refreshControl: UIRefreshControl!
    
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 30,
                target: self,
                selector: #selector(self.getTimeOfDate),
                userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(defaultKeywordsCollectionView),
        name: NSNotification.Name(rawValue: "allItemsLoaded"),
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(fetchData),
        name: NSNotification.Name(rawValue: "newItemCreated"),
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardShowNotification:)),
        name: UIResponder.keyboardDidShowNotification,
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(handle(keyboardHideNotification:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)
        
        // time initial setup
        timeLabel.text = formatter.string(from: Date())
        
        // searchBar initial setup
        searchBar.delegate = self
        UISearchBar.appearance().setSearchFieldBackgroundImage(UIImage(), for: .normal)
        
        // keywords collection initial setup
        keywordsCollectionView.delegate = self
        keywordsCollectionView.dataSource = self
        defaultKeywordsCollectionView()
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        // plusButton initial setup
        plusButton.layer.masksToBounds = true
        plusButton.layer.cornerRadius = plusButton.frame.size.height / 2
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(view.endEditing))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        setupSearchBar(searchBar: searchBar)
    }

    func setupSearchBar(searchBar : UISearchBar) {
        searchBar.setPlaceholderTextColorTo(color: UIColor(named: "content2")!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
        if items.count == 0 {
            keywordsCollectionView.isHidden = true
            addPlaceholderLabel()
        } else {
            keywordsCollectionView.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    @objc func refreshTableView(_ sender: Any) {
        fetchData()
        searchBar.text = ""
        refreshControl.endRefreshing()
    }

    
    // MARK: - Context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            return self.createContextMenu(indexPath: indexPath)
        }
    }
    
    func createContextMenu(indexPath: IndexPath) -> UIMenu {
       let similar = UIAction(title: "Similar", image: UIImage.circles(diameter: 50, color: UIColor(named: "buttonBackground")!)) { _ in
            self.item = self.items[indexPath.row]
            self.findSimilarItems(for: self.item)
       }
       let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            self.copyItemContent(indexPath: indexPath)
            self.item = self.items[indexPath.row]
       }
       let edit = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { _ in
            self.item = self.items[indexPath.row]
            self.performSegue(withIdentifier: "toEditItemViewController", sender: (Any).self)
       }
       let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive) { _ in
            self.deleteItem(indexPath: indexPath)
       }

       return UIMenu(title: "", children: [similar, copy, edit, delete])
    }
    
    func copyItemContent(indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        let content = item.content
        let pasteboard = UIPasteboard.general
        pasteboard.string = content
    }
    
    func deleteItem(indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Are you sure you want to delete this?", message: nil, preferredStyle: .alert)
        alertController.view.tintColor = UIColor.lightGray;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action:UIAlertAction) in
            let item = self.items[indexPath.row]
            self.context.delete(item)
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Items Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell

        let item = items[indexPath.row]
        
        let content = item.value(forKey: "content") as! String
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        let regularAttributes: [NSAttributedString.Key : Any] = [.font : UIFont.FiraMono(.regular, size: 16), .paragraphStyle : paragraphStyle, .foregroundColor: UIColor(named: "content")! ]
        let mutableString = NSMutableAttributedString(string: content, attributes: regularAttributes)
        
        cell.itemContentText.attributedText = mutableString
    
        cell.itemContentText.textContainerInset = UIEdgeInsets(top: 10, left: 6, bottom: 11, right: 6)
        
//        cell.itemTimestampLabel?.text = convertTimestamp(timestamp: item.value(forKey: "timestamp") as! Double)

        cell.itemContentText.linkTextAttributes = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        
        cell.itemKeywordsCollectionView.tag = indexPath.row

        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let tableViewCell = cell as? ItemsCell else { return }

        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? editItemViewController {
            destinationVC.item = self.item
        }
    }
    
    
    // MARK: - Fetch items data
    @objc func fetchData() {
       
       let request: NSFetchRequest = Item.fetchRequest()
       let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
       request.sortDescriptors = [sortDescriptor]
        do {
            items = try context.fetch(request)
            let itemsLoading = DispatchGroup()
            DispatchQueue.main.async(group: itemsLoading) {
                self.tableView.reloadData()
                self.keywordsCollectionView.reloadData()
            }
            itemsLoading.notify(queue: .main) {
                NotificationCenter.default.post(name:
                NSNotification.Name(rawValue: "allItemsLoaded"),
                object: nil)
            }
        } catch {
            print("Fetching failed")
        }
    }
    
    @objc func fetchDataForSelectedKeyword() {
        let request: NSFetchRequest = Item.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
         do {
            self.showSpinner()
            var itemsWithSelectedKeyword: [Item] = []
             items = try context.fetch(request)
             for item in items {
                if item.keywords!.contains(selectedKeyword!.title) {
                    itemsWithSelectedKeyword.append(item)
                }
             }
             DispatchQueue.main.async {
                self.items = itemsWithSelectedKeyword
                self.animateTableView()
                self.tableView.reloadData()
                self.removeSpinner()
             }
         } catch {
             print("Fetching failed")
         }
    }
    

    // MARK: - Get similar items
    func getSimilarItems(item: Item? = nil, text: String = "") -> [Item] {
        
        var selectedItemEmbedding: [Float] = []
        var similarItems: [Item] = []
        var scores: [Float] = []
        
        if text != "" {
            selectedItemEmbedding = self.bert.getTextEmbedding(text: text)
        } else {
            selectedItemEmbedding = item!.embedding!
        }
        
        for item in items {
            let distance = SimilarityDistance(A: selectedItemEmbedding, B: item.embedding!)
            similarItems.append(item)
            scores.append(distance)
        }
        
        let sortedSimilarItems = sortSimilarItemsByScore(similarItems, scores)
        
        var topSimilarItems: [Item] = []
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

        return topSimilarItems
    }
    
    
    func sortSimilarItemsByScore(_ items: [Item], _ scores: [Float]) -> [Item] {
        let sortedResults = zip(items, scores).sorted {$0.1 > $1.1}
        return sortedResults.map {$0.0}
    }
    
    
    // MARK: - Search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(itemsViewController.reloadSearch), object: nil)
            self.perform(#selector(itemsViewController.reloadSearch), with: nil, afterDelay: 1.0)
        } else {
            fetchData()
            defaultKeywordsCollectionView()
        }
    }
    
    @objc func reloadSearch() {
        guard let searchText = searchBar.text else { return }
        
        if !searchText.isEmpty {
            performSimilaritySearch(searchText)
        } else {
            fetchData()
        }
    }

    func performSimilaritySearch(_ searchText: String) {
        
        var similarItems: [Item] = []
        var suggestedKeywords: [String] = []
        
        self.showSpinner()
        DispatchQueue.global(qos: .userInitiated).async {
            
            similarItems = self.getSimilarItems(text: searchText)
            suggestedKeywords = self.getSuggestedKeywords(similarItems)
            
            DispatchQueue.main.async {

                self.showSuggestedKeywords(suggestedKeywords)
                self.items = similarItems
                self.tableView.reloadData()
                self.animateTableView()
                self.removeSpinner()
            }
        }
    }
    
    
    func findSimilarItems(for item: Item!) {
        searchBar.text = item.content!
        reloadSearch()
    }
    
    
    func animateTableView() {
        if self.items.isEmpty == false {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        self.tableView.alpha = 0
        UIView.animate(withDuration: 0.35, delay: 0.05, options: [.curveEaseInOut], animations: {
            self.tableView.alpha = 1
        }, completion: nil)
    }
    
    func getSuggestedKeywords(_ similarItems: [Item]) -> [String] {
        var suggestedKeywords: [String] = []
        
        if similarItems != [] {
            for item in similarItems {
                suggestedKeywords.append(contentsOf: item.keywords!)
            }
            return suggestedKeywords
            
        } else { return [] }
    }
    
    func showSuggestedKeywords(_ suggestedKeywords: [String]) {
        keywordsCollection = [self.selectedAllKeyword.title]
        keywordsCollection.append(self.selectedKeyword!.title)
        keywordsCollection.append(contentsOf: suggestedKeywords)
        keywordsCollection = self.keywordsCollection.removeDuplicates()
        
        if keywordsCollection.contains(searchBar.text!.lowercased()) {
            keywordsCollection.remove(at:
            keywordsCollection.firstIndex(of: self.searchBar.text!.lowercased())!)
            keywordsCollection.insert(searchBar.text!.lowercased(), at: 1)
        }
        self.keywordsCollectionView.reloadData()
    }
    
    func getMostFrequentKeywords() -> [String] {
        var allKeywords: [String] = []
        
        for item in items {
            if item.keywords != nil {
                for keyword in item.keywords! {
                    allKeywords.append(keyword)
                }
            }
        }
        
        let mappedKeywords = allKeywords.map { ($0, 1) }
        let counts = Dictionary(mappedKeywords, uniquingKeysWith: +)
        let sortedCounts = counts.sorted { $0.1 > $1.1 }
        let topKeywords = sortedCounts.prefix(10).map { $0.key }

        return topKeywords
    }
    
    func addPlaceholderLabel() {
        let placeholderLabel = UILabel()
        placeholderLabel.textAlignment = .center
        
        placeholderLabel.text = "What is on your mind?"
        placeholderLabel.textColor = UIColor(named: "content2")
        placeholderLabel.numberOfLines = 0
        placeholderLabel.sizeToFit()
        placeholderLabel.lineBreakMode = .byWordWrapping
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(placeholderLabel)
        
        placeholderLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    
    // Handle keyboard appearence
    @objc private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            tableViewBC.constant = keyboardFrame.height
        }
    }

    @objc private func handle(keyboardHideNotification notification: Notification) {
        tableViewBC.constant = 0
    }
    
    @objc func getTimeOfDate() {
        let ticks = Date().ticks
        timeLabel?.text = convertTime(time: ticks)
    }
    
    func convertTimestamp(timestamp: Double) -> String {
        let x = timestamp / 1000
        let date = NSDate(timeIntervalSince1970: x)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        return formatter.string(from: date as Date)
    }
    
    func convertTime(time: UInt64) -> String {
        let x = time / 1000
        let date = NSDate(timeIntervalSince1970: TimeInterval(x))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return formatter.string(from: date as Date)
    }
    
    
}



// MARK: - Keywords
extension itemsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @objc func defaultKeywordsCollectionView() {
        keywordsCollection = [selectedAllKeyword.title]
        mostFrequentKeywords = getMostFrequentKeywords()
        keywordsCollection.append(contentsOf: mostFrequentKeywords)
        selectedKeyword = selectedAllKeyword
        keywordsCollectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == keywordsCollectionView {
            if keywordsCollection != [] {
                return keywordsCollection.count
            } else {
                return 0
            }
        } else {
            if items[collectionView.tag].keywords != nil {
                return items[collectionView.tag].keywords!.count
            } else {
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == keywordsCollectionView {
            let text = keywordsCollection[indexPath.item]
            let cellWidth = text.size(withAttributes:[.font: UIFont.FiraMono(.regular, size: 16)]).width + 20
            let cellHeight = CGFloat(26.0)
        
            return CGSize(width: cellWidth, height: cellHeight)
        }

        else {
            let item = items[collectionView.tag]
            let text = item.keywords![indexPath.row]
            let cellWidth = text.size(withAttributes:[.font: UIFont.FiraMono(.regular, size: 16)]).width + 20
            let cellHeight = CGFloat(26.0)

            return CGSize(width: cellWidth, height: cellHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == keywordsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "keywordCell", for: indexPath) as! keywordsCollectionViewCell
            
            let itemKeywordTitle = keywordsCollection[indexPath.item]
            cell.keywordButton.setTitle(itemKeywordTitle, for: .normal)
            
            if selectedKeyword!.path == indexPath.row {
                cell.keywordButton.isSelected = true
                cell.keywordButton.layer.borderColor = UIColor(named: "buttonBackground")?.cgColor
            } else {
                cell.keywordButton.isSelected = false
                cell.keywordButton.layer.borderColor = UIColor(named: "content2")?.cgColor
            }
            
            return cell
        }
        
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "keywordCell", for: indexPath) as! ItemsKeywordsCell
            
            let item = items[collectionView.tag]
            let itemKeywordTitle = item.keywords![indexPath.row]
            cell.keywordButton.setTitle(itemKeywordTitle, for: .normal)
            
            return cell
        }
    }
    
}




// MARK: - Extensions

class itemContentText: UITextView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let tapLocation = point.applying(CGAffineTransform(translationX: -textContainerInset.left, y: -textContainerInset.top))
        let characterAtIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let linkAttributeAtIndex = textStorage.attribute(.link, at: characterAtIndex, effectiveRange: nil)

        // Returns true for points located on linked text
        return linkAttributeAtIndex != nil
    }

    override func becomeFirstResponder() -> Bool {
        // Returning false disables double-tap selection of link text
        return false
    }
}


extension Date {
    var current: Double {
        return Double((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}


public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func withRoundCorners(_ cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        let context = UIGraphicsGetCurrentContext()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

        context?.beginPath()
        context?.addPath(path.cgPath)
        context?.closePath()
        context?.clip()

        draw(at: CGPoint.zero)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        return image;
    }

}


extension UIView {
    func animateButtonDown() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
    }

    func animateButtonUp() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut], animations: {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
    }
}


extension UISearchBar {
    func setPlaceholderTextColorTo(color: UIColor) {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "content")!]
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = color
        
        // Make the magnifying glass the same color
        (textFieldInsideSearchBar!.leftView as? UIImageView)?.tintColor = color
    }
}


extension UIImage {
    class func circles(diameter: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        for i in 0...1 {
            let circle = UIBezierPath(arcCenter: CGPoint(x: diameter/2.5 + CGFloat(i*11), y: diameter/2), radius: diameter/3.5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            color.setStroke()
            circle.lineWidth = 2.8
            circle.stroke()
        }

        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return img
    }
}


extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}
