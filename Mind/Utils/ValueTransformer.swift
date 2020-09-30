//
//  ValueTransformer.swift
//  Mind
//
//  Created by Anton Evstigneev on 29.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

// 1. Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(EmbeddingValueTransformer)
final class EmbeddingValueTransformer: NSSecureUnarchiveFromDataTransformer {

    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: EmbeddingValueTransformer.self))

    // 2. Make sure `UIColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return [EmbeddingValueTransformer.self]
    }

    /// Registers the transformer.
    public static func register() {
        let transformer = EmbeddingValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
