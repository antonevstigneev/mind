//
//  NetworkState.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import Alamofire


class NetworkState {
    static let shared = NetworkState()
    let reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    func startNetworkReachabilityObserver() {
        reachabilityManager?.startListening(onUpdatePerforming: { status in
            print("🔐 Authorized: \(MindCloud.isUserAuthorized)")
            switch status {
                            case .reachable:
                                print("✅ Online")
                            case .notReachable:
                                print("⚠️ Offline")
                            case .unknown:
                                print("It is unknown whether the network is reachable")
            }
        })
    }
}
