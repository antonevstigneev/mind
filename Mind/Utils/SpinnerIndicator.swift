//
//  SpinnerIndicator.swift
//  Mind
//
//  Created by Anton Evstigneev on 26.06.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import UIKit

fileprivate var aView: UIView?
fileprivate let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)

extension UIViewController {

    func showSpinner() {
        aView = UIView(frame: self.view.bounds)
        
        impactFeedbackgenerator.prepare()
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = CGPoint(x: 45, y: 25)
        activityIndicator.startAnimating()
        aView?.addSubview(activityIndicator)
        self.view.addSubview(aView!)
    }
    
    func removeSpinner() {
        aView?.removeFromSuperview()
        aView = nil
        impactFeedbackgenerator.impactOccurred()
    }
}
