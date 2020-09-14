//
//  itemsViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 06.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import CoreData
import CoreML
import Foundation
import NaturalLanguage
import LocalAuthentication

class itemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    
    // MARK: - Data
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    // MARK: - Variables
    var items: [Item] = []
    var item: Item!
    var keywordsCollection: [String] = []
    var mostFrequentKeywords: [String] = []
    var selectedKeyword: String = ""
    var keywordsClusters: [[String]] = []
    var selectedFilter: String = "Recent"
    var refreshControl = UIRefreshControl()
    let searchController = UISearchController(searchResultsController: nil)
    var selectedInterfaceStyle: UIUserInterfaceStyle = .unspecified
    
    
    /// An authentication context stored at class scope so it's available for use during UI updates.
    var authContext = LAContext()

    /// The available states of being logged in or not.
    enum AuthenticationState {
        case loggedin, loggedout
    }

    /// The current authentication state.
    var state = AuthenticationState.loggedout {
        // Update the UI on a change.
        didSet {}
    }
    
    // MARK: - Outlets
    @IBOutlet weak var mindLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
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
    @IBAction func moreButtonTouchUpInside(_ sender: Any) {
        showMoreButtonMenu()
    }
    @IBAction func filterButtonTouchUpInside(_ sender: Any) {
        showFilterMenu()
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        fetchData()
        tableView.reloadData()
    }
    
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupViews()
        setupLabelTap()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(showItemsForSelectedKeyword),
        name: NSNotification.Name(rawValue: "itemKeywordClicked"),
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(fetchData),
        name: NSNotification.Name(rawValue: "itemsChanged"),
        object: nil)
        
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
        authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        // Set the initial app state. This impacts the initial state of the UI as well.
        state = .loggedout
        
        // navigationController initial setup
        self.navigationItem.searchController = searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchController.searchBar.setImage(UIImage(systemName: "xmark"), for: .clear, state: .normal)
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        searchController.searchBar.showsCancelButton = false
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.isEditing = false
        tableView.addSubview(refreshControl)
        
        // plusButton initial setup
        plusButton.layer.masksToBounds = true
        plusButton.layer.cornerRadius = plusButton.frame.size.height / 2
        
        // pullDown to search initital setup
        refreshControl.addTarget(self, action: #selector(self.pullToSearch(_:)), for: .valueChanged)
        refreshControl.alpha = 0
    }
    
    func setupLabelTap() {
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.mindTapped(_:)))
        self.mindLabel.isUserInteractionEnabled = true
        self.mindLabel.addGestureRecognizer(labelTap)
    }
    
    @objc func mindTapped(_ sender: UITapGestureRecognizer) {
        let indexPath = IndexPath(row: 0, section: 0)
        if self.items.isEmpty == false {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    @objc func showItemsForSelectedKeyword() {
        searchController.searchBar.text = "#\(selectedKeyword)"
        reloadSearch()
    }
    
    @objc func pullToSearch(_ sender: AnyObject) {
        searchController.searchBar.becomeFirstResponder()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
        reloadSearch()
        for item in items {
            print(item.embedding)
            print(item.keywords)
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            return self.createContextMenu(indexPath: indexPath)
        }
    }
    
    func createContextMenu(indexPath: IndexPath) -> UIMenu {
        self.item = self.items[indexPath.row]
        var favoriteLabel: String!
        var favoriteImage: UIImage!
        var lockedImage: UIImage!
        var lockedLabel: String!
        var archivedLabel: String!
        
        if item.favorited == true {
            favoriteLabel = "Unfavorite"
            favoriteImage = UIImage(systemName: "star.slash")
        } else {
            favoriteLabel = "Favorite"
            favoriteImage = UIImage(systemName: "star")
        }
        if item.locked == true {
            lockedLabel = "Unlock"
            lockedImage = UIImage(systemName: "lock.slash")
        } else {
            lockedLabel = "Lock"
            lockedImage = UIImage(systemName: "lock")
        }
        if item.archived == true {
            archivedLabel = "Unarchive"
        } else {
            archivedLabel = "Archive"
        }

        let favorite = UIAction(title: favoriteLabel, image: favoriteImage) { _ in
            self.favoriteItem(self.item, indexPath)
        }
        let lock = UIAction(title: lockedLabel, image: lockedImage) { _ in
            self.lockItem(self.item, indexPath)
        }
        let archive = UIAction(title: archivedLabel, image: UIImage(systemName: "archivebox")) { _ in
            self.archiveItem(self.item, indexPath)
        }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            self.deleteItem(self.item, indexPath)
        }
        
        if self.item.archived == true {
            return UIMenu(title: "", children: [favorite, lock, archive, delete])
        } else {
            return UIMenu(title: "", children: [favorite, lock, archive])
        }
    }
    
    public func favoriteItem(_ item: Item, _ indexPath: IndexPath) {
        if item.favorited == true {
            item.favorited = false
        } else {
            item.favorited = true
        }
        self.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    public func lockItem(_ item: Item, _ indexPath: IndexPath) {
        if item.locked == false {
            let actionMessage = "This will be hidded from all places but can be found in the Locked folder"
            postActionSheet(title: "", message: actionMessage, confirmation: "Lock", success: { () -> Void in
                self.item.locked = true
                self.items.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }) { () -> Void in
                print("Cancelled")
            }
        } else {
            self.item.locked = false
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
    }
    
    public func archiveItem(_ item: Item, _ indexPath: IndexPath) {
        if item.archived == false {
            let actionMessage = "This will be archived but can be found in the Archived folder"
            postActionSheet(title: "", message: actionMessage, confirmation: "Archive", success: { () -> Void in
                self.item.archived = true
                self.items.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }) { () -> Void in
                print("Cancelled")
            }
        } else {
            self.item.archived = false
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    public func deleteItem(_ item: Item, _ indexPath: IndexPath) {
        let actionTitle = "Are you sure you want to delete this?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Delete", success: { () -> Void in
            self.context.delete(item)
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            NotificationCenter.default.post(name:
                NSNotification.Name(rawValue: "itemsChanged"), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }) { () -> Void in
            print("Cancelled")
        }
    }
    
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell
        
        let item = items[indexPath.row]
        let content = item.value(forKey: "content") as! String
        
        cell.itemContentText.delegate = self
        
        cell.itemContentText.addHyperLinksToText(originalText: content, hyperLinks: item.keywords!, fontSize: 16, fontWeight: .regular, lineSpacing: 3.0)
        cell.itemContentText.textColor = UIColor(named: "text")
        
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
        self.item = self.items[indexPath.row]
        self.performSegue(withIdentifier: "toItemViewController", sender: (Any).self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchController.searchBar.searchTextField.backgroundColor = UIColor(named: "button")!
            .withAlphaComponent(-scrollView.contentOffset.y / 100)
    }
    
    @objc func keywordTapHandler(_ sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager

        // location of tap in myTextView coordinates and taking the inset into account
        var location = sender.location(in: myTextView)
        
        location.x -= myTextView.textContainerInset.left
        location.y -= myTextView.textContainerInset.top
        
        // character index at tap location
         let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        // check if the tap location has a certain attribute
         let attributeName = NSAttributedString.Key.link
         let attributeValue = myTextView.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil)
         if let clickedKeyword = attributeValue {
             searchController.searchBar.text = "#\(clickedKeyword)"
             reloadSearch()
         }

    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? itemViewController {
            destinationVC.selectedItem = self.item
            destinationVC.items = self.items
        }
    }
    
    
    // MARK: - Fetch items data
    @objc func fetchData() {
        let request: NSFetchRequest = Item.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            items = try context.fetch(request)
            switch selectedFilter {
            case "Recent":
                items = items.filter {
                    $0.locked == false &&
                    $0.archived == false
                }
            case "Favorite":
                items = items.filter {
                    $0.favorited == true &&
                    $0.locked == false &&
                    $0.archived == false
                }
            case "Random":
                items = items.shuffled()
                items = items.filter {
                    $0.locked == false &&
                    $0.archived == false
                }
            case "Locked":
                items = items.filter {
                    $0.locked == true &&
                    $0.archived == false
                }
            case "Archived":
                items = items.filter {
                    $0.locked == false &&
                    $0.archived == true
                }
            default:
                items = items.filter {
                    $0.locked == false &&
                    $0.archived == false
                }
            }
            
            let itemsLoading = DispatchGroup()
            DispatchQueue.main.async(group: itemsLoading) {
                self.tableView.reloadData()
            }
            itemsLoading.notify(queue: .main) {
                NotificationCenter.default.post(name:
                    NSNotification.Name(rawValue: "itemsLoaded"),
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
            self.tableView.hide()
            var itemsWithSelectedKeyword: [Item] = []
            items = try context.fetch(request)
            for item in items {
                if item.keywords!.contains(selectedKeyword) {
                    itemsWithSelectedKeyword.append(item)
                }
            }
            DispatchQueue.main.async {
                self.items = itemsWithSelectedKeyword
                self.items = self.items.filter {
                    $0.locked == false &&
                    $0.archived == false
                }
                self.tableView.reloadData()
                self.scrollToTopTableView()
                self.tableView.show()
            }
        } catch {
            print("Fetching failed")
        }
    }
    
    
    // MARK: - Semantic search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 2 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(itemsViewController.reloadSearch), object: nil)
            self.perform(#selector(itemsViewController.reloadSearch), with: nil, afterDelay: 1.0)
        } else {
            fetchData()
        }
    }
    
    @objc func reloadSearch() {
        guard let searchText = searchController.searchBar.text else { return }
        if !searchText.isEmpty {
            if searchText.hasPrefix("#") {
                selectedKeyword = String(searchController.searchBar.text!.dropFirst())
                fetchDataForSelectedKeyword()
            } else {
                performSimilaritySearch(searchText)
            }
        } else {
            fetchData()
        }
        searchController.dismiss(animated: false)
    }
    
    func performSimilaritySearch(_ searchText: String) {
        var similarItems: [Item] = []
        var suggestedKeywords: [String] = []
        
        tableView.hide()
        items = []
        tableView.reloadData()
        fetchData()
        
        self.showSpinner()
        DispatchQueue.global(qos: .userInitiated).async {
            
            suggestedKeywords = self.getKeywordSuggestions(for: searchText)
            
            var keywordsScores: [(item: Item, score: Int)] = []
            var itemsWithMatchedKeywords: [(item: Item, matchedKeywords: [String])] = []
            for item in self.items {
                itemsWithMatchedKeywords.append((item: item, matchedKeywords: []))
            }
            
            for keyword in suggestedKeywords {
                for item in self.items {
                    if item.keywords!.contains(keyword) {
                        if let index = itemsWithMatchedKeywords.firstIndex(where: {$0.item.content! == item.content!}) {
                            itemsWithMatchedKeywords[index].matchedKeywords.append(keyword)
                        }
                    }
                }
            }
            
            itemsWithMatchedKeywords = itemsWithMatchedKeywords.filter { $0.matchedKeywords != [] }
            itemsWithMatchedKeywords = itemsWithMatchedKeywords.sorted {$0.1.count > $1.1.count}
            
            for item in itemsWithMatchedKeywords {
                var keywordsScore: [Int] = []
                for keyword in item.matchedKeywords {
                    let indexOfKeyword = suggestedKeywords.firstIndex(of: keyword)
                    keywordsScore.append(indexOfKeyword!)
                }
                keywordsScores.append((item: item.item, score: keywordsScore.min()!))
            }
            
            keywordsScores = keywordsScores.sorted { $0.1 < $1.1 }
            similarItems = keywordsScores.map { $0.item }
        
            DispatchQueue.main.async {
                self.items = similarItems.slice(length: 10)
                self.tableView.reloadData()
                self.tableView.show()
                self.scrollToTopTableView()
                self.removeSpinner()
            }
        }
    }
    
    
    func findSimilarItems(for item: Item!) {
        searchController.searchBar.text = item.content!
        performSimilaritySearch(searchController.searchBar.text!)
    }
    
    
    // MARK: - Keywords suggestions
    func getKeywordSuggestions(for text: String) -> [String] {
        var keywordsSimilarityScores: [(keyword: String, score: Double)] = []
        let keywordsEmbeddings = getAllKeywordsEmbeddings()
//        let forKeywordEmbedding = self.bert.getTextEmbedding(text: text)
        let forKeywordEmbedding = keywordsEmbeddings[0].value // <--------------------------------------------- change
        
        for keywordEmbedding in keywordsEmbeddings {
            let score = Distance.cosine(A: forKeywordEmbedding, B: keywordEmbedding.value)
            keywordsSimilarityScores.append((keyword: keywordEmbedding.keyword, score: score))
        }
        
        keywordsSimilarityScores = keywordsSimilarityScores.sorted { $0.1 > $1.1 }
        let suggestedKeywords = keywordsSimilarityScores.prefix(10)
        
        return suggestedKeywords.map { $0.keyword }
    }
    
    
    func getAllKeywordsEmbeddings() -> [(keyword: String, value: [Double])] {
        var keywordsEmbeddings: [(keyword: String, value: [Double])] = []
        for item in items {
            for keyword in item.keywords! {
                if !keywordsEmbeddings.map({$0.0}).contains(keyword) {
                    let keywordIndex = item.keywords!.firstIndex(of: keyword)!
                    let keywordEmbedding = item.keywordsEmbeddings![keywordIndex]
                    keywordsEmbeddings.append((keyword: keyword, value: keywordEmbedding))
                }
            }
        }
        return keywordsEmbeddings
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
    
    
    func getRandomKeywords() -> [String] {
        var allKeywords: [String] = []
        
        for item in items {
            if item.keywords != nil {
                for keyword in item.keywords! {
                    allKeywords.append(keyword)
                }
            }
        }
        
        let shuffledKeywords = Array(Set(allKeywords.shuffled()))
        let topShuffledKeywords = shuffledKeywords.prefix(10).map { $0 }
        
        return topShuffledKeywords
    }
    
    func getItemsSimilarityScores() {
        var itemsPairs: [[Item]] = []
        var itemsPairsScores: [Double] = []
        var itemsTotalScores: [(itemContent: String, score: Double)] = []
        
        let itemsEmbeddings = getItemsEmbeddings()
        
        for item in items {
            let currentItemEmbedding = item.embedding!
            var itemTotalScore: Double = 0
            for index in 0..<items.count {
                let otherItemEmbedding = itemsEmbeddings[index]
                if item != items[index] {
                    itemsPairs.append([item, items[index]])
                    let score = Distance.cosine(A: currentItemEmbedding, B: otherItemEmbedding)
                    itemTotalScore += score
                    itemsPairsScores.append(score)
                }
            }
            itemsTotalScores.append((item.content!, itemTotalScore))
        }
        itemsTotalScores = itemsTotalScores.sorted { $0.1 > $1.1 }
        print("Items similarity matrix:")
        print("\n")
        for i in itemsTotalScores {
            print(i.itemContent)
            print(i.score)
            print("\n")
        }
    }
    
    
    func getItemsEmbeddings() -> [[Double]] {
        var itemsEmbeddings: [[Double]] = []
        for item in items {
            itemsEmbeddings.append(item.embedding!)
        }
        return itemsEmbeddings
    }

    
    func scrollToTopTableView() {
        if self.items.isEmpty == false {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    
    func getKeywordsEmbeddings() -> [(keyword: String, embedding: [Double])] {
        var keywordsWithEmbeddings: [(keyword: String, embedding: [Double])] = []
        
        for item in self.items {
            for (index, keyword) in item.keywords!.enumerated() {
                if !keywordsWithEmbeddings.map({$0.keyword}).contains(keyword) {
                    let keywordEmbedding = item.keywordsEmbeddings![index]
                    keywordsWithEmbeddings.append((keyword: keyword, embedding: keywordEmbedding))
                }
            }
        }
        
        return keywordsWithEmbeddings
    }
    
    
    func getItemsEmbeddingsTest() -> [(item: String, embedding: [Double])] {
        var itemsEmbeddings: [(item: String, embedding: [Double])] = []
        
        for item in self.items {
            itemsEmbeddings.append((item: item.content!, embedding: item.embedding!))
        }
        
        return itemsEmbeddings
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
    
    func postAlert(title: String, _ message: String = "") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        // delays execution of code to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
    func showFilterMenu() {
        let titles = ["Recent", "Favorite", "Random", "Locked", "Archived"]
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for title in titles {
            let actionAlert: UIAlertAction = UIAlertAction(title: title, style: .default) { action in
                self.selectedFilter = title
                if title == "Locked" {
                    self.authenticateWithBiometrics()
                } else {
                    self.state = .loggedout
                    self.fetchData()
                }
            }
            if title == selectedFilter {
                actionAlert.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            controller.addAction(actionAlert)
        }
        controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        controller.view.tintColor = UIColor(named: "button")
        self.present(controller, animated: true, completion: nil)
    }
    
    
    func showMoreButtonMenu() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let aboutAction: UIAlertAction = UIAlertAction(title: "About", style: .default)
            { _ in
                //                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            aboutAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            aboutAction.setValue(UIImage(systemName: "info.circle"), forKey: "image")
            
            let supportAction: UIAlertAction = UIAlertAction(title: "Support", style: .default)
            { _ in
                let mailURL = URL(string: "mailto:contact@getmindapp.com")!
                UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            }
            supportAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            supportAction.setValue(UIImage(systemName: "text.bubble"), forKey: "image")
            
            let mindCloudAction: UIAlertAction = UIAlertAction(title: "Mind Cloud", style: .default)
            { _ in
                self.performSegue(withIdentifier: "toCloudViewController", sender: (Any).self)
            }
            mindCloudAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            mindCloudAction.setValue(UIImage(systemName: "cloud"), forKey: "image")
            
            alertController.addAction(cancelAction)
            alertController.addAction(mindCloudAction)
            alertController.addAction(supportAction)
            alertController.addAction(aboutAction)
            
            alertController.view.tintColor = UIColor(named: "button")
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func authenticateWithBiometrics() {
        if self.state == .loggedin {

            // Log out immediately.
            self.state = .loggedout

        } else {

            // Get a fresh context for each login. If you use the same context on multiple attempts
            //  (by commenting out the next line), then a previously successful authentication
            //  causes the next policy evaluation to succeed without testing biometry again.
            //  That's usually not what you want.
            
            self.authContext = LAContext()
            self.authContext.localizedCancelTitle = ""
            
            // First check if we have the needed hardware support.
            var error: NSError?
            if self.authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                
                let reason = "Log in to your account"
                self.authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in

                    if success {

                        // Move to the main thread because a state update triggers UI changes.
                        DispatchQueue.main.async { [unowned self] in
                            self.state = .loggedin
                            self.tableView.show()
                            self.fetchData()
                        }

                    } else {
                        print(error?.localizedDescription ?? "Failed to authenticate")
                        
                        self.selectedFilter = "Recent"
                        self.fetchData()
                        // Fall back to a asking for username and password.
                        // ...
                    }
                }
            } else {
                // User has denied the use of biometry for this app.
                print(error?.localizedDescription ?? "Can't evaluate policy")
                self.getBiometricsAccess()
                
                
                // Fall back to a asking for username and password.
                // ...
            }
        }
    }
    
    func getBiometricsAccess() {
        var biomertyType: String = ""
        if authContext.biometryType == .faceID {
            biomertyType = "FaceID"
        } else {
            biomertyType = "TouchID"
        }
                
        let alertController = UIAlertController (title: "\(biomertyType) is disabled", message: "Go to Settings, to enable \(biomertyType).", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in

            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (UIAlertAction) in
            print("Cancel was pressed")
            self.selectedFilter = "Recent"
            self.fetchData()
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    
}
    
    


// MARK: - Extensions

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
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

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
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
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "text")!]
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = color
        
        // Make the magnifying glass the same color
        (textFieldInsideSearchBar!.leftView as? UIImageView)?.tintColor = color
    }
}


extension UIView {
    #if targetEnvironment(macCatalyst)
    @objc(_focusRingType)
    var focusRingType: UInt {
        return 1
    }
    #endif
}


extension Array where Element == Float {
    public var asArrayOfDoubles: [Double] {
        return self.map { return Double($0) }
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


extension itemsViewController {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


extension UITextView {
    
    func addHyperLinksToText(originalText: String, hyperLinks: [String], fontSize: Int, fontWeight: UIFont.Weight, lineSpacing: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineSpacing = lineSpacing
        
        if hyperLinks.count > 0 {
            let attributedOriginalText = NSMutableAttributedString(string: originalText)
            for hyperLink in hyperLinks {
                let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
                let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
                attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: hyperLink, range: linkRange)
                attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
                attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight), range: fullRange)
            }
            self.linkTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
                NSAttributedString.Key.underlineStyle: 0,
            ]
            
            self.attributedText = attributedOriginalText
        } else {
            let attributes: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.paragraphStyle: style,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight)
            ]
            let attributedOriginalText = NSMutableAttributedString(string: originalText, attributes: attributes)
            
            self.attributedText = attributedOriginalText
        }
    }
    
    func clearTextStyles(originalText: String, fontSize: Int = 21, fontWeight: UIFont.Weight = .regular, lineSpacing: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineSpacing = lineSpacing
        
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight)
        ]
        
        let attributedOriginalText = NSMutableAttributedString(string: originalText, attributes: attributes)

        self.attributedText = attributedOriginalText
    }
}


extension UIViewController {
    func postActionSheet(title: String!, message: String!, confirmation: String!, success: (() -> Void)? , cancel: (() -> Void)?) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: message,
                                                    preferredStyle: .actionSheet)
            alertController.view.tintColor = UIColor.lightGray
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel",
                                                            style: .cancel) {
                                                                action -> Void in cancel?()
            }
            let successAction: UIAlertAction = UIAlertAction(title: confirmation,
                                                             style: .destructive) {
                                                                action -> Void in success?()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(successAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


extension String {

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}
