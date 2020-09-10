//
//  selectedItemCell.swift
//  Mind
//
//  Created by Anton Evstigneev on 10.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class selectedItemCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var itemContentTextView: UITextView!
    
    override func awakeFromNib() {
        itemContentTextView.isScrollEnabled = false
        itemContentTextView.translatesAutoresizingMaskIntoConstraints = true
        itemContentTextView.isEditable = true
        itemContentTextView.sizeToFit()
        itemContentTextView.delegate = self
    }
    
}
