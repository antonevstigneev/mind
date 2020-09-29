//
//  NetworkState.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire


var connectivityTitle = "✅ Online"

class NetworkState {
    static let shared = NetworkState()
    let reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    func startNetworkReachabilityObserver() {
        reachabilityManager?.startListening(onUpdatePerforming: { status in
            switch status {
                            case .reachable:
                                print("✅ Online")
                                connectivityTitle = "✅ Online"
                            case .notReachable:
                                print("⚠️ Offline")
                                connectivityTitle = "⚠️ Offline"
                            case .unknown:
                                print("It is unknown whether the network is reachable")
            }
        })
    }
}
