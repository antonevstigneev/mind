//
//  ItemData.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

struct ItemData: Decodable {
    var embedding: [Double]?
    var keywords: [String]?
    var keywordsEmbedding: [[Double]]?
    
    enum CodingKeys: String, CodingKey {
        case embedding = "embedding"
        case keywords = "keywords"
        case keywordsEmbedding = "keywordsEmbedding"
    }
}
