//
//  Matrix.swift
//  Mind
//
//  Created by Anton Evstigneev on 04.08.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

struct Matrix {
    var rows: Int, columns: Int
    var grid: [Float]
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: 0.0, count: rows * columns)
    }
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> Float {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}

extension Matrix {
    
    func position(of value: Float) -> [(row: Int, column: Int)] {
        var valuePosition: [(row: Int, column: Int)] = []
        for row in 0..<self.rows {
            let thisRow = Array(self.grid[row*(self.columns)..<((row+1)*self.columns)])
            if thisRow.contains(value) {
                let column = thisRow.firstIndex(of: value)!
                valuePosition.append((row: row, column: column))
            }
        }
        return valuePosition
    }
    
    func getRowValues(_ rowIndex: Int) -> [Float] {
        return Array(self.grid[rowIndex*(self.columns)..<((rowIndex+1)*self.columns)])
    }
    
    func getColumnValues(_ columnIndex: Int) -> [Float] {
        return Array(self.grid[columnIndex*(self.rows)..<((columnIndex+1)*self.rows)])
    }
    
    func show() {
        for row in 0..<self.rows {
            let thisRow = Array(self.grid[row*(self.columns)..<((row+1)*self.columns)])
            print(thisRow, row)
        }
    }
    
    func arrays() -> [[Float]] {
        var matrixArrays: [[Float]] = []
        for row in 0..<self.rows {
            let thisRow = Array(self.grid[row*(self.columns)..<((row+1)*self.columns)])
            matrixArrays.append(thisRow)
        }
        return matrixArrays
    }
    
    mutating func remove(row: Int, column: Int) {
        var matrixArrays = self.arrays()
        
        for index in 0...matrixArrays.count-1 {
            matrixArrays[index].remove(at: column)
        }
        matrixArrays.remove(at: row)
        
        self.grid = matrixArrays.reduce([], +)
        self.rows = self.rows - 1
        self.columns = self.columns - 1
    }
}
