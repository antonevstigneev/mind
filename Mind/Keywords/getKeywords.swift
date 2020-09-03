
import Foundation
import NaturalLanguage

public func getKeywords(from text: String, count: Int) -> [String] {
    var keywords = text.keywords.slice(length: count)
    
    // for filtering out similar keywords
    if keywords.count > 1 {
        var similarKeywords: [String] = []
        for index in 0..<keywords.count {
            for keyword in keywords {
                let distance = Distance.levenshtein(A: keywords[index], B: keyword)
                if distance == 1 && !similarKeywords.contains(keywords[index]) {
                    similarKeywords.append(keyword)
                }
            }
        }
        for keyword in similarKeywords {
            keywords = keywords.filter { $0 != keyword }
        }
    }
    
    return keywords
}


public extension String {
    var keywords: [String] {
        return Keyword(text: self).execute()
    }
}


