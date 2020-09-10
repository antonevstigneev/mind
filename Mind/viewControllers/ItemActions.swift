//
//  ItemActions.swift
//  Mind
//
//  Created by Anton Evstigneev on 09.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import CoreData
import UIKit

var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext


extension Item {

    func favorite() {
        if self.favorited == true {
            self.favorited = false
        } else {
            self.favorited = true
        }
    }

    func lock() {
        if self.locked == false {
            self.locked = true
        } else {
            self.locked = false
        }
    }

    func archive() {
        if self.archived == false {
            self.archived = true
        } else {
            self.archived = false
        }
    }

    func delete() {
        context.delete(self)
    }
    
    func saveChanges() {
        NotificationCenter.default.post(name:
            NSNotification.Name(rawValue: "itemsChanged"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
}
