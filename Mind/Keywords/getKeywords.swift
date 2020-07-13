
import Foundation
import NaturalLanguage

fileprivate let bert = BERT()

public func getKeywords(from text: String, count: Int) -> [String] {
    return text.keywords.slice(length: count)
}

public extension String {
    var keywords: [String] {
        return Keyword(text: self).execute()
    }
}


