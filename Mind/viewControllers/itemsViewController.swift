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
import Firebase

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
    var keywordsClusters: [[String]] = []
    var selectedClusterKeyword: String = ""
    var selectedFilter: String = "Recent"
    var refreshControl = UIRefreshControl()
    var emojiEmbeddings = getEmojiEmbeddings()
    

    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mindLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var tableViewBC: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var emptyPlaceholderLabel: UILabel!
    
    
    
    // MARK: - Actions
    @IBAction func plusButtonTouchDownInside(_ sender: Any) {
        plusButton.animateButtonUp()
        performSegue(withIdentifier: "toAddItemViewController", sender: sender)
        Analytics.logEvent("plusButton_pressed", parameters: nil)
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
//        performSegue(withIdentifier: "toFilterViewController", sender: sender)
        showFilterMenu()
        Analytics.logEvent("filterButton_pressed", parameters: nil)
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
    
    override func viewDidLayoutSubviews() {
        setupSearchBar(searchBar: searchBar)
    }
    
    func setupSearchBar(searchBar : UISearchBar) {
        searchBar.setPlaceholderTextColorTo(color: UIColor(named: "content2")!)
    }
    
    func setupNotifications() {
//        NotificationCenter.default.addObserver(self,
//        selector: #selector(hierarchicalClustering),
//        name: NSNotification.Name(rawValue: "itemsChanged"),
//        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(updateEmptyView),
        name: NSNotification.Name(rawValue: "itemsLoaded"),
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
        // searchBar initial setup
        searchBar.delegate = self
        searchBar.setImage(UIImage(systemName: "xmark"), for: .clear, state: .normal)
        
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
        refreshControl.setValue(75, forKey: "_snappingHeight")
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
    
    
    @objc func pullToSearch(_ sender: AnyObject) {
        searchBar.becomeFirstResponder()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
//        getEmojiForKeywords()
//        recalculateAllKeywords()
        hierarchicalClustering()
//        updateAllEmbeddings()
    }
    
    @objc func updateEmptyView() {
        if items.count > 0 {
            tableView.isHidden = false
            searchBar.isHidden = false
            emptyPlaceholderLabel.isHidden = true
        } else {
            tableView.isHidden = true
            searchBar.isHidden = true
            emptyPlaceholderLabel.isHidden = false
            if selectedFilter == "Archived"  {
                emptyPlaceholderLabel.text = "Archive is empty."
            }
            if selectedFilter == "Hidden" {
                emptyPlaceholderLabel.text = "No hidden elements."
            }
            if selectedFilter == "Favorite" {
                emptyPlaceholderLabel.text = "No favorites."
            }
        }
    }
    
    func recalculateAllKeywords() {
        // for restoring texted keywords
        for item in items {
            item.keywords = []
            let keywords = getKeywords(from: item.content!, count: 8)
            item.keywords = keywords
            item.keywordsEmbeddings = self.bert.getKeywordsEmbeddings(keywords: keywords)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            tableView.reloadData()
        }
    }

    func getEmojiForKeywords() {
        for item in items {
            let keywordEmbeddings = self.bert.getKeywordsEmbeddings(keywords: item.keywords!)
            for (index, keywordEmbedding) in keywordEmbeddings.enumerated() {
                var scores: [(emoji: String, score: Float)] = []
                for (index, emojiEmbedding) in emojiEmbeddings.enumerated() {
                    let score = Distance.cosine(A: keywordEmbedding, B: emojiEmbedding)
                    let emoji = getEmoji(index)
                    scores.append((emoji: emoji, score: score))
                }
                scores = scores.sorted {$0.1 > $1.1}
                print("keyword: '\(item.keywords![index])', predicted emoji: \(scores[0].emoji), score: \(scores[0].score)")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    
    func copyItemContent(_ item: Item) {
        let content = item.content
        let pasteboard = UIPasteboard.general
        pasteboard.string = content
    }
    
    func favoriteItem(_ item: Item) {
        if item.favorited == true {
            item.favorited = false
        } else {
            item.favorited = true
        }
        NotificationCenter.default.post(name:
        NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func hideItem(_ item: Item, _ indexPath: IndexPath) {
        let actionMessage = "This will be hidded from all places but can be found in the Hidden folder"
        postActionSheet(title: "", message: actionMessage, confirmation: "Hide", success: { () -> Void in
            print("Hide clicked")
            self.item.hidden = true
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "itemsChanged"), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
          }) { () -> Void in
            print("Cancelled")
        }
    }
    
    func archiveItem(_ item: Item, _ indexPath: IndexPath) {
        let actionMessage = "This will be archived but can be found in the Archived folder"
        if item.archived == true {
            self.item.archived = false
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        } else {
            postActionSheet(title: "", message: actionMessage, confirmation: "Archive", success: { () -> Void in
                self.item.archived = true
                self.items.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
              }) { () -> Void in
                print("Cancelled")
            }
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func deleteItem(_ item: Item, _ indexPath: IndexPath) {
        let actionTitle = "Are you sure you want to delete this?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Delete", success: { () -> Void in
            print("Delete clicked")
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
    
    
    // MARK: - Items Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell
        
        let item = items[indexPath.row]
        let content = item.value(forKey: "content") as! String
        
        cell.itemContentText.delegate = self
        cell.itemContentText.addHyperLinksToText(originalText: content, hyperLinks: item.keywords!)
        cell.itemContentText.textColor = UIColor(named: "content")!
        
        if item.favorited {
            cell.favoritedButton.isHidden = false
            cell.itemContentTextRC.constant = 35
            
        } else {
            cell.favoritedButton.isHidden = true
            cell.itemContentTextRC.constant = 16
        }
//        cell.itemTimestampLabel?.text = convertTimestamp(timestamp: item.value(forKey: "timestamp") as! Double)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        showItemMenu(indexPath: indexPath)
        self.item = self.items[indexPath.row]
        self.performSegue(withIdentifier: "toItemViewController", sender: (Any).self)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.searchTextField.backgroundColor = UIColor(named: "buttonBackground")!
                                .withAlphaComponent(-scrollView.contentOffset.y / 100)
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? editItemViewController {
            destinationVC.item = self.item
        }
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
                    $0.hidden == false &&
                    $0.archived == false
                }
            case "Favorite":
                items = items.filter {
                    $0.favorited == true &&
                    $0.hidden == false &&
                    $0.archived == false
                }
            case "Random":
                items = items.shuffled()
                items = items.filter {
                    $0.hidden == false &&
                    $0.archived == false
                }
            case "Hidden":
                items = items.filter {
                    $0.hidden == true &&
                    $0.archived == false
                }
            case "Archived":
                items = items.filter {
                    $0.hidden == false &&
                    $0.archived == true
                }
            default:
                items = items.filter {
                    $0.hidden == false &&
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
                self.tableView.reloadData()
                self.scrollToTopTableView()
                self.tableView.show()
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
        var topSimilarItems: [Item] = []
        
        if text != "" {
            selectedItemEmbedding = self.bert.getTextEmbedding(text: text)
        } else {
            selectedItemEmbedding = item!.embedding!
        }
        
        for item in items {
            let distance = Distance.cosine(A: selectedItemEmbedding, B: item.embedding!)
            similarItems.append(item)
            scores.append(distance)
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
        print(sortedResults.map {$0.0.content!}, sortedResults.map {$0.1})
        return sortedResults.map {$0.0}
    }
    
    
    // MARK: - Semantic search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(itemsViewController.reloadSearch), object: nil)
            self.perform(#selector(itemsViewController.reloadSearch), with: nil, afterDelay: 1.0)
        } else {
            fetchData()
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
        
        tableView.hide()
        items = []
        tableView.reloadData()
        fetchData()
        
        self.showSpinner()
        DispatchQueue.global(qos: .userInitiated).async {
            
            //            similarItems = self.getSimilarItems(text: searchText)
            
            let keywordsForSearchText = getKeywords(from: searchText, count: 6)
            if keywordsForSearchText == [] {
                suggestedKeywords = self.getKeywordSuggestions(for: searchText)
            }
            suggestedKeywords = self.getKeywordSuggestions(for: keywordsForSearchText.joined(separator: " "))
            
            
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
                Analytics.logEvent("search_completed", parameters: nil)
            }
        }
    }
    
    
    func findSimilarItems(for item: Item!) {
        searchBar.text = item.content!
        performSimilaritySearch(searchBar.text!)
    }
    
    
    func updateAllEmbeddings() {
        self.showSpinner()
        DispatchQueue.global(qos: .userInitiated).async {
            for item in self.items {
                item.keywordsEmbeddings = self.bert.getKeywordsEmbeddings(keywords: item.keywords!)
                item.embedding = self.bert.getTextEmbedding(text: item.content!)
            }
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                self.tableView.reloadData()
                self.removeSpinner()
            }
        }
    }
    
    
    // MARK: - Keywords suggestions
    func getKeywordSuggestions(for text: String) -> [String] {
        var keywordsSimilarityScores: [(keyword: String, score: Float)] = []
        let keywordsEmbeddings = getAllKeywordsEmbeddings()
        let forKeywordEmbedding = self.bert.getTextEmbedding(text: text)
        
        for keywordEmbedding in keywordsEmbeddings {
            let score = Distance.cosine(A: forKeywordEmbedding, B: keywordEmbedding.value)
            keywordsSimilarityScores.append((keyword: keywordEmbedding.keyword, score: score))
        }
        
        keywordsSimilarityScores = keywordsSimilarityScores.sorted { $0.1 > $1.1 }
        let suggestedKeywords = keywordsSimilarityScores.prefix(11)
        
        return suggestedKeywords.map { $0.keyword }
    }
    
    
    func getAllKeywordsEmbeddings() -> [(keyword: String, value: [Float])] {
        var keywordsEmbeddings: [(keyword: String, value: [Float])] = []
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
        var itemsPairsScores: [Float] = []
        var itemsTotalScores: [(itemContent: String, score: Float)] = []
        
        let itemsEmbeddings = getItemsEmbeddings()
        
        for item in items {
            let currentItemEmbedding = item.embedding!
            var itemTotalScore: Float = 0
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
    
    func getItemsEmbeddings() -> [[Float]] {
        var itemsEmbeddings: [[Float]] = []
        for item in items {
            itemsEmbeddings.append(item.embedding!)
        }
        return itemsEmbeddings
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
    
    func scrollToTopTableView() {
        if self.items.isEmpty == false {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    
    // MARK: - Clustering
    @objc func hierarchicalClustering() {
        let clustersCreation = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: clustersCreation) {
            var (similarityMatrix, keywords) = self.getSimilarityMatrix()
            var clusters: [[String]] = []
            for keyword in keywords {
                clusters.append([keyword])
            }
            let matrixMeanValue = similarityMatrix.grid.avg()
            
            while clusters.count > 1 {
                
                // get most two most similar keywords
                let minValues = similarityMatrix.grid.filter { $0 != 0.0 }
                let minValue = minValues.min()
                
                if minValue! > matrixMeanValue { break }
                
                let firstValue = similarityMatrix.position(of: minValue!)[0]
                let secondValue = similarityMatrix.position(of: minValue!)[1]
                
                // get max values from similar keywords value pairs
                let firstValuesRow = similarityMatrix.getRowValues(firstValue.row)
                let secondValuesRow = similarityMatrix.getRowValues(secondValue.row)
//                print("Min value \(minValue!) between: \(clusters[firstValue.row]) and \(clusters[secondValue.row])")
                var maxValues = zip(firstValuesRow, secondValuesRow).map { max($0, $1) }
                maxValues[firstValue.row] = 0.0
                
                // update matrix with new values
                for column in 0...similarityMatrix.columns-1 {
                    similarityMatrix[firstValue.row, column] = maxValues[column]
                    similarityMatrix[column, firstValue.row] = maxValues[column]
                }
                similarityMatrix.remove(row: secondValue.row, column: firstValue.column)
                
                // update keywords cluster labels
                clusters[firstValue.row].append(contentsOf: clusters[secondValue.row])
                clusters.remove(at: secondValue.row)
                
                // save clusters
                DispatchQueue.main.async {
                    self.keywordsClusters = clusters
                    // remove outliers
                    self.keywordsClusters = self.keywordsClusters
                                            .filter { $0.count > 1}
                }
                
            }
        }
        clustersCreation.notify(queue: .main) {
            NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "clustersCreated"),
            object: nil)
        }
    }
    
    func getSimilarityMatrix() -> (Matrix, [String]) {
        let keywordsWithEmbeddings = getKeywordsEmbeddings()
        let keywordsEmbeddings = keywordsWithEmbeddings.map { $0.embedding }
        let keywords = keywordsWithEmbeddings.map { $0.keyword }
        
        let matrixSize = Int(keywords.count)
        var matrix = Matrix(rows: matrixSize, columns: matrixSize)
        
        for (index, keyword) in keywords.enumerated() {
            let currentKeywordIndex = keywords.firstIndex(of: keyword)!
            let currentKeywordEmbedding = keywordsEmbeddings[index]
            for index in currentKeywordIndex..<keywords.count {
                var score: Float = 0.0
                let otherKeywordEmbedding = keywordsEmbeddings[index]
                if keyword != keywords[index] {
                    score = Distance.euclidean(A: currentKeywordEmbedding, B: otherKeywordEmbedding)
//                    print("Score \(score) between \(keyword) and \(keywords[index])")
                } else {
                    score = 0.0
                }
                matrix[index, currentKeywordIndex] = score
                matrix[currentKeywordIndex, index] = score
            }
        }
        
        return (matrix, keywords)
    }
    
    
    func getKeywordsEmbeddings() -> [(keyword: String, embedding: [Float])] {
        var keywordsWithEmbeddings: [(keyword: String, embedding: [Float])] = []
        
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
    
    
    func getItemsEmbeddingsTest() -> [(item: String, embedding: [Float])] {
        var itemsEmbeddings: [(item: String, embedding: [Float])] = []
        
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
    
    func postAlert(title: String, _ message: String = "") {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      self.present(alert, animated: true, completion: nil)

      // delays execution of code to dismiss
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
        alert.dismiss(animated: true, completion: nil)
      })
    }
    
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
    
    func showFilterMenu() {
        let titles = ["Recent", "Favorite", "Random", "Hidden", "Archived"]
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for title in titles {
            let actionAlert: UIAlertAction = UIAlertAction(title: title, style: .default) { action in
                self.selectedFilter = title
                self.fetchData()
            }
            if title == selectedFilter {
                actionAlert.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            controller.addAction(actionAlert)
        }
        controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        controller.view.tintColor = UIColor(named: "buttonBackground")!
        self.present(controller, animated: true, completion: nil)
    }
    
    func showMoreButtonMenu() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let FAQAction: UIAlertAction = UIAlertAction(title: "Mind FAQ", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            FAQAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            FAQAction.setValue(UIImage(systemName: "questionmark.circle"), forKey: "image")
            
            let questionAction: UIAlertAction = UIAlertAction(title: "Ask a Question", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            questionAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            questionAction.setValue(UIImage(systemName: "text.bubble"), forKey: "image")
            
            let appearanceAction: UIAlertAction = UIAlertAction(title: "Appearance", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            appearanceAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            appearanceAction.setValue(UIImage(systemName: "paintbrush"), forKey: "image")
            
            let privacyAction: UIAlertAction = UIAlertAction(title: "Privacy and Security", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            privacyAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            privacyAction.setValue(UIImage(systemName: "lock"), forKey: "image")
            
            let syncAction: UIAlertAction = UIAlertAction(title: "Synchronization", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            syncAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            syncAction.setValue(UIImage(systemName: "icloud"), forKey: "image")
            
            let subscriptionAction: UIAlertAction = UIAlertAction(title: "Subscription", style: .default)
            { _ in
//                self.performSegue(withIdentifier: "", sender: (Any).self)
            }
            subscriptionAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            subscriptionAction.setValue(UIImage(systemName: "goforward"), forKey: "image")
            
            alertController.addAction(cancelAction)
            alertController.addAction(subscriptionAction)
            alertController.addAction(syncAction)
            alertController.addAction(privacyAction)
            alertController.addAction(appearanceAction)
            alertController.addAction(questionAction)
            alertController.addAction(FAQAction)
            
            alertController.view.tintColor = UIColor(named: "buttonBackground")!
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Item menu
    func showItemMenu(indexPath: IndexPath) {
        self.item = self.items[indexPath.row]
        var favoriteLabel: String!
        var favoriteImage: UIImage!
        var archivedLabel: String!
        
        if item.favorited == true {
            favoriteLabel = "Unfavorite"
            favoriteImage = UIImage(systemName: "star.slash")
        } else {
            favoriteLabel = "Favorite"
            favoriteImage = UIImage(systemName: "star")
        }
        
        if item.archived == true {
            archivedLabel = "Unarchive"
        } else {
            archivedLabel = "Archive"
        }
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let archiveAction: UIAlertAction = UIAlertAction(title: archivedLabel, style: .default)
            { _ in
                self.archiveItem(self.item, indexPath)
            }
            archiveAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            archiveAction.setValue(UIImage(systemName: "archivebox"), forKey: "image")
            
            let hideAction: UIAlertAction = UIAlertAction(title: "Hide", style: .default)
            { _ in
                self.hideItem(self.item, indexPath)
            }
            hideAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            hideAction.setValue(UIImage(systemName: "eye.slash"), forKey: "image")
            
            let favoriteAction: UIAlertAction = UIAlertAction(title: favoriteLabel, style: .default)
            { _ in
                self.favoriteItem(self.item)
            }
            favoriteAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            favoriteAction.setValue(favoriteImage, forKey: "image")
            
            let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default)
            { _ in
                self.performSegue(withIdentifier: "toEditItemViewController", sender: (Any).self)
            }
            editAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            editAction.setValue(UIImage(systemName: "square.and.pencil"), forKey: "image")
            
            let copyAction: UIAlertAction = UIAlertAction(title: "Copy", style: .default)
            { _ in
                self.copyItemContent(self.item)
            }
            copyAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            copyAction.setValue(UIImage(systemName: "doc.on.doc"), forKey: "image")
            
            let similarAction: UIAlertAction = UIAlertAction(title: "Similar", style: .default)
            { _ in
                self.findSimilarItems(for: self.item)
                Analytics.logEvent("similarItems_search", parameters: nil)
            }
            similarAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            similarAction.setValue(UIImage(systemName: "circle.grid.2x2"), forKey: "image")
            
            alertController.addAction(cancelAction)
            alertController.addAction(similarAction)
            alertController.addAction(copyAction)
            alertController.addAction(editAction)
            alertController.addAction(favoriteAction)
            alertController.addAction(hideAction)
            alertController.addAction(archiveAction)
            
            if self.item.archived == true {
                let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive)
                { _ in
                    self.deleteItem(self.item, indexPath)
                }
                deleteAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                deleteAction.setValue(UIImage(systemName: "trash"), forKey: "image")
                alertController.addAction(deleteAction)
            }
            
            alertController.view.tintColor = UIColor(named: "buttonBackground")!
            self.present(alertController, animated: true, completion: nil)
        }
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
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "content")!]
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
    
    func addHyperLinksToText(originalText: String, hyperLinks: [String]) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineSpacing = 3.0

        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        for hyperLink in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: "#" + hyperLink, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 16, weight: .regular), range: fullRange)
        }
        
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
            NSAttributedString.Key.underlineStyle: 0,
        ]
        self.attributedText = attributedOriginalText
    }
}

