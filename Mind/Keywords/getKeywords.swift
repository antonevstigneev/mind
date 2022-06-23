
import Foundation
import NaturalLanguage

public func getKeywords(from text: String, count: Int) -> [String] {
    let keywords = text.keywords.slice(length: count)
    
    return keywords
}


public extension String {
    var keywords: [String] {
        return Keyword(text: self).execute()
    }
}


