//
//  Math.swift
//  Mind
//
//  Created by Anton Evstigneev on 16.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

func SimilarityDistance(A: [Float], B: [Float]) -> Float {

    /** Dot Product **/
    func dot(A: [Float], B: [Float]) -> Float {
        var x: Float = 0
        for i in 0...A.count-1 {
            x += A[i] * B[i]
        }
        return x
    }

    /** Vector Magnitude **/
    func magnitude(A: [Float]) -> Float {
        var x: Float = 0
        for elt in A {
            x += elt * elt
        }
        return sqrt(x)
    }

    /** Cosine similarity **/
    func cosineSimilarity(A: [Float], B: [Float]) -> Float {
        return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
    }
    
    
    return cosineSimilarity(A: A, B: B)
}

