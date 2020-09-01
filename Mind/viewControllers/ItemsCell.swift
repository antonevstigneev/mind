//
//  Itemsswift
//  Mind
//
//  Created by Anton Evstigneev on 09.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit


class ItemsCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var itemContentText: UITextView!
    @IBOutlet weak var itemContentTextRC: NSLayoutConstraint!
    @IBOutlet weak var favoritedButton: UIButton!
}

class ItemContentText: UITextView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
