//
//  Animations.swift
//  Mind
//
//  Created by Anton Evstigneev on 15.07.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import Foundation
import UIKit


// MARK: - UIButton Show/Hide
public extension UIButton {

    func show() {
        self.isHidden = false
        self.isEnabled = true
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.alpha = 1
        }, completion: nil)
    }
    
    func hide() {
        self.isHidden = false
        self.isEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.alpha = 0.0
        }, completion: nil)
    }
}


// MARK: - UITableView Show/Hide
public extension UITableView {
    
    func show() {
        self.alpha = 0
        UIView.animate(withDuration: 0.35, delay: 0.1, options: [.curveEaseInOut], animations: {
            self.alpha = 1
        }, completion: nil)
    }
    
    func hide() {
        self.alpha = 1
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut], animations: {
            self.alpha = 0
        }, completion: nil)
    }
}


