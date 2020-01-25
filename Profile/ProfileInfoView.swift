//
//  LocationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase
import SafariServices

class ProfileInfoView: UIViewController {

    
    let datePicker = UIDatePicker()
    var alert: UIAlertController?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBAction func firstNameField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var lastNameField: UITextField!
    @IBAction func lastNameField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var emailField: UITextField!
    @IBAction func emailField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var phoneField: UITextField!
    @IBAction func phoneField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var dobField: UITextField!
    @IBAction func dobField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var emailNotificationButton: UIButton!
    @IBAction func emailNotificationButton(_ sender: Any) {
        emailNotificationButton.isSelected = !emailNotificationButton.isSelected
    }
    
    @IBOutlet weak var textNotificationButton: UIButton!
    @IBAction func textNotificationButton(_ sender: Any) {
        textNotificationButton.isSelected = !textNotificationButton.isSelected

    }
    
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveButton(_ sender: Any) {

        self.view.endEditing(true)
        
        guard activityIndicator.isHidden == true else {
            //print("currently working on creating an account")
            return
        }
        
        
        guard firstNameField.text != nil && firstNameField.text != "" && !includesNumbersAndLetters(text: firstNameField.text!) else {
            firstNameField.text = ""
            self.alert = UIAlertController(title: "uh oh!", message: "your first name appears to be an invalid entry", preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(self.alert!, animated: true, completion: nil)
            return
        }
        
        guard (lastNameField.text != nil && lastNameField.text != "" && !includesNumbersAndLetters(text: lastNameField.text!)) else {
            lastNameField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your last name appears to be an invalid entry", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        
        guard (emailField.text != nil && emailField.text != "") && (emailField.text?.contains("@"))! && (emailField.text?.contains("."))! && (emailField.text?.count)! > 3 else {
            emailField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "it seems you have entered an invalid email. please try again", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
       
        //checking phone number for validity
        guard phoneField.text != nil && phoneField.text != "" && phoneField.text?.replacingOccurrences(of: " ", with: "", options:[], range: nil).count == 10 && !includesNumbersAndLetters(text: phoneField.text!) && Int(phoneField.text!) != nil else {
            alert = UIAlertController(title: "uh oh!", message: "your phone number appears to be an invalid entry. please use 10 numbers, no more no less, in the format: 0001114444", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        guard dobField.text != nil else {
            alert = UIAlertController(title: "uh oh!", message: "don't forget to fill in your date of birth!", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone =  TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.date(from: dobField.text!)
        guard date != nil else {
            print("error parsing date object from \(dobField.text!)")
            return
        }
        dateFormatter.dateFormat =  "yyyy-MM-dd'T'HH:mm:ssxxxxx"
        Customer.dobFormatted =  dateFormatter.string(from: date!)
        Customer.dob = dobField.text!
        
        Customer.firstName = firstNameField.text!
        Customer.lastName = lastNameField.text!
        Customer.email = emailField.text!
        Customer.phoneNumber = Int(phoneField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil))!
        
        Customer.allowRecieveEmails = emailNotificationButton.isSelected
        Customer.allowRecieveSMS = textNotificationButton.isSelected
    
        activityIndicator.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        CustomerAPI().updateInfo(methodCompletion: { (success, error) -> Void in
           
             DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.activityIndicator.isHidden = true
            }
            
            guard success else {
                print("Failed to update customer: \(error)")
                DispatchQueue.main.async {
                    self.alert = UIAlertController(title: "uh oh!", message: "it looks like there was a problem updating your information. please try again later!", preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(self.alert!, animated: true, completion: nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.alert = UIAlertController(title: "all set!", message: "your information has successfully updated!", preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(self.alert!, animated: true, completion: nil)
            }
        })
        
    }
    
    
    @IBAction func resetPassButton(_ sender: Any) {
        let url = URL(string: "https://go.booker.com/#/location/sbsantamonica/reset-password")!
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("ProfileInfoView", screenClass: "app")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.isHidden = true
        
        //Fill Fields
        firstNameField.text = Customer.firstName
        lastNameField.text = Customer.lastName
        emailField.text = Customer.email
        phoneField.text = "\(Customer.phoneNumber)"
        dobField.text = Customer.dob
        
        emailNotificationButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        emailNotificationButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        
        textNotificationButton.setImage(UIImage(named: "agreement_checked"), for: .selected)
        textNotificationButton.setImage(UIImage(named: "agreement_unchecked"), for: .normal)
        
        if Customer.allowRecieveEmails { emailNotificationButton.isSelected = true }
        if Customer.allowRecieveSMS { textNotificationButton.isSelected = true }

        //make allowRecievePromotionalEmails always the same as allowRecieveEmails
        
        
        saveButton.layer.cornerRadius = 4
        saveButton.layer.masksToBounds = true
        saveButton.layer.borderColor = Design.Colors.blue.cgColor
        saveButton.layer.borderWidth = 1.0
      
        //Format Date Picker
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        let toolbar = UIToolbar(); //Format Date Picker Toolbar
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker));
        toolbar.setItems([cancelButton,spaceButton,doneButton], animated: false)
        dobField.inputAccessoryView = toolbar
        dobField.inputView = datePicker
     
    }
    
    @objc func doneDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        dobField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker(){
        self.view.endEditing(true)
    }
}
