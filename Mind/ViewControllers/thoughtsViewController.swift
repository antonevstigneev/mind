//
//  thoughtsVC.swift
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
import LocalAuthentication


class thoughtsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    
    // MARK: - Model
        let bert = BERT()
    
    
    // MARK: - Data
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    
    // MARK: - Variables
    var thoughts: [Thought] = [] {
        willSet {
            DispatchQueue.main.async {
                self.placeholderView.removeFromSuperview()
            }
        }
        didSet {
            if thoughts.count == 0 {
                DispatchQueue.main.async {
                    self.addPlaceholderView()
                }
            }
        }
    }
    var thought: Thought!
    var selectedFilter: ThoughtsFilter = .recent
    var refreshControl = UIRefreshControl()
    let searchController = UISearchController(searchResultsController: nil)
    let iconConfig = UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)
    var authContext = LAContext()
    enum AuthenticationState { case loggedin, loggedout }
    var state = AuthenticationState.loggedout { didSet {} }
    var placeholderView = UIView()
    
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var tableViewBC: NSLayoutConstraint!
    
    
    // MARK: - Actions
    @IBAction func plusButtonTouchDownInside(_ sender: UIButton) {
        sender.animate()
    }
    @IBAction func moreButtonTouchUpInside(_ sender: Any) {
        showMoreButtonMenu()
    }
    @IBAction func filterButtonTouchUpInside(_ sender: Any) {
        showFilterMenu()
    }
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        fetchThoughtsData()
    }
    
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupViews()
        
        // biometric auth init setup for locked thoughts
        authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        self.state = .loggedout
    }
    
    
    func setupViews() {
        
        // navigationController initial setup
        self.navigationItem.titleView = searchController.searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle", withConfiguration: iconConfig),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(showFilterMenu))
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        
        searchController.searchBar.setImage(SFSymbols.close, for: .clear, state: .normal)
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        searchController.searchBar.showsCancelButton = false
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
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
     
    
    @objc func mindTapped(_ sender: UITapGestureRecognizer) {
        self.tableView.scrollToTheTop(animated: true)
    }
    
    @objc func pullToSearch(_ sender: AnyObject) {
        searchController.searchBar.becomeFirstResponder()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchThoughtsData()
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
        self.thought = self.thoughts[indexPath.row]
        var favoriteLabel: String!
        var favoriteImage: UIImage!
        var lockedImage: UIImage!
        var lockedLabel: String!
        var archivedLabel: String!
        
        if thought.favorited == true {
            favoriteLabel = "Unfavorite"
            favoriteImage = SFSymbols.unfavorite
        } else {
            favoriteLabel = "Favorite"
            favoriteImage = SFSymbols.favorite
        }
        if thought.locked == true {
            lockedLabel = "Unlock"
            lockedImage = SFSymbols.unlocked
        } else {
            lockedLabel = "Lock"
            lockedImage = SFSymbols.locked
        }
        if thought.archived == true {
            archivedLabel = "Unarchive"
        } else {
            archivedLabel = "Archive"
        }

        let favorite = UIAction(title: favoriteLabel, image: favoriteImage) { _ in
            self.favoriteThought(self.thought, indexPath)
        }
        let lock = UIAction(title: lockedLabel, image: lockedImage) { _ in
            self.lockThought(self.thought, indexPath)
        }
        let archive = UIAction(title: archivedLabel, image: SFSymbols.archive) { _ in
            self.archiveThought(self.thought, indexPath)
        }
        let remove = UIAction(title: "Remove", image: SFSymbols.remove, attributes: .destructive) { _ in
            self.removeThought(self.thought, indexPath)
        }
        
        if self.thought.archived {
            return UIMenu(title: "", children: [favorite, lock, archive, remove])
        } else {
            return UIMenu(title: "", children: [favorite, lock, archive])
        }
    }
    
    public func favoriteThought(_ thought: Thought, _ indexPath: IndexPath) {
        thought.toggleState(.favorited)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    public func lockThought(_ thought: Thought, _ indexPath: IndexPath) {
        self.thoughts.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        thought.toggleState(.locked)
    }

    public func archiveThought(_ thought: Thought, _ indexPath: IndexPath) {
        self.thoughts.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        thought.toggleState(.archived)
    }

    public func removeThought(_ thought: Thought, _ indexPath: IndexPath) {
        let actionTitle = "Are you sure you want to remove this thought?"
        postActionSheet(title: actionTitle, message: "", confirmation: "Remove", success: { () -> Void in
            thought.remove()
            self.thoughts.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
        }) { () -> Void in
            print("Cancelled")
        }
    }
    
 
    
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thoughts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ThoughtsTableViewCell
        
        let thought = thoughts[indexPath.row]
        let content = thought.content!
        
        cell.thoughtContentText.delegate = self
        
        if thought.keywords != nil {
            cell.thoughtContentText.highlightKeywords(originalText: content, keywords: thought.keywords!, fontSize: 16, lineSpacing: 3.0)
        }
        
        cell.thoughtContentText.font = UIFont.systemFont(ofSize: 16)
        cell.thoughtContentText.textColor = UIColor(named: "text")
        
        if thought.embedding == nil {
            cell.retryButton.isHidden = false
            cell.thoughtContentTextRC.constant = 35
        } else {
            cell.retryButton.isHidden = true
            cell.thoughtContentTextRC.constant = 16
        }
        
        if thought.favorited && thought.embedding != nil {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.thought = self.thoughts[indexPath.row]
        self.performSegue(withIdentifier: "toThoughtViewController", sender: (Any).self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // change search bar tint here <------------------
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
        
         if let tappedKeyword = attributeValue {
            showThoughtsForSelectedKeyword(tappedKeyword as! String)
         }
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? thoughtViewController {
            destinationVC.selectedThought = self.thought
            destinationVC.thoughts = self.thoughts
        }
    }
    
    
    // MARK: - Fetch thoughts data
    @objc func fetchThoughtsData() {
        let request: NSFetchRequest = Thought.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            thoughts = try context.fetch(request)
            applyThoughtsFilter(selectedFilter)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                NotificationCenter.default.post(name:
                    NSNotification.Name(rawValue: "thoughtsDataFetched"),
                                                object: nil)
            }
        } catch {
            print("Fetching failed")
        }
    }
    
    @objc func showThoughtsForSelectedKeyword(_ keyword: String) {
        
        searchController.searchBar.text = "#\(keyword)"
        
        let request: NSFetchRequest = Thought.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            self.tableView.hide()
            thoughts = try context.fetch(request)
            thoughts = thoughts.filter { $0.keywords!.contains(keyword) }

            DispatchQueue.main.async {
                self.applyThoughtsFilter(.recent)
                self.tableView.reloadData()
                self.tableView.scrollToTheTop(animated: false)
                self.tableView.show()
            }
        } catch {
            print("Fetching failed")
        }
    }
    
    
    // MARK: - Semantic search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 1 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(thoughtsViewController.reloadSearch), object: nil)
            self.perform(#selector(thoughtsViewController.reloadSearch), with: nil, afterDelay: 1.0)
        } else {
            fetchThoughtsData()
        }
    }
    
    @objc func reloadSearch() {
        guard let searchText = searchController.searchBar.text else { return }
        if !searchText.isEmpty {
            performSimilaritySearch(searchText)
        } else {
            fetchThoughtsData()
        }
        searchController.dismiss(animated: false)
    }
    
    func performSimilaritySearch(_ searchText: String) {
        var similarThoughts: [Thought] = []
        var suggestedKeywords: [String] = []
        
        tableView.hide()
        thoughts = []
        tableView.reloadData()
        fetchThoughtsData()
        
        self.showSpinner()
        DispatchQueue.global(qos: .userInitiated).async {
            
            suggestedKeywords = self.getKeywordSuggestions(for: searchText)
            
            var keywordsScores: [(thought: Thought, score: Int)] = []
            var thoughtsWithMatchedKeywords: [(thought: Thought, matchedKeywords: [String])] = []
            for thought in self.thoughts {
                thoughtsWithMatchedKeywords.append((thought: thought, matchedKeywords: []))
            }
            
            for keyword in suggestedKeywords {
                for thought in self.thoughts {
                    if thought.keywords!.contains(keyword) {
                        if let index = thoughtsWithMatchedKeywords.firstIndex(where: {$0.thought.content! == thought.content!}) {
                            thoughtsWithMatchedKeywords[index].matchedKeywords.append(keyword)
                        }
                    }
                }
            }
            
            thoughtsWithMatchedKeywords = thoughtsWithMatchedKeywords.filter { $0.matchedKeywords != [] }
            thoughtsWithMatchedKeywords = thoughtsWithMatchedKeywords.sorted {$0.1.count > $1.1.count}
            
            for thought in thoughtsWithMatchedKeywords {
                var keywordsScore: [Int] = []
                for keyword in thought.matchedKeywords {
                    let indexOfKeyword = suggestedKeywords.firstIndex(of: keyword)
                    keywordsScore.append(indexOfKeyword!)
                }
                keywordsScores.append((thought: thought.thought, score: keywordsScore.min()!))
            }
            
            keywordsScores = keywordsScores.sorted { $0.1 < $1.1 }
            similarThoughts = keywordsScores.map { $0.thought }
        
            DispatchQueue.main.async {
                self.thoughts = similarThoughts.slice(length: 10)
                self.tableView.reloadData()
                self.tableView.show()
                self.tableView.scrollToTheTop(animated: false)
                self.removeSpinner()
            }
        }
    }
    
    
    func findSimilarThoughts(for thought: Thought!) {
        searchController.searchBar.text = thought.content!
        performSimilaritySearch(searchController.searchBar.text!)
    }
    
    
    // MARK: - Keywords suggestions
    func getKeywordSuggestions(for text: String) -> [String] {
        var keywordsSimilarityScores: [(keyword: String, score: Float)] = []
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
    
    
    func getAllKeywordsEmbeddings() -> [(keyword: String, value: [Float])] {
        var keywordsEmbeddings: [(keyword: String, value: [Float])] = []
        for thought in thoughts {
            for keyword in thought.keywords! {
                if !keywordsEmbeddings.map({$0.0}).contains(keyword) {
                    let keywordIndex = thought.keywords!.firstIndex(of: keyword)!
                    let keywordEmbedding = thought.keywordsEmbeddings![keywordIndex]
                    keywordsEmbeddings.append((keyword: keyword, value: keywordEmbedding))
                }
            }
        }
        return keywordsEmbeddings
    }
    
    
    func getMostFrequentKeywords() -> [String] {
        var allKeywords: [String] = []
        
        for thought in thoughts {
            if thought.keywords != nil {
                for keyword in thought.keywords! {
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
        
        for thought in thoughts {
            if thought.keywords != nil {
                for keyword in thought.keywords! {
                    allKeywords.append(keyword)
                }
            }
        }
        
        let shuffledKeywords = Array(Set(allKeywords.shuffled()))
        let topShuffledKeywords = shuffledKeywords.prefix(10).map { $0 }
        
        return topShuffledKeywords
    }
    
    func getThoughtsSimilarityScores() {
        var thoughtsPairs: [[Thought]] = []
        var thoughtsPairsScores: [Float] = []
        var thoughtsTotalScores: [(thoughtContent: String, score: Float)] = []
        
        let thoughtsEmbeddings = getThoughtsEmbeddings()
        
        for thought in thoughts {
            let currentThoughtEmbedding = thought.embedding!
            var thoughtTotalScore: Float = 0
            for index in 0..<thoughts.count {
                let otherThoughtEmbedding = thoughtsEmbeddings[index]
                if thought != thoughts[index] {
                    thoughtsPairs.append([thought, thoughts[index]])
                    let score = Distance.cosine(A: currentThoughtEmbedding, B: otherThoughtEmbedding)
                    thoughtTotalScore += score
                    thoughtsPairsScores.append(score)
                }
            }
            thoughtsTotalScores.append((thought.content!, thoughtTotalScore))
        }
        thoughtsTotalScores = thoughtsTotalScores.sorted { $0.1 > $1.1 }
        print("Thoughts similarity matrix:")
        print("\n")
        for i in thoughtsTotalScores {
            print(i.thoughtContent)
            print(i.score)
            print("\n")
        }
    }
    
    
    func getThoughtsEmbeddings() -> [[Float]] {
        var thoughtsEmbeddings: [[Float]] = []
        for thought in thoughts {
            thoughtsEmbeddings.append(thought.embedding!)
        }
        return thoughtsEmbeddings
    }

    func getKeywordsEmbeddings() -> [(keyword: String, embedding: [Float])] {
        var keywordsWithEmbeddings: [(keyword: String, embedding: [Float])] = []
        
        for thought in self.thoughts {
            for (index, keyword) in thought.keywords!.enumerated() {
                if !keywordsWithEmbeddings.map({$0.keyword}).contains(keyword) {
                    let keywordEmbedding = thought.keywordsEmbeddings![index]
                    keywordsWithEmbeddings.append((keyword: keyword, embedding: keywordEmbedding))
                }
            }
        }
        
        return keywordsWithEmbeddings
    }
    
    
    func getThoughtsEmbeddingsTest() -> [(thought: String, embedding: [Float])] {
        var thoughtsEmbeddings: [(thought: String, embedding: [Float])] = []
        
        for thought in self.thoughts {
            thoughtsEmbeddings.append((thought: thought.content!, embedding: thought.embedding!))
        }
        
        return thoughtsEmbeddings
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
    
    @objc func showFilterMenu() {
        let titles = ["Recent", "Favorite", "Random", "Locked", "Archived"]
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for title in titles {
            let actionAlert: UIAlertAction = UIAlertAction(title: title, style: .default) { action in
                self.selectedFilter = ThoughtsFilter(rawValue: title)!
                if title == "Locked" {
                    self.authenticateWithBiometrics()
                } else {
                    self.state = .loggedout
                    self.fetchThoughtsData()
                }
            }
            if title == selectedFilter.rawValue {
                actionAlert.setValue(SFSymbols.checkmark, forKey: "image")
            }
            controller.addAction(actionAlert)
        }
        controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        controller.view.tintColor = UIColor(named: "button")
        self.present(controller, animated: true, completion: nil)
    }
    
    
    @objc func showMoreButtonMenu() {
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
            aboutAction.setValue(SFSymbols.info, forKey: "image")
            
            let supportAction: UIAlertAction = UIAlertAction(title: "Support", style: .default)
            { _ in
                let mailURL = URL(string: "mailto:contact@getmindapp.com")!
                UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            }
            supportAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            supportAction.setValue(SFSymbols.text, forKey: "image")
            
            let mindCloudAction: UIAlertAction = UIAlertAction(title: "Mind Cloud", style: .default)
            { _ in
                self.performSegue(withIdentifier: "toMindCloudVC", sender: (Any).self)
            }
            mindCloudAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            mindCloudAction.setValue(SFSymbols.cloud, forKey: "image")
            
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
                            self.fetchThoughtsData()
                        }

                    } else {
                        print(error?.localizedDescription ?? "Failed to authenticate")
                        
                        self.selectedFilter = ThoughtsFilter.recent
                        self.fetchThoughtsData()
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
            self.selectedFilter = ThoughtsFilter.recent
            self.fetchThoughtsData()
        }
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    
}
    
    
// MARK: - ThoughtsFilter

extension thoughtsViewController {
    
    enum ThoughtsFilter: String {
        case recent = "Recent"
        case favorite = "Favorite"
        case random = "Random"
        case locked = "Locked"
        case archived = "Archived"
    }
    
    func applyThoughtsFilter(_ filter: ThoughtsFilter) {
        switch filter {
        case .recent:
            thoughts = thoughts.filter {
                $0.locked == false &&
                $0.archived == false
            }
        case .favorite:
            thoughts = thoughts.filter {
                $0.favorited == true &&
                $0.locked == false &&
                $0.archived == false
            }
        case .random:
            thoughts = thoughts.shuffled()
            thoughts = thoughts.filter {
                $0.locked == false &&
                $0.archived == false
            }
        case .locked:
            thoughts = thoughts.filter {
                $0.locked == true &&
                $0.archived == false
            }
        case .archived:
            thoughts = thoughts.filter {
                $0.locked == false &&
                $0.archived == true
            }
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


extension thoughtsViewController {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


extension UITextView {
    
    func highlightKeywords(originalText: String, keywords: [String], fontSize: Int, lineSpacing: CGFloat, fontWeight: UIFont.Weight = .regular) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineSpacing = lineSpacing
        
        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        for keyword in keywords {
            let linkRange = attributedOriginalText.mutableString.range(of: keyword)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: keyword, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight), range: fullRange)
        }
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "link")!,
            NSAttributedString.Key.underlineStyle: 0]
        
        self.attributedText = attributedOriginalText
    }
    
    func addLineSpacing(originalText: String, lineSpacing: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let attributes = [NSAttributedString.Key.paragraphStyle : style]
        self.attributedText = NSAttributedString(string: originalText, attributes:attributes)
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
    
    //Show a basic alert
    func showAlert(alertText : String, alertMessage : String) {
        let alert = UIAlertController(title: alertText, message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}


extension String {

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}


extension thoughtsViewController {
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(showThoughtsForSelectedKeyword),
        name: NSNotification.Name(rawValue: "thoughtKeywordClicked"),
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(fetchThoughtsData),
        name: NSNotification.Name(rawValue: "thoughtsChanged"),
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
}


extension thoughtsViewController {
    
    func addPlaceholderView() {
        placeholderView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        placeholderView.center = self.view.center
        self.view.addSubview(placeholderView)
        
        let iconOptions: [ThoughtsFilter: UIImage] = [
            .favorite: UIImage(systemName: "star.fill")!,
            .locked: UIImage(systemName: "lock.fill")!,
            .archived: UIImage(systemName: "archivebox.fill")!,
            .recent: UIImage(systemName: "clock.fill")!,
            .random: UIImage(systemName: "shuffle")!,
        ]
        
        let selectedIcon = iconOptions[selectedFilter]!
        let selectedIconWidth = selectedIcon.size.width * 3.5
        let selectedIconHeight = selectedIcon.size.height * 3.5
        
        let placeholderIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: selectedIconWidth, height: selectedIconHeight))
        placeholderIcon.center = CGPoint(x: placeholderView.frame.size.width  / 2,
                                         y: placeholderView.frame.size.height / 2)
        placeholderIcon.image = selectedIcon
        placeholderIcon.tintColor = UIColor(named: "placeholder")
        self.placeholderView.addSubview(placeholderIcon)
        
        let placeholderTitle = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.maxX, height: 21))
        placeholderTitle.center = CGPoint(x: placeholderIcon.frame.midX, y: placeholderIcon.frame.maxY + 45)
        placeholderTitle.textAlignment = .center
        placeholderTitle.textColor = UIColor(named: "placeholder")
        placeholderTitle.font = placeholderTitle.font.withSize(26)
        placeholderTitle.text = "No \(selectedFilter.rawValue)"
        self.placeholderView.addSubview(placeholderTitle)
        
        let placeholderMessage = UILabel(frame: CGRect(x: 0, y: 0, width: self.placeholderView.frame.maxX, height: 21))
        placeholderMessage.center = CGPoint(x: placeholderIcon.frame.midX, y: placeholderTitle.frame.maxY + 25)
        placeholderMessage.textAlignment = .center
        placeholderMessage.textColor = UIColor(named: "placeholder")
        placeholderMessage.font = placeholderMessage.font.withSize(16)
        placeholderMessage.text = "Your \(selectedFilter.rawValue.lowercased()) thoughts will appear here."
        self.placeholderView.addSubview(placeholderMessage)
    }
}
