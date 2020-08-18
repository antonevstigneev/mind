//
//  Itemsswift
//  Mind
//
//  Created by Anton Evstigneev on 09.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit


class ItemsCell: UITableViewCell {
    
    @IBOutlet weak var itemContentText: UITextView!
    @IBOutlet weak var itemKeywordsCollectionView: UICollectionView!
}


class ItemsKeywordsCell: UICollectionViewCell {

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


extension ItemsCell {
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate: D, forRow row: Int) {
        itemKeywordsCollectionView.delegate = dataSourceDelegate
        itemKeywordsCollectionView.dataSource = dataSourceDelegate
        itemKeywordsCollectionView.tag = row
        itemKeywordsCollectionView.reloadData()
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
