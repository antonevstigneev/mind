//
//  ArraySlice.swift
//  Mind
//
//  Created by Anton Evstigneev on 17.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

internal extension Array {

    var count: Float {
        return Float(self.count as Int)
    }

    func slice(length: Int) -> [Element] {
        return self.prefix(length).map { $0 }
    }

    func slice(percent: Float) -> [Element] {
        if 0.0...1.0 ~= percent {
            let count = Int((1-percent)*self.count)
            return slice(length: count)
        }
        return []
    }
}
