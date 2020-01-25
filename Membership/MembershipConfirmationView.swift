//
//  MembershipConfirmationView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase
import SafariServices

class MembershipConfirmationView: UIViewController {
    
    var alert: UIAlertController?
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var membershipNameLabel: UILabel!
    @IBOutlet weak var membershipNameLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var membershipPriceLabel: UILabel!
    @IBOutlet weak var membershipQuantityLabel: UILabel!
    @IBOutlet weak var membershipDescriptionLabel: UILabel!
    
    @IBOutlet weak var agreementButton1: UIButton!
    @IBAction func agreementButton1(_ sender: Any) {
        agreementButton1.isSelected = !agreementButton1.isSelected
        if agreementButton1.isSelected && agreementButton2.isSelected && agreementButton3.isSelected && agreementButton4.isSelected  {
            confirmButton.isHidden = false
            confirmButtonSpacer.isHidden = false
        } else {
            confirmButton.isHidden = true
            confirmButtonSpacer.isHidden = true
        }
    }
    @IBOutlet weak var agreementButton2: UIButton!
    @IBAction func agreementButton2(_ sender: Any) {
        agreementButton2.isSelected = !agreementButton2.isSelected
        if agreementButton1.isSelected && agreementButton2.isSelected && agreementButton3.isSelected && agreementButton4.isSelected  {
            confirmButton.isHidden = false
            confirmButtonSpacer.isHidden = false
        } else {
            confirmButton.isHidden = true
            confirmButtonSpacer.isHidden = true
        }
    }
    @IBOutlet weak var agreementButton3: UIButton!
    @IBAction func agreementButton3(_ sender: Any) {
        agreementButton3.isSelected = !agreementButton3.isSelected
        if agreementButton1.isSelected && agreementButton2.isSelected && agreementButton3.isSelected && agreementButton4.isSelected  {
            confirmButton.isHidden = false
            confirmButtonSpacer.isHidden = false
        } else {
            confirmButton.isHidden = true
            confirmButtonSpacer.isHidden = true
        }
    }
    @IBOutlet weak var agreementButton4: UIButton!
    @IBAction func agreementButton4(_ sender: Any) {
        agreementButton4.isSelected = !agreementButton4.isSelected
        if agreementButton1.isSelected && agreementButton2.isSelected && agreementButton3.isSelected && agreementButton4.isSelected  {
            confirmButton.isHidden = false
            confirmButtonSpacer.isHidden = false
        } else {
            confirmButton.isHidden = true
            confirmButtonSpacer.isHidden = true
        }
    }
    
    @IBOutlet weak var termsButton: UIButton!
    @IBAction func termsButton(_ sender: Any) {
        
//TODO: FIX THIS URL
        let url = URL(string: "https://waiver.smartwaiver.com/w/5b6d3cd3d4123/web/")!
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var confirmButtonSpacer: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBAction func confirmButton(_ sender: Any) {
        
        guard Customer.age >= 18 else {
            self.alert = UIAlertController(title: "uh oh!", message: "you must be 18 or older to sign up for a membership. if you need to fix your date of birth please visit the EDIT PROFILE section of the app, otherwise, please have an adult purchase the membership for you!", preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(self.alert!, animated: true, completion: nil)
            return
        }
        
        guard agreementButton1.isSelected  && agreementButton2.isSelected && agreementButton3.isSelected && agreementButton4.isSelected else {
            self.alert = UIAlertController(title: "uh oh!", message: "please agree to all terms by selecting the checkboxes", preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(self.alert!, animated: true, completion: nil)
            return
        }
        
        performSegue(withIdentifier: "toPaymentViewSegue", sender: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("MembershipConfirmationView", screenClass: "app")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.isHidden = true
        confirmButtonSpacer.isHidden = true
        
        agreementButton1.setImage(UIImage(named: "agreement_checked"), for: .selected)
        agreementButton1.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        agreementButton2.setImage(UIImage(named: "agreement_checked"), for: .selected)
        agreementButton2.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        agreementButton3.setImage(UIImage(named: "agreement_checked"), for: .selected)
        agreementButton3.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        agreementButton4.setImage(UIImage(named: "agreement_checked"), for: .selected)
        agreementButton4.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        
        var totalPrice = 0
        var totalBenefits = 0
        var membershipNames = ""
        var numMemberships = MembershipPurchase.membershipsSelected.count
        
        for membership in MembershipPurchase.membershipsSelected {
            if MembershipPurchase.location!.upcharge {
                totalPrice += membership.priceNYC
            } else {
                totalPrice += membership.priceWest
            }
            
            membershipNames.append(membership.name)
            if numMemberships > 1 {
                membershipNames.append(", \n")
                membershipNameLabelHeight.constant += 30
                numMemberships -= 1
            }
            totalBenefits += membership.quantityOfBenefits()
        }
        
        membershipNameLabel.text = membershipNames
        membershipPriceLabel.text = "∙ $\(totalPrice) ∙"
        membershipQuantityLabel.text = "\(totalBenefits) benefit(s) per month"
        
        if MembershipPurchase.membershipsSelected.count == 1 {
            membershipDescriptionLabel.text = MembershipPurchase.membershipsSelected.first!.description
        } else {
            membershipDescriptionLabel.text = ""
        }
        
      
    }
    
}
