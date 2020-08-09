
import Foundation
import NaturalLanguage

fileprivate let bert = BERT()

public func getKeywords(from text: String, count: Int) -> [String] {
    var keywords = text.keywords.slice(length: count)
    keywords = Normalize.getNouns(keywords)
    
    if keywords == [] {
        keywords = Keyword.preprocess(text)
                  .filter(removeShortWords)
        keywords = Normalize.getNouns(keywords)
    }
    
    return keywords
}

public extension String {
    var keywords: [String] {
        return Keyword(text: self).execute()
    }
}


