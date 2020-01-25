//
//  HomeScreenView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/20/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import UIKit

//MARK: - The Container for the Home and Menu Views in order to allow simultaneous presence on screen

class HomeContainerView: UIViewController {

    @IBOutlet weak var leftEdgeConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var menuWidth: NSLayoutConstraint!
    
    @IBOutlet weak var homePageWidth: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        homePageWidth.constant = self.view.frame.width
        menuWidth.constant = view.frame.width * 4/5
        leftEdgeConstraint.constant = menuWidth.constant * -1
        
    }
    
}
