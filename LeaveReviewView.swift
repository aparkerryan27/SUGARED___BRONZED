//
//  LeaveReviewView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/19.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase
import NVActivityIndicatorView

class LeaveReviewView: UIViewController, UITextFieldDelegate {
    
    
    var rating = 3
    var activityIndicatorContainerView: UIView? = nil
    var activityIndicator: NVActivityIndicatorView? = nil
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var servicesField: UITextField!
    
    @IBOutlet weak var locationField: UITextField!
    
    @IBOutlet weak var reviewField: UITextField!
    
    @IBOutlet weak var ratingField: UITextField!
    
    @IBOutlet weak var star1: UIButton!
    @IBAction func star1(_ sender: Any) {
        guard star1.isSelected else {
            star1.isSelected = true
            rating = 1
            ratingField.text = "1/5"
            return
        }
        rating = 0
        ratingField.text = "0/5"
        star1.isSelected = false
        star2.isSelected = false
        star3.isSelected = false
        star4.isSelected = false
        star5.isSelected = false
    }
    
    @IBOutlet weak var star2: UIButton!
    @IBAction func star2(_ sender: Any) {
        guard star2.isSelected else {
            star1.isSelected = true
            star2.isSelected = true
            rating = 2
            ratingField.text = "2/5"
            return
        }
        rating = 1
        ratingField.text = "1/5"
        star2.isSelected = false
        star3.isSelected = false
        star4.isSelected = false
        star5.isSelected = false
    }
    
    @IBOutlet weak var star3: UIButton!
    @IBAction func star3(_ sender: Any) {
        guard star3.isSelected else {
            star1.isSelected = true
            star2.isSelected = true
            star3.isSelected = true
            rating = 3
            ratingField.text = "3/5"
            return
        }
        rating = 2
        ratingField.text = "2/5"
        star3.isSelected = false
        star4.isSelected = false
        star5.isSelected = false
    }
    
    @IBOutlet weak var star4: UIButton!
    @IBAction func star4(_ sender: Any) {
        guard star4.isSelected else {
            star1.isSelected = true
            star2.isSelected = true
            star3.isSelected = true
            star4.isSelected = true
            rating = 4
            ratingField.text = "4/5"
            return
        }
        rating = 3
        ratingField.text = "3/5"
        star4.isSelected = false
        star5.isSelected = false
    }
    
    @IBOutlet weak var star5: UIButton!
    @IBAction func star5(_ sender: Any) {
        guard star5.isSelected else {
            star1.isSelected = true
            star2.isSelected = true
            star3.isSelected = true
            star4.isSelected = true
            star5.isSelected = true
            rating = 5
            ratingField.text = "5/5"
            return
        }
        rating = 4
        ratingField.text = "4/5"
        star5.isSelected = false
    }
    
    
    
    
    
    @IBOutlet weak var leaveReviewButton: UIButton!
    @IBAction func leaveReviewButton(_ sender: Any) {
    
        self.view.endEditing(true)
 
        guard activityIndicator!.isHidden == true else {
            return
        }
        
        activityIndicator!.isHidden = false
        activityIndicatorContainerView!.isHidden = false
        
        //for 3 or below stars, force a written review alongside!!
        
        
        guard reviewField.text != nil && reviewField.text!.count > 0 && reviewField.text!.count < 300 else {
            print("insufficient review!")
            return
        }
        
        //reviewField.text = reviewField.text .  removing ( ; and other mysql stuff)
        
        let reviewParams: [String : Any] = ["access_key": "PP2017srvrp455w0rdkEY", "EmployeeID": Customer.employeeID!, "EmployeeName": Customer.employeeName, "Rating": rating, "Review": reviewField.text!, "CustomerID": Customer.id, "CustomerFirst": Customer.firstName, "CustomerLast": Customer.lastName, "CustomerPhone": Customer.phoneNumber, "Location": Customer.locationID!]
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Requests().POST(url: "https://sugaredandbronzed.com/employeeReviews.php", parameters: reviewParams, headerType: "sugaredandbronzed") { (success, data, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.activityIndicator!.isHidden = true
                self.activityIndicatorContainerView!.isHidden = true
            }
            
            guard success else {
                print("Error sending Review to Server: \(error ?? "error")")
                return
            }
            
        }
    }
    
    @IBOutlet weak var refuseButton: UIButton!
    @IBAction func refuseButton(_ sender: Any) {
        self.view.endEditing(true)
        //dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("LeaveReviewView", screenClass: "app")
        
        activityIndicatorContainerView!.center = view.center
        activityIndicator!.center = activityIndicatorContainerView!.center
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        activityIndicatorContainerView!.center = view.center
        activityIndicatorContainerView!.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
        activityIndicatorContainerView!.layer.cornerRadius = 4
        activityIndicatorContainerView!.layer.masksToBounds = true
        self.view.addSubview(activityIndicatorContainerView!)
        
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: view.center.x - 30, y: view.center.y-20, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(activityIndicator!)
        
        activityIndicator!.startAnimating()
        activityIndicator!.isHidden = false
        activityIndicatorContainerView!.isHidden = false
        
        leaveReviewButton.layer.cornerRadius = 4
        leaveReviewButton.layer.masksToBounds = true
        leaveReviewButton.layer.borderColor = Design.Colors.brown.cgColor
        leaveReviewButton.layer.borderWidth = 1.0
        
        reviewField.delegate = self
        
        star1.setImage(UIImage(named: "star-regular"), for: .selected)
        star1.setImage(UIImage(named: "star-empty"), for: .normal)
        star2.setImage(UIImage(named: "star-regular"), for: .selected)
        star2.setImage(UIImage(named: "star-empty"), for: .normal)
        star3.setImage(UIImage(named: "star-regular"), for: .selected)
        star3.setImage(UIImage(named: "star-empty"), for: .normal)
        star4.setImage(UIImage(named: "star-regular"), for: .selected)
        star4.setImage(UIImage(named: "star-empty"), for: .normal)
        star5.setImage(UIImage(named: "star-regular"), for: .selected)
        star5.setImage(UIImage(named: "star-empty"), for: .normal)
        
        star1.isSelected = true
        star2.isSelected = true
        star3.isSelected = true
        ratingField.text = "3/5"
        
        guard Customer.orderID != nil else {
            print("no data from OneSignal, missing Customer.orderID")
            self.activityIndicator!.isHidden = true
            self.activityIndicatorContainerView!.isHidden = true
            dismiss(animated: true, completion: nil)
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CustomerAPI().getOrder { (success, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.activityIndicator!.isHidden = true
                self.activityIndicatorContainerView!.isHidden = true
            }
            
            guard success else {
                print("failed getOrder on error: \(error)")
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            self.locationField.text = "@ \(SugaredAndBronzed.locations[Customer.locationID!]!.name)"
            self.nameField.text = "How was your service with \(Customer.employeeName)?"
            //self.serviceLabel.text = "Service: \(Customer.services.first.name)"
    
        }
        
    }
    
}

