//
//  NotificationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/23/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import UIKit
import OneSignal
import FirebaseAnalytics

class NotificationPermissionRequestView: UIViewController {
 
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    @IBAction func denyButton(_ sender: Any) {
        
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .homeViewDidBecomeVisible, object: nil)
        }

    }
    
    @IBAction func acceptButton(_ sender: Any) {
        OneSignal.promptForPushNotifications(userResponse: { response in
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: .homeViewDidBecomeVisible, object: nil)
            }
            OneSignal.sendTags(["customerID": Customer.id])
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Analytics.setScreenName("NotificationPermissionView", screenClass: "app")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        background.layer.cornerRadius = 10
        background.layer.masksToBounds = true
        background.layer.borderColor = Design.Colors.brown.cgColor
        background.layer.borderWidth = 1.0
        
        acceptButton.layer.cornerRadius = 4
        acceptButton.layer.masksToBounds = true
        acceptButton.layer.borderColor = Design.Colors.brown.cgColor
        acceptButton.layer.borderWidth = 1.0
        
        denyButton.layer.cornerRadius = 4
        denyButton.layer.masksToBounds = true
        denyButton.layer.borderColor = Design.Colors.brown.cgColor
        denyButton.layer.borderWidth = 1.0
        
    }
   
}
