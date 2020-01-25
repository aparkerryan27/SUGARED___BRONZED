//
//  LocationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase

class CancelOptionsView: UIViewController {
    
    var membership: Membership? = nil
    
    var reasons = ""
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    var accepted: Bool?
    
    @IBAction func denyButton(_ sender: Any) {
        
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .backToProfile, object: nil)
        }
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        reasons = ""
        if workButton.isSelected {
            reasons += "-WORK-"
        }
        if educationButton.isSelected {
            reasons += "-EDUCATION-"
        }
        if travelButton.isSelected {
            reasons += "-TRAVEL-"
        }
        if expenseButton.isSelected {
            reasons += "-EXPENSIVE-"
        }
        if otherButton.isSelected {
            reasons += "-OTHER-"
        }
        
        guard reasons != "" else {
            let reasonAlert = UIAlertController(title: "uh oh!", message: "looks like you've forgotten to select a reason", preferredStyle: .alert)
            reasonAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(reasonAlert, animated: true)
            return
        }
        
        sendMembershipEmail(type: .cancel, membership: membership!, reason: reasons)
        
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .backToProfile, object: nil) /* CURRENTLY NOT DOING ANYTHING WITH THIS */
        }
    }
    
    @IBOutlet weak var workButton: UIButton!
    @IBAction func workButton(_ sender: Any) {
        workButton.isSelected = !workButton.isSelected
    }
    
    @IBOutlet weak var educationButton: UIButton!
    @IBAction func educationButton(_ sender: Any) {
        educationButton.isSelected = !educationButton.isSelected
         
    }
    
    @IBOutlet weak var travelButton: UIButton!
    @IBAction func travelButton(_ sender: Any) {
        travelButton.isSelected = !travelButton.isSelected
    }
    
    @IBOutlet weak var expenseButton: UIButton!
    @IBAction func expenseButton(_ sender: Any) {
        expenseButton.isSelected = !expenseButton.isSelected
    }
    
    @IBOutlet weak var otherButton: UIButton!
    @IBAction func otherButton(_ sender: Any) {
        otherButton.isSelected = !otherButton.isSelected
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Analytics.setScreenName("CancelOptionsView", screenClass: "app")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        background.layer.cornerRadius = 10
        background.layer.masksToBounds = true
        background.layer.borderColor = Design.Colors.blue.cgColor
        background.layer.borderWidth = 1.0
        
        acceptButton.layer.cornerRadius = 4
        acceptButton.layer.masksToBounds = true
        acceptButton.layer.borderColor = Design.Colors.blue.cgColor
        acceptButton.layer.borderWidth = 1.0
        
        denyButton.layer.cornerRadius = 4
        denyButton.layer.masksToBounds = true
        denyButton.layer.borderColor = Design.Colors.blue.cgColor
        denyButton.layer.borderWidth = 1.0
        
        workButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        workButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        educationButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        educationButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        expenseButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        expenseButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        travelButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        travelButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        otherButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        otherButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        
    }
    
}
