//
//  FlowLayout.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class KeywordsClusterFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesForElementsInRect = super.layoutAttributesForElements(in: rect)
        var newAttributesForElementsInRect = [UICollectionViewLayoutAttributes]()
        
        var leftMargin: CGFloat = self.sectionInset.left
        
        for attributes in attributesForElementsInRect! {
            if (attributes.frame.origin.x == self.sectionInset.left) {
                leftMargin = self.sectionInset.left
            } else {
                var newLeftAlignedFrame = attributes.frame
                
                if leftMargin + attributes.frame.width < self.collectionViewContentSize.width {
                    newLeftAlignedFrame.origin.x = leftMargin
                } else {
                    newLeftAlignedFrame.origin.x = self.sectionInset.left
                }
                
                attributes.frame = newLeftAlignedFrame
            }
            leftMargin += attributes.frame.size.width + 8
            newAttributesForElementsInRect.append(attributes)
        }
        
        return newAttributesForElementsInRect
    }
}

