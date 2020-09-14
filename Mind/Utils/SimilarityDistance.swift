//
//  Math.swift
//  Mind
//
//  Created by Anton Evstigneev on 16.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation


class Distance {
    
    private class func min(numbers: Int...) -> Int {
        return numbers.reduce(numbers[0]) {$0 < $1 ? $0 : $1}
    }
    
    class Array2D {
        var cols:Int, rows:Int
        var matrix: [Int]
        
        
        init(cols:Int, rows:Int) {
            self.cols = cols
            self.rows = rows
            matrix = Array(repeating:0, count:cols*rows)
        }
        
        subscript(col:Int, row:Int) -> Int {
            get {
                return matrix[cols * row + col]
            }
            set {
                matrix[cols*row+col] = newValue
            }
        }
        
        func colCount() -> Int {
            return self.cols
        }
        
        func rowCount() -> Int {
            return self.rows
        }
    }
    
    class func levenshtein(A: String, B: String) -> Int {
        let a = Array(A.utf16)
        let b = Array(B.utf16)
        
        let dist = Array2D(cols: a.count + 1, rows: b.count + 1)
        
        for i in 1...a.count {
            dist[i, 0] = i
        }
        
        for j in 1...b.count {
            dist[0, j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i, j] = dist[i-1, j-1]  // noop
                } else {
                    dist[i, j] = min(
                        numbers: dist[i-1, j] + 1,  // deletion
                        dist[i, j-1] + 1,  // insertion
                        dist[i-1, j-1] + 1  // substitution
                    )
                }
            }
        }
        
        return dist[a.count, b.count]
    }
    
    class func cosine(A: [Double], B: [Double]) -> Double {

        // Dot Product
        func dot(A: [Double], B: [Double]) -> Double {
            var x: Double = 0
            for i in 0...A.count-1 {
                x += A[i] * B[i]
            }
            return x
        }

        // Vector Magnitude
        func magnitude(A: [Double]) -> Double {
            var x: Double = 0
            for elt in A {
                x += elt * elt
            }
            return sqrt(x)
        }

        // Cosine similarity
        func cosineSimilarity(A: [Double], B: [Double]) -> Double {
            return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
        }
        
        return cosineSimilarity(A: A, B: B)
    }
    
    class func euclidean(A: [Double], B: [Double]) -> Double {
        var sum: Double = 0
        let sA = A.std()
        let sB = B.std()
        
        for i in 0...A.count-1 {
            sum += (A[i]/sA - B[i]/sB) * (A[i]/sA - B[i]/sB)
        }
        
        return sqrt(sum)
    }
    
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
