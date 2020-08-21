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
        setupNotifications()
        setupViews()
        if clusters.count == 0 {
            showSpinner()
            print("Clusters are not ready yet.")
        }
    }

    func setupViews() {
        // tableView initial setup
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(checkClusters),
        name: NSNotification.Name(rawValue: "clustersCreated"),
        object: nil)
    }
    
    @objc func checkClusters() {
        
        print("Clusters are loaded and ready.")
        print("Clusters number: \(clusters.count)")
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.removeSpinner()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clusters.count
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? ClustersCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ClustersCell
        cell.clusterKeywordsCollectionView.tag = indexPath.row
        
        let clusterKeywords = clusters[indexPath.row].joined(separator: " ")
        let clusterHeight = getHeigthForCluster(text: clusterKeywords, Width: cell.frame.width - 26.0)

        cell.heightConstraint.constant = clusterHeight

        return cell
    }
    
    func getHeigthForCluster(text: String, Width: CGFloat) -> CGFloat {

        let constrainedSize = CGSize.init(width: Width, height: CGFloat(MAXFLOAT))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .regular),
            .paragraphStyle: paragraphStyle]

        let mutablestring = NSMutableAttributedString.init(string: text, attributes: attributes)

        var requiredHeight = mutablestring.boundingRect(with: constrainedSize, options: NSStringDrawingOptions.usesFontLeading.union(NSStringDrawingOptions.usesLineFragmentOrigin), context: nil)

        if requiredHeight.size.width > Width {
            requiredHeight = CGRect.init(x: 0, y: 0, width: Width, height: requiredHeight.height)
        }
        
        return requiredHeight.size.height;
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
