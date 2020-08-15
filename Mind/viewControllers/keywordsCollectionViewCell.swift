//
//  keywordsCollectionViewCell.swift
//  Mind
//
//  Created by Anton Evstigneev on 29.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//


import UIKit

// for keywords in header (keywords selector collection view)
class keywordsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var keywordButton: UIButton!
    
    override func awakeFromNib() {
         super.awakeFromNib()
        
         keywordButton.layer.cornerRadius = keywordButton.frame.size.height / 2
         keywordButton.contentEdgeInsets = UIEdgeInsets(top: 1, left: 3, bottom: 3, right: 3)
         keywordButton.layer.borderWidth = 1.2
         keywordButton.clipsToBounds = true
        
         keywordButton.layer.borderColor = UIColor(named: "content2")?.cgColor
         keywordButton.setBackgroundColor(UIColor(named: "background")!, for: .normal)
         keywordButton.setTitleColor(UIColor(named: "content2")!, for: .normal)
        
         keywordButton.setBackgroundColor(UIColor(named: "content")!, for: .highlighted)
         keywordButton.setBackgroundColor(UIColor(named: "buttonBackground")!, for: .selected)
         keywordButton.setTitleColor(UIColor(named: "background")!, for: .selected)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        keywordButton.isSelected = false
    }
    
    
}
