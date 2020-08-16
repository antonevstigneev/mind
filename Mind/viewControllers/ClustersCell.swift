//
//  ClustersCell.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class ClustersCell: UITableViewCell {

    @IBOutlet weak var clusterKeywordsCollectionView: UICollectionView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
}

class ClusterKeywordsCell: UICollectionViewCell {

    @IBOutlet weak var keywordButton: UIButton!
    
    override func awakeFromNib() {
         super.awakeFromNib()
         keywordButton.layer.cornerRadius = keywordButton.frame.size.height / 2
         keywordButton.layer.borderWidth = 1.2
         keywordButton.layer.borderColor = UIColor(named: "content")?.cgColor
         keywordButton.contentEdgeInsets = UIEdgeInsets(top: 1, left: 3, bottom: 3, right: 3)
         keywordButton.clipsToBounds = true
         keywordButton.setBackgroundColor(UIColor(named: "background")!, for: .normal)
         keywordButton.setBackgroundColor(UIColor(named: "content")!, for: .highlighted)
         keywordButton.setBackgroundColor(UIColor(named: "buttonBackground")!, for: .selected)
         keywordButton.setTitleColor(UIColor(named: "background")!, for: .selected)
    }
}

extension ClustersCell {
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate: D, forRow row: Int) {
        clusterKeywordsCollectionView.delegate = dataSourceDelegate
        clusterKeywordsCollectionView.dataSource = dataSourceDelegate
        clusterKeywordsCollectionView.tag = row
        clusterKeywordsCollectionView.reloadData()
    }
    
    func updateClustersHeights(_ height: CGFloat) {
        heightConstraint.constant = height
        clusterKeywordsCollectionView.layoutIfNeeded()
    }
}


