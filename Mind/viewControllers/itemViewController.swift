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

class itemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Variables
    var items: [Item] = []
    var similarItems: [Item] = []
    var selectedItem: Item!
    
    // MARK: - Outlets
    @IBOutlet weak var itemContentTextView: UITextView!
    @IBOutlet weak var itemTimestampLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIButton!
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }
    
    func setupViews() {
        
        // itemView initial setup
        itemContentTextView.text = self.selectedItem.content!
        itemContentTextView.isScrollEnabled = false
        itemContentTextView.translatesAutoresizingMaskIntoConstraints = true
        itemContentTextView.sizeToFit()
        itemContentTextView.textColor = UIColor(named: "content")
        itemTimestampLabel.text = convertTimestamp(timestamp: selectedItem.value(forKey: "timestamp") as! Double)
        
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.isEditing = false
        
        // plusButton initial setup
        plusButton.layer.masksToBounds = true
        plusButton.layer.cornerRadius = plusButton.frame.size.height / 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return similarItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell
                
        let item = similarItems[indexPath.row]
        let content = item.content!
        
        cell.itemContentText.addHyperLinksToText(originalText: content, hyperLinks: item.keywords!, fontSize: 16)
        cell.itemContentText.textColor = UIColor(named: "content")!
        
        if item.favorited {
            cell.favoritedButton.isHidden = false
            cell.itemContentTextRC.constant = 35
            
        } else {
            cell.favoritedButton.isHidden = true
            cell.itemContentTextRC.constant = 16
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(self.similarItems[indexPath.row].content!)
        selectedItem = self.similarItems[indexPath.row]
        self.performSegue(withIdentifier: "toItemViewController", sender: (Any).self)
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
        self.tableView.hide()
        self.showSpinner()
        similarItems = getSimilarItems(item: self.selectedItem)
        DispatchQueue.main.async() {
            self.tableView.reloadData()
            self.tableView.show()
            self.removeSpinner()
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
    
    func convertTime(time: UInt64) -> String {
        let x = time / 1000
        let date = NSDate(timeIntervalSince1970: TimeInterval(x))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: date as Date)
    }
    
}
