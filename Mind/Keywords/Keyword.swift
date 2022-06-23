
import Foundation
import NaturalLanguage

internal final class Keyword {

    private let ngram: Int = 2
    private var words: [String]
    private var nouns: [String]

    private let ranking = TextRank<String>()

    init(text: String) {
        self.words = Keyword.preprocess(text)
        self.nouns = Keyword.getAllNouns(text)
    }

    func execute() -> [String] {
        filterWords()
        removeSimilarWords()
        buildGraph()
        return ranking.execute()
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    func filterWords() {
        self.words = self.words
            .filter(removeShortWords)
            .filter(removeStopWords)
            .filter(removeNotNouns)
    }
    
    func removeSimilarWords() {
        var similarKeywords: [String] = []
        for index in 0..<self.words.count {
            for keyword in self.words {
                let distance = Distance.levenshtein(A: self.words[index], B: keyword)
                if distance == 1 && !similarKeywords.contains(self.words[index]) {
                    similarKeywords.append(keyword)
                }
            }
        }
        for keyword in similarKeywords {
            self.words = self.words.filter { $0 != keyword }
        }
    }

    func buildGraph() {
        for (index, node) in words.enumerated() {
            var (min, max) = (index-ngram, index+ngram)
            if min < 0 { min = words.startIndex }
            if max > words.count { max = words.endIndex }
            words[min..<max].forEach { word in
                ranking.add(edge: node, to: word)
            }
        }
    }
}

extension Keyword {

    static func preprocess(_ text: String) -> [String] {
        return text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
    }
    
    static func getAllNouns(_ text: String) -> [String] {
        var nounWords: [String] = []
        // Initialize the tagger
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        // Ignore whitespace and punctuation marks
        let options : NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        // Process the text for POS
        tagger.string = text

        // loop through all the tokens and print their POS tags
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag {
                if tag.rawValue == "Noun" {
                    nounWords.append(text[tokenRange].lowercased())
//                    print("\(text[tokenRange].lowercased()): \(tag.rawValue)")
                }
            }
            return true
        }
        return nounWords
    }
    
    func removeNotNouns(_ word: String) -> Bool {
        return self.nouns.contains(word)
    }
}

public func removeShortWords(_ word: String) -> Bool {
    return word.count > 2
}

public func removeStopWords(_ word: String) -> Bool {
    return !stopwords.contains(word)
}
