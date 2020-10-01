//
//  Edge.swift
//  Mind
//
//  Created by Anton Evstigneev on 01.10.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation


public struct Edge<T>: Equatable where T: Hashable {
    public let from: Vertex<T>
    public let to: Vertex<T>
    public let weight: Double?
}


public enum EdgeType {
    case directed, undirected
}


extension Edge: CustomStringConvertible {
    
    public var description: String {
        guard let unwrappedWeight = weight else {
            return "\(from.description) ––> \(to.description)"
        }
        return "\(from.description) ––(\(unwrappedWeight))––> \(to.description)"
    }
}


extension Edge: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(to)
        if weight != nil {
            hasher.combine(weight)
        }
    }
}


public func == <T>(lhs: Edge<T>, rhs: Edge<T>) -> Bool {
    guard lhs.from == rhs.from else {
        return false
    }
    
    guard lhs.to == rhs.to else {
        return false
    }
    
    guard lhs.weight == rhs.weight else {
        return false
    }
    
    return true
}
