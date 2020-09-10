//
//  appearanceViewController.swift
//  Mind
//
//  Created by Anton Evstigneev on 09.09.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit
import Foundation

class appearanceViewController: UIViewController {

    // MARK: - Variables
    var selectedInterfaceStyle: UIUserInterfaceStyle!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? itemsViewController {
            destinationVC.selectedInterfaceStyle = self.selectedInterfaceStyle
        }
    }
    

}
