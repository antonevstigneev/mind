
import CoreML

struct BERTInput {
    /// The maximum number of tokens the BERT model can process.
    static let maxTokens = 512
    
    // There are 2 sentinel tokens before the document, 1 [CLS] token and 1 [SEP] token.
    static let documentTokenOverhead = 2
    
    // There are 3 sentinel tokens total, 1 [CLS] token and 2 [SEP] tokens.
    static let totalTokenOverhead = 3

    var modelInput: distilbert_base_nliInput?
    
    var wordIDs = [BERTVocabulary.classifyStartTokenID]

    let document: TokenizedString

    private let documentOffset: Int

    var documentRange: Range<Int> {
        return documentOffset..<documentOffset + document.tokens.count
    }
    
    var totalTokenSize: Int {
        return BERTInput.totalTokenOverhead + document.tokens.count
    }
    
    /// - Tag: BERTInputInitializer
    init(documentString: String) {
        document = TokenizedString(documentString)

        // Save the number of tokens before the document tokens for later.
        documentOffset = BERTInput.documentTokenOverhead
        
        guard totalTokenSize < BERTInput.maxTokens else {
            return
        }
        
        // Start the wordID array with the `classification start` token.
        wordIDs = [BERTVocabulary.classifyStartTokenID]
        
        // Add the document tokens and a separator.
        wordIDs += document.tokenIDs
        wordIDs += [BERTVocabulary.separatorTokenID]
        
        
        let inputShape = [1, NSNumber(value: wordIDs.count)]
        let tokenIDMultiArray = try? MLMultiArray(shape: inputShape,
                                                  dataType: .int32)

        
//        // Unwrap the MLMultiArray optionals.
        guard let tokenIDInput = tokenIDMultiArray else {
            fatalError("Couldn't create wordID MLMultiArray input")
        }
        
//         Copy the Swift array contents to the MLMultiArrays.
        for (index, identifier) in wordIDs.enumerated() {
            tokenIDInput[index] = NSNumber(value: identifier)
        }

        // Create the BERT input MLFeatureProvider.
        let modelInput = distilbert_base_nliInput(input_ids: tokenIDInput)
        self.modelInput = modelInput
    }
}
