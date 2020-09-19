//
//  Authorization.swift
//  Mind
//
//  Created by Anton Evstigneev on 16.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

class Authorization {
    class var isUserAuthorized: Bool {
        return UserDefaults.standard.object(forKey: "isAuthorized") as! Bool
    }
}
