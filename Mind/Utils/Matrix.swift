//
//  Matrix.swift
//  Mind
//
//  Created by Anton Evstigneev on 29.07.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Accelerate

typealias Matrix = Array<[Double]>

// Matrix Calculation

func matAdd(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecAdd(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matSub(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecSub(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matScale(mat:Matrix, num:Double) -> Matrix {
    let outputMatrix = mat.map({vecScale(vec: $0, num: num)})
    return outputMatrix
}

func transpose(inputMatrix: Matrix) -> Matrix {
    let m = Int(inputMatrix[0].count)
    let n = Int(inputMatrix.count)
    let t = inputMatrix.reduce([], {$0+$1})
    var result = Vector(repeating: 0.0, count: Int(m*n))
    vDSP_mtransD(t, 1, &result, 1, vDSP_Length(m), vDSP_Length(n))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(result[i*n..<i*n+n]))
    }
    return outputMatrix
}

func matMul(mat1:Matrix, mat2:Matrix) -> Matrix {
    if mat1.count != mat2[0].count {
        print("error")
        return []
    }
    let m = Int(mat1[0].count)
    let n = Int(mat2.count)
    let p = Int(mat1.count)
    var mulresult = Vector(repeating: 0.0, count: m*n)
    let mat1t = transpose(inputMatrix: mat1)
    let mat1vec = mat1t.reduce([], {$0+$1})
    let mat2t = transpose(inputMatrix: mat2)
    let mat2vec = mat2t.reduce([], {$0+$1})
    vDSP_mmulD(mat1vec, 1, mat2vec, 1, &mulresult, 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(p))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(mulresult[i*n..<i*n+n]))
    }
    return transpose(inputMatrix: outputMatrix)
}


// Covariance Matrix
func covarianceMatrix(inputMatrix:Matrix) -> Matrix {
    let t = transpose(inputMatrix: inputMatrix)
    return matMul(mat1: inputMatrix, mat2: t)
}



