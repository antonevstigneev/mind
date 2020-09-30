//
//  Itemsswift
//  Mind
//
//  Created by Anton Evstigneev on 09.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit


class ThoughtsTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var thoughtContentText: UITextView!
    @IBOutlet weak var thoughtContentTextRC: NSLayoutConstraint!
    @IBOutlet weak var favoritedButton: UIButton!
    @IBOutlet weak var retryButton: UIButton!
}

class ThoughtContentText: UITextView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
