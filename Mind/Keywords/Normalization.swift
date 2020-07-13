
import Foundation
import NaturalLanguage

func detectedLanguage(for string: String) -> String? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(string)
    guard let languageCode = recognizer.dominantLanguage?.rawValue else { return "en" }
    return languageCode
}

internal struct Normalize {
    
    static func getNouns(_ text: [String]) -> [String] {
        var nouns: [String] = []
        
        let text = text.joined(separator: ", ")
        
        let language = detectedLanguage(for: text)
        let tagger = NSLinguisticTagger(
            tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: language!),
            options: 0)
        let options: NSLinguisticTagger.Options = [
            .omitPunctuation, .omitWhitespace, .joinNames
            ]

        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)

        tagger.enumerateTags(
            in: range,
            unit: .word,
            scheme: .nameTypeOrLexicalClass,
            options: options) {
                tag, tokenRange, _ in

                if let tag = tag {
                    if tag == .noun {
                        let word = (text as NSString)
                        .substring(with: tokenRange)
                        nouns.append(word)
                    }
                }
        }
        
        return Array(Set(nouns))
    }


    static func getLemmas(_ text: [String]) -> [String] {
        var lemmas: [String] = []
        
        let text = text.joined(separator: ", ")

        let language = detectedLanguage(for: text)
        let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: language!), options: 0)
        tagger.string = text
        
        let range = NSRange(location: 0, length: text.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        tagger.enumerateTags(in: range,
                             unit: .word,
                             scheme: .lemma,
                             options: options) { (tag, tokenRange, stop) in
        let word = (text as NSString).substring(with: tokenRange)
            if let lemma = tag?.rawValue {
                if lemma == "datum" {
                    lemmas.append("data")
                } else {
                    lemmas.append(lemma)
                }
            } else {
                lemmas.append(word)
            }
        }

        return Array(Set(lemmas))
    }
}
