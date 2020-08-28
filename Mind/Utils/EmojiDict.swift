import Foundation

public func getEmojiEmbeddings() -> [[Float]] {
    let emojiJSONEmbeddings = readJSONFromFile(fileName: "EmojiEmbeddings")
    var emojiEmbeddings: [[Float]] = []
    for embedding in emojiJSONEmbeddings! {
        emojiEmbeddings.append(embedding.map { $0.floatValue })
    }
    return emojiEmbeddings
}


public func readJSONFromFile(fileName: String) -> [[NSNumber]]? {
    var json: [[NSNumber]]?
    if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
        do {
            let fileUrl = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            json = try? JSONSerialization.jsonObject(with: data) as? [[NSNumber]]
        } catch {
            print("Can't read JSON file.")
        }
    }
    
    return json
}

public func getEmoji(_ index: Int) -> String {
    return emojiDict[index].emoji
}

let emojiDict = [
(emoji: "💀", word: "death"), 
(emoji: "🤖", word: "robot"),
(emoji: "👽", word: "alien"),
(emoji: "😱", word: "surprise"),
(emoji: "🤓", word: "nerd"),
(emoji: "🤯", word: "explosion"),
(emoji: "⭐", word: "star"),
(emoji: "🔥", word: "fire"),
(emoji: "🎓", word: "education"),
(emoji: "🎥", word: "movie"),
(emoji: "🎼", word: "music"),
(emoji: "🔊", word: "sound"),
(emoji: "🦠", word: "virus"),
(emoji: "🌱", word: "nature"),
(emoji: "🌎", word: "world"),
(emoji: "🎉", word: "party"),
(emoji: "😨", word: "fear"),
(emoji: "👿", word: "evil"),
(emoji: "💩", word: "poo"),
(emoji: "🤡", word: "clown"),
(emoji: "👾", word: "invader"),
(emoji: "🤘", word: "rock"),
(emoji: "✋", word: "hand"),
(emoji: "👊", word: "fist"),
(emoji: "👐", word: "open"),
(emoji: "✍", word: "writing"),
(emoji: "💪", word: "strength"),
(emoji: "👃", word: "smell"),
(emoji: "👂", word: "hear"),
(emoji: "🧠", word: "brain"),
(emoji: "👀", word: "eyes"),
(emoji: "👁", word: "visual"),
(emoji: "👶", word: "baby"),
(emoji: "🧑", word: "person"),
(emoji: "👨", word: "man"),
(emoji: "👩", word: "woman"),
(emoji: "🧑‍⚖️", word: "judge"),
(emoji: "👨‍🌾", word: "farmer"),
(emoji: "🧑‍🔧", word: "worker"),
(emoji: "🧑‍🍳", word: "cook"),
(emoji: "🧑‍🔬", word: "scientist"),
(emoji: "🧑‍💻", word: "technologist"),
(emoji: "🧑‍🎨", word: "artist"),
(emoji: "🧑‍🚀", word: "astronaut"),
(emoji: "🕵", word: "detective"),
(emoji: "🤴", word: "prince"),
(emoji: "👸", word: "princess"),
(emoji: "👼", word: "angel"),
(emoji: "🦸", word: "superhero"),
(emoji: "🧙", word: "mage"),
(emoji: "🧞‍♂️", word: "genie"),
(emoji: "🚶", word: "walk"),
(emoji: "🏃", word: "running"),
(emoji: "💃", word: "dance"),
(emoji: "🧘", word: "meditation"),
(emoji: "👪", word: "family"),
(emoji: "🗣", word: "speaking"),
(emoji: "👣", word: "footprints"),
(emoji: "👕", word: "clothes"),
(emoji: "🎒", word: "backpack"),
(emoji: "👟", word: "footwear"),
(emoji: "👑", word: "crown"),
(emoji: "⛑", word: "rescue"),
(emoji: "💼", word: "work"),
(emoji: "🩸", word: "blood"),
(emoji: "💣", word: "bomb"),
(emoji: "🛌", word: "sleep"),
(emoji: "⏳", word: "time"),
(emoji: "🧭", word: "compass"),
(emoji: "🗺", word: "map"),
(emoji: "🏺", word: "amphora"),
(emoji: "🌡", word: "thermometer"),
(emoji: "🎈", word: "ballon"),
(emoji: "🎁", word: "gift"),
(emoji: "🔮", word: "magic"),
(emoji: "🕹", word: "joystick"),
(emoji: "🖼", word: "picture"),
(emoji: "💎", word: "gem"),
(emoji: "🎙", word: "microphone"),
(emoji: "📻", word: "radio"),
(emoji: "💻", word: "computer"),
(emoji: "🎞", word: "film"),
(emoji: "📷", word: "camera"),
(emoji: "🔍", word: "search"),
(emoji: "💡", word: "idea"),
(emoji: "📚", word: "books"),
(emoji: "💰", word: "money"),
(emoji: "📦", word: "package"),
(emoji: "✏", word: "pencil"),
(emoji: "📅", word: "calendar"),
(emoji: "📊", word: "statistics"),
(emoji: "🗂", word: "folders"),
(emoji: "📐", word: "measure"),
(emoji: "🔑", word: "key"),
(emoji: "🛠", word: "tools"),
(emoji: "🧰", word: "toolbox"),
(emoji: "🛡", word: "protection"),
(emoji: "⚙", word: "gear"),
(emoji: "⚖", word: "balance"),
(emoji: "🔗", word: "link"),
(emoji: "⛓", word: "chains"),
(emoji: "🧲", word: "magnet"),
(emoji: "🧪", word: "test"),
(emoji: "🧬", word: "DNA"),
(emoji: "🔬", word: "microscope"),
(emoji: "🔭", word: "telescope"),
(emoji: "📡", word: "antenna"),
(emoji: "💊", word: "drugs"),
(emoji: "🚬", word: "cigarette"),
(emoji: "⚰", word: "coffin"),
(emoji: "🍏", word: "fruits"),
(emoji: "🥦", word: "vegetables"),
(emoji: "🥚", word: "egg"),
(emoji: "🐔", word: "chicken"),
(emoji: "🍿", word: "popcorn"),
(emoji: "🍪", word: "cookie"),
(emoji: "🍷", word: "wine"),
(emoji: "🍺", word: "beer"),
(emoji: "🧊", word: "ice"),
(emoji: "🏁", word: "finish"),
(emoji: "🚩", word: "flag"),
(emoji: "❤", word: "love"),
(emoji: "💭", word: "thought"),
(emoji: "🛑", word: "stop"),
(emoji: "🌀", word: "spiral"),
(emoji: "⚠", word: "warning"),
(emoji: "🚫", word: "prohibited"),
(emoji: "☢", word: "radiation"),
(emoji: "⬆", word: "up"),
(emoji: "⬇", word: "down"),
(emoji: "🕉", word: "om"),
(emoji: "☯", word: "zen"),
(emoji: "☮", word: "peace"),
(emoji: "🔁", word: "repaet"),
(emoji: "🔀", word: "random"),
(emoji: "♾", word: "infinity"),
(emoji: "❔", word: "question"),
(emoji: "❕", word: "exclamation"),
(emoji: "〰", word: "wave"),
(emoji: "♻", word: "recycling"),
(emoji: "✅", word: "done"),
(emoji: "©", word: "copyright"),
(emoji: "⭕", word: "circle"),
(emoji: "🔢", word: "numbers"),
(emoji: "🔠", word: "letters"),
(emoji: "ℹ", word: "information"),
(emoji: "🆗", word: "OK"),
(emoji: "🔘", word: "button"),
(emoji: "🏕", word: "camping"),
(emoji: "🏠", word: "house"),
(emoji: "🏦", word: "bank"),
(emoji: "🏥", word: "hospital"),
(emoji: "🏭", word: "factory"),
(emoji: "🏰", word: "custle"),
(emoji: "⛲", word: "fountain"),
(emoji: "🚌", word: "bus"),
(emoji: "🚔", word: "police"),
(emoji: "🚕", word: "taxi"),
(emoji: "🚗", word: "automobile"),
(emoji: "🏎", word: "racing"),
(emoji: "🏍", word: "motorcycle"),
(emoji: "🚲", word: "bicycle"),
(emoji: "🚦", word: "traffic"),
(emoji: "⚓", word: "anchor"),
(emoji: "🚢", word: "ship"),
(emoji: "✈", word: "airplane"),
(emoji: "🪂", word: "parachute"),
(emoji: "🚁", word: "helicopter"),
(emoji: "🛰", word: "satellite"),
(emoji: "🚀", word: "rocket"),
(emoji: "🪐", word: "cosmos"),
]


extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}


// MARK: - For saving embeddings in JSON

//    func saveEmojiEmbeddings() {
//        // install package ---> https://github.com/SwiftyJSON/SwiftyJSON
//        let emojiWords = emojiDict.map { $0.word }
//        print(emojiWords)
//        self.showSpinner()
//        DispatchQueue.global(qos: .userInitiated).async {
//            let embeddings = self.bert.getKeywordsEmbeddings(keywords: emojiWords)
//            DispatchQueue.main.async {
//                print("🎉 EmojiEmbiddings calculations DONE!")
//                print(embeddings[0])
//                let json = JSON(embeddings)
//                let string = json.description
//                let filename = self.getDocumentsDirectory().appendingPathComponent("emojiEmbeddings.json")
//
//                do {
//                    try string.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
//                } catch {
//                    print("Failed to write a JSON file.")
//                }
//                self.removeSpinner()
//            }
//        }
//    }
//
//    func getDocumentsDirectory() -> URL {
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        print("🗂 Local file folder for Simulator: \(paths[0])")
//        return paths[0]
//    }
