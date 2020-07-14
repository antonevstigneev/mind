//
//  similarItemsViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 17.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import UIKit

class similarItemsViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var item: Item!
    var similarItems: [Item] = []
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // tableView initial setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return similarItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemsCell
        
        let item = similarItems[indexPath.row]
        
        let content = item.value(forKey: "content") as! String
                
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        let regularAttributes: [NSAttributedString.Key : Any] = [.font : UIFont.FiraMono(.regular, size: 16), .paragraphStyle : paragraphStyle, .foregroundColor: UIColor(named: "content")! ]
        let mutableString = NSMutableAttributedString(string: content, attributes: regularAttributes)
        
        cell.itemContentText.attributedText = mutableString

        cell.itemContentText.textContainerInset = UIEdgeInsets(top: 10, left: 6, bottom: 11, right: 6)

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
    
}

// MARK: - Item keywords
extension similarItemsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return similarItems[collectionView.tag].keywords!.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let item = similarItems[collectionView.tag]

        let text = item.keywords![indexPath.row]
        let cellWidth = text.size(withAttributes:[.font: UIFont.FiraMono(.regular, size: 16)]).width + 20
        let cellHeight = CGFloat(26.0)
  
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "keywordCell", for: indexPath) as! ItemsKeywordsCell
        
        let item = similarItems[collectionView.tag]
        
        let text = item.keywords![indexPath.row]
        cell.keywordButton.setTitle(text, for: .normal)
        
        return cell
    }
    
}
