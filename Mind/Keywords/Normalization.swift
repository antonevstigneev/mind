
import Foundation
import NaturalLanguage

func detectedLanguage(for string: String) -> String? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(string)
    guard let languageCode = recognizer.dominantLanguage?.rawValue else { return "en" }
    return languageCode
}

internal struct Normalize {
    
    static func getNouns(_ keywords: [String]) -> [String] {
        var nouns: [String] = []
        
        let keywords = keywords.joined(separator: ", ")
        
        let language = detectedLanguage(for: keywords)
        let tagger = NSLinguisticTagger(
            tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: language!),
            options: 0)
        let options: NSLinguisticTagger.Options = [
            .omitPunctuation, .omitWhitespace, .joinNames
            ]

        tagger.string = keywords
        let range = NSRange(location: 0, length: keywords.utf16.count)

        tagger.enumerateTags(
            in: range,
            unit: .word,
            scheme: .nameTypeOrLexicalClass,
            options: options) {
                tag, tokenRange, _ in

                if let tag = tag {
                    if tag == .noun {
                        let word = (keywords as NSString)
                        .substring(with: tokenRange)
                        nouns.append(word)
                    }
                }
        }
        
        return Array(Set(nouns))
    }

}
