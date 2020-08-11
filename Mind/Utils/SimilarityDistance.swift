//
//  Math.swift
//  Mind
//
//  Created by Anton Evstigneev on 16.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation


public func SimilarityDistance(A: [Float], B: [Float]) -> Float {

    // Dot Product
    func dot(A: [Float], B: [Float]) -> Float {
        var x: Float = 0
        for i in 0...A.count-1 {
            x += A[i] * B[i]
        }
        return x
    }

    // Vector Magnitude
    func magnitude(A: [Float]) -> Float {
        var x: Float = 0
        for elt in A {
            x += elt * elt
        }
        return sqrt(x)
    }

    // Cosine similarity
    func cosineSimilarity(A: [Float], B: [Float]) -> Float {
        return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
    }
    
    return cosineSimilarity(A: A, B: B)
}


public func EuclideanDistance(A: [Float], B: [Float]) -> Float {
    var sum: Float = 0
    let sA = A.std()
    let sB = B.std()
    
    for i in 0...A.count-1 {
        sum += (A[i]/sA - B[i]/sB) * (A[i]/sA - B[i]/sB)
    }
    
    return sqrt(sum)
}


extension Array where Element: FloatingPoint {
    
    func sum() -> Element {
        return self.reduce(0, +)
    }
    
    func avg() -> Element {
        return self.sum() / Element(self.count)
    }
    
    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
}
