//
//  LaunchVC.swift
//  Mind
//
//  Created by Anton Evstigneev on 18.04.2020.
//  Copyright © 2020 Anton Evstigneev. All rights reserved.
//

import UIKit

class launchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        performSegue(withIdentifier: "toItemsViewController", sender: self)
    }
    
}
