//
//  Itemsswift
//  Mind
//
//  Created by Anton Evstigneev on 09.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

// MARK: - Data
var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext


class ThoughtsTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var thoughtContentText: UITextView!
    @IBOutlet weak var thoughtContentTextRC: NSLayoutConstraint!
    @IBOutlet weak var favoritedButton: UIButton!
}


extension Thought {
    
    enum ThoughtState: String {
        case favorited = "favorited"
        case locked = "locked"
        case archived = "archived"
    }
    
    func toggleState(_ state: ThoughtState) {
        
        var options: [ThoughtState: Bool] = [
            .favorited: false,
            .locked: false,
            .archived: false,
        ]
        
        options[state]!.toggle()
        
        // Update thought data
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if MindCloud.isUserAuthorized {
            MindCloud.updateThought(id: self.id!, upd: [state.rawValue: options[state]!]) {
                (responseData, success) in
                if (success) {
                    print("✅ 🔐 Authorized thought update success.")
                }
            }
        }
    }
    
    func delete() {
        context.delete(self)
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "thoughtsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        if MindCloud.isUserAuthorized {
            MindCloud.deleteThought(id: self.id!) { (responseData, success) in
                if (success) {
                    print("✅ 🔐 Authorized thought deletion success.")
                }
            }
        }
    }
}


class ThoughtContentText: UITextView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
