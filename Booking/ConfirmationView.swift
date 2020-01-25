//
//  ConfirmationViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase

class ConfirmationView: UIViewController {
    
    var alert: UIAlertController?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var serviceLabel: UILabel!
    
    @IBOutlet weak var locationTitleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var cancellationPolicyLabel: UILabel!
    @IBOutlet weak var cancellationPolicyLabelHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var confirmAppointmentButton: UIButton!
    @IBAction func confirmAppointmentButton(_ sender: Any) {
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        confirmAppointmentButton.isUserInteractionEnabled = false
        
        CustomerAPI().createAppointment(methodCompletion: { (success, error) -> Void in
            
            guard success else {
                print("Failure to Create Appointment: \(error)")
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.activityIndicator.isHidden = true
                
                    if error == "We're sorry, but the appointment time you requested is no longer available." {
                        self.alert = UIAlertController(title: "uh oh!", message: error.lowercased(), preferredStyle: .alert)
                        self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: { Void in 
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(self.alert!, animated: true, completion: nil)
                    } else {
                        self.alert = UIAlertController(title: "uh oh!", message: "something went wrong, please try again later", preferredStyle: .alert)
                        self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(self.alert!, animated: true, completion: nil)
                    }
                }
                return
            }
            
            guard Customer.appointmentToCancelID == nil else {
                CustomerAPI().cancelAppointment(methodCompletion: { (success, error) -> Void in
                    guard success else {
                        print("Failure to Cancel Appointment: \(error)")
                        self.alert = UIAlertController(title: "hmm..", message: "your appointment has NOT been successfully cancelled (something went wrong), but a new one has been booked. please make sure to cancel your previous appointment", preferredStyle: .alert)
                        self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        DispatchQueue.main.async {
                            self.present(self.alert!, animated: true, completion: nil)
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                        return
                    }
                    
                    Customer.appointmentToCancelID = nil
                    self.alert = UIAlertController(title: "yay!", message: "your appointment has been successfully modified", preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) -> Void in
                        DispatchQueue.main.async { self.performSegue(withIdentifier: "toConfirmedSegue", sender: nil) }
                    }))
                    DispatchQueue.main.async {
                        self.present(self.alert!, animated: true, completion: nil)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    Customer.appointmentModified = true //sets up the base AppointmentDetail view to be dismissed immediately
                })
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.performSegue(withIdentifier: "toConfirmedSegue", sender: nil)
            }

        })
    }
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("ConfirmationView", screenClass: "app")
        activityIndicator.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton: UIButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back_arrow"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        backButton.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.navigationItem.leftBarButtonItems = [backBarButton]
        
        serviceLabel.text = ""
        var treatmentCount = AppointmentSearch.selectedServices.count
        for service in AppointmentSearch.selectedServices {
            serviceLabel.text?.append(service.name.uppercased())
            treatmentCount -= 1
            if treatmentCount != 0 { serviceLabel.text?.append("\n") }
        }
    
        locationImageView.image = AppointmentSearch.location!.image
        
        locationTitleLabel.text = "\(AppointmentSearch.location!.name)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        let dateString = dateFormatter.string(from: AppointmentSearch.appointmentSelected!.startDateTime)
        dateLabel.text = dateString
        
        timeLabel.text = "\(AppointmentSearch.appointmentSelected!.startTimeHuman) - \(AppointmentSearch.appointmentSelected!.endTimeHuman)"
        
        priceLabel.text = "$\(AppointmentSearch.availableAppointmentsPrice)"
        
        
        //fixing the text size of the cancellation policy on a device dependent basis
        switch UIScreen.main.nativeBounds.height {
        case 2436, 2688: //iPhone X, Xs, XsMax
            cancellationPolicyLabelHeight.constant += 80
            cancellationPolicyLabel.font = UIFont(name: cancellationPolicyLabel.font.fontName, size: cancellationPolicyLabel.font.pointSize + 2)
        default: //other devices with no changes needed
            break
        }
        
    
    }
}
