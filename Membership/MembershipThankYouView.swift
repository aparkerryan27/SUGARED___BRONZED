//
//  MembershipThankYouView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase

class MembershipThankYouView: UIViewController {
    
    var alert: UIAlertController?
    
  
    @IBOutlet weak var confirmButtonSpacer: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBAction func confirmButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.navigationController!.popToRootViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        for membership in MembershipPurchase.membershipsSelected {
            sendMembershipEmail(type: .purchase, membership: membership, reason: "")
        }
        
        MembershipPurchase.membershipsSelected = []
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("MembershipThankYouView", screenClass: "app")
        
        //MARK: - Set Observers
        NotificationCenter.default.addObserver(self, selector: #selector(presentAlert), name: .alertToPresent, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func presentAlert(notification: Notification) {
        DispatchQueue.main.async {
            let info = notification.userInfo as! [String: Any]
            
            guard info["success"] as! Bool else {
                let alert = UIAlertController(title: "uh oh!", message: "it seems there was an issue sending your request. please try again later or contact membership@sugaredandbronzed.com", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let alert = UIAlertController(title: "all set!", message: "your membership change request has been sent in, and you should see the changes on your account within the next 30 days. if you have any questions, concerns, or issues, please contact membership@sugaredandbronzed.com", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

