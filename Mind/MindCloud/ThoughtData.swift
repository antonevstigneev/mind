//
//  ItemData.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

struct ThoughtData: Decodable {
    var embedding: [Double]?
    var keywords: [String]?
    var keywordsEmbeddings: [[Double]]?
    var timestamp: Int64?
    var id: String?
    
    enum CodingKeys: String, CodingKey {
        case embedding = "embedding"
        case keywords = "keywords"
        case keywordsEmbeddings = "keywordsEmbeddings"
        case timestamp = "timestamp"
        case id = "_id"
    }
}
