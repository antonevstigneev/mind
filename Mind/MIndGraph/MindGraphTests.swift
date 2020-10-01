//
//  MindGraphTests.swift
//  Mind
//
//  Created by Anton Evstigneev on 01.10.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation

func testAdjacencyMatrixGraphDescription() {
    
    let graph = AdjacencyMatrixGraph<Int>()
    
    let verticesCount = 10
    var vertices: [Vertex<Int>] = []
    
    for i in 0..<verticesCount {
        vertices.append(graph.createVertex(i))
    }
    
    for i in 0..<verticesCount {
        for j in i+1..<verticesCount {
            graph.addDirectedEdge(vertices[i], to: vertices[j], withWeight: Double.random(in: 0..<1))
        }
    }
    
    print(graph.description)
    print(graph.edges)
    print(graph.vertices)
}
