//
//  clustersViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class clustersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Variables
    var clusters: [[String]] = []
    var selectedClusterKeyword: String = ""
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // Actions
    @IBAction func clusterKeywordTouchUpInside(_ sender: UIButton) {
        selectedClusterKeyword = sender.titleLabel!.text!
    }
    
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }


    @objc func setupViews() {
        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clusters.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ClustersCell
        cell.clusterKeywordsCollectionView.tag = indexPath.row
        
        cell.clusterKeywordsCollectionView.delegate = self
        cell.clusterKeywordsCollectionView.dataSource = self
        
        let height = cell.clusterKeywordsCollectionView.collectionViewLayout.collectionViewContentSize.height
        cell.heightConstraint.constant = height
        self.view.layoutIfNeeded()
        
        return cell
    }
    
    
}


// MARK: - Keywords setup
extension clustersViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clusters[collectionView.tag].count
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cluster = clusters[collectionView.tag]
        let text = cluster[indexPath.row]
        let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize: 17, weight: .regular)]).width + 20
        let cellHeight = CGFloat(26.0)
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "keywordCell", for: indexPath) as! ClusterKeywordsCell
        
        let cluster = clusters[collectionView.tag]
        let keywordTitle = cluster[indexPath.row]
        cell.keywordButton.setTitle(keywordTitle, for: .normal)
        
        return cell
    }
    
    
    // MARK: - Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let itemsViewController = segue.destination as! itemsViewController
        itemsViewController.selectedClusterKeyword = self.selectedClusterKeyword
        NotificationCenter.default.post(name:
        NSNotification.Name(rawValue: "clusterKeywordClicked"),
                                        object: nil)
    }


}
