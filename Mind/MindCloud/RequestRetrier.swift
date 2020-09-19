//
//  RequestRetrier.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Alamofire


class NetworkRequestRetrier: RequestRetrier {
    
    private let retryLimit = 3
    private let timeDelay = 1.0
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let statusCode = request.response?.statusCode else {
            completion(.doNotRetry)
            return
        }
        
        switch statusCode {
        case 200...299:
            completion(.doNotRetry)
        default:
            completion(.retry)
        }
    }
}


