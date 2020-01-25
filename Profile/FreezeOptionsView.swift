//
//  LocationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase
import GMStepper

class FreezeOptionsView: UIViewController {
    
    var membership: Membership? = nil
    
    var medicalImageString: String? = nil
    
    var reasons = ""
    
    var accepted: Bool?
    
    var stepperValue = 1
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    @IBAction func denyButton(_ sender: Any) {
        
        //just send back to view
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
        if medicalButton.isSelected {
           reasons += "-MEDICAL (SEE NOTE)-"
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
        
        if self.medicalImageString == nil {
            sendMembershipEmail(type: .freeze, membership: self.membership!, freezeDuration: self.stepperValue, reason: self.reasons)
            
        } else {
            sendMembershipEmail(type: .freeze, membership: self.membership!, freezeDuration: self.stepperValue, medicalImageString: self.medicalImageString!, reason: self.reasons)
        }

        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .backToProfile, object: nil)
        }

       
    }
    
    @IBOutlet weak var durationStepper: GMStepper! {
        didSet {
            durationStepper.labelFont = UIFont(name: "AvenirNext-Medium", size: 12)!
        }
    }
    @IBAction func serviceQuantityStepper(_ sender: GMStepper) {
        stepperValue = Int(sender.value)
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
    
    @IBOutlet weak var otherButton: UIButton!
    @IBAction func otherButton(_ sender: Any) {
        otherButton.isSelected = !otherButton.isSelected
    }
    
    @IBOutlet weak var medicalButton: UIButton!
    @IBAction func medicalButton(_ sender: Any) {
        if medicalButton.isSelected {
            medicalButton.isSelected = false
            self.medicalImageString = ""
            self.durationStepper.maximumValue = 3
            self.durationStepper.value = 3
        } else {
            ImagePickerManager().pickImage(self){ image in
                
                //TODO: - make this compression quality specific to the actual size of the photo
                guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                    print("error - could not convert image to png data")
                    return
                }
                self.medicalImageString = imageData.base64EncodedString(options: .lineLength64Characters)
                print(self.medicalImageString!)
                self.medicalButton.isSelected = true
                self.durationStepper.maximumValue = 9
            }
            
        }
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Analytics.setScreenName("FreezeOptionsView", screenClass: "app")
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
        travelButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        travelButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        otherButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        otherButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        medicalButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        medicalButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
    }
    
}
