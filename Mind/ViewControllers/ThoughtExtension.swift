//
//  ThoughtExtension.swift
//  Mind
//
//  Created by Anton Evstigneev on 19.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import CoreData
import UIKit


// MARK: - Data
var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext


// MARK: - Thought actions
extension Thought {
    
    enum ThoughtState: String {
        case favorited = "favorited"
        case locked = "locked"
        case archived = "archived"
    }
    
    func toggleState(_ state: ThoughtState) {
        
        var options: [ThoughtState: Bool] = [
            .favorited: self.favorited,
            .locked: self.locked,
            .archived: self.archived,
        ]
        options[state]!.toggle()
        self.setValue(options[state]!, forKey: state.rawValue)

        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func remove() {
        context.delete(self)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
}

