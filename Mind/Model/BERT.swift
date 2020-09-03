/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Wrapper class for the BERT model that handles its input and output.
*/

import CoreML

class BERT {
    
    /// The underlying Core ML Model.
    let model = distilbert_base_nli()

    public func getTextEmbedding(text: String) -> [Float] {
        // Prepare the input for the BERT model.
        let bertInput = BERTInput(documentString: text)
        
        // The MLFeatureProvider that supplies the BERT model with its input MLMultiArrays.
        let modelInput = bertInput.modelInput!
        
        let options = MLPredictionOptions()
        options.usesCPUOnly = true // Can't use GPU in the background
        
        // Make a prediction with the BERT model.
        let embeddings = try? model.prediction(input: modelInput, options: options)
        
        var cls_embeddings_arr = [Float]()
        
        for n in 0...767 {
            cls_embeddings_arr.append(Float(truncating: embeddings!.output[n]))
        }
        
        return cls_embeddings_arr
    }
    
    public func getKeywordsEmbeddings(keywords: [String]) -> [[Float]] {
        var keywordsEmbeddings: [[Float]] = []
        
        for keyword in keywords {
            let keywordEmbedding = self.getTextEmbedding(text: keyword)
            keywordsEmbeddings.append(keywordEmbedding)
        }
        return keywordsEmbeddings
    }
    
}


