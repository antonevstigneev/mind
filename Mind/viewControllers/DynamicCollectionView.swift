//
//  DynamicCollectionView.swift
//  Mind
//
//  Created by Anton Evstigneev on 17.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class DynamicCollectionView: UICollectionView {

    override func layoutSubviews() {
            super.layoutSubviews()
            if bounds.size != intrinsicContentSize {
                invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: CGSize {
            return self.contentSize
    }

}
