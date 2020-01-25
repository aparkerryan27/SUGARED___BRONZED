//
//  CreateAccountView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase

class CreateAccountView: UIViewController {
    
    var alert: UIAlertController?
    
    var datePicker = UIDatePicker()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var signUpLabel: UILabel!
    
    @IBOutlet weak var activityScroller: UIActivityIndicatorView!
    
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBAction func firstNameTextField(_ sender: Any) {
        //print("first name typed")
    }
    
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBAction func lastNameTextField(_ sender: Any) {
        //print("last name typed")
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBAction func emailTextField(_ sender: Any) {
        //print("email typed")
    }
    
    @IBOutlet weak var initialPasswordLabel: UILabel!
    @IBOutlet weak var initialPasswordTextField: UITextField!
    @IBAction func initialPasswordTextField(_ sender: Any) {
        
        guard (initialPasswordTextField.text != nil && initialPasswordTextField.text != "") else {
            initialPasswordTextField.text = ""
            return
        }
        
        guard (initialPasswordTextField.text!.count >= 8 && includesNumbersAndLetters(text: initialPasswordTextField.text!)) else {
            initialPasswordTextField.text = ""
            confirmPasswordTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your password is invalid. please include 8 or more characters, as well as both letters and numbers", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
    }
    
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBAction func confirmPasswordTextField(_ sender: Any) {
        //print("action")
    }
    
    @IBOutlet weak var phoneTextField: UITextField!
    @IBAction func phoneTextField(_ sender: Any) {
        //print("action")
    }
    
    @IBOutlet weak var dobField: UITextField!
    @IBAction func dobField(_ sender: Any) {
    
    }
    
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBAction func signUpButton(_ sender: Any) {
        
        self.view.endEditing(true)
    
        guard activityScroller.isHidden == true else {
            //print("currently working on creating an account")
            return
        }
        
        guard (firstNameTextField.text != nil && firstNameTextField.text != "" && !includesNumbersAndLetters(text: firstNameTextField.text!)) else {
            firstNameTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your first name appears to be an invalid entry", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        guard (lastNameTextField.text != nil && lastNameTextField.text != "" && !includesNumbersAndLetters(text: lastNameTextField.text!)) else {
            lastNameTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your last name appears to be an invalid entry", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        
        guard (emailTextField.text != nil && emailTextField.text != "") && (emailTextField.text?.contains("@"))! && (emailTextField.text?.contains("."))! && (emailTextField.text?.count)! > 3 else {
            emailTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "it seems you have entered an invalid email. please try again", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }

        //Passwords must be at least eight characters long and contain both letters and numbers
        guard (initialPasswordTextField.text != nil && initialPasswordTextField.text != "") else {
            initialPasswordTextField.text = ""
            confirmPasswordTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "it seems you have forgotten to enter a password", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        guard (initialPasswordTextField.text!.count >= 8 && includesNumbersAndLetters(text: initialPasswordTextField.text!)) else {
            initialPasswordTextField.text = ""
            confirmPasswordTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your password is invalid. please include 8 or more characters, as well as both letters and numbers, without spaces", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        guard (initialPasswordTextField.text! == confirmPasswordTextField.text!) else {
            initialPasswordTextField.text = ""
            confirmPasswordTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "your passwords do not match", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        //checking phone number for validity
        guard (phoneTextField.text != nil && phoneTextField.text != "" && phoneTextField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil).count == 10 && !includesNumbersAndLetters(text: phoneTextField.text!)) else {
            alert = UIAlertController(title: "uh oh!", message: "your phone number appears to be an invalid entry. please use 10 numbers, and no more no less", preferredStyle: .alert)
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
        
        Customer.firstName = firstNameTextField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil)
        Customer.lastName = lastNameTextField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil)
        Customer.password = confirmPasswordTextField.text!
        Customer.email = emailTextField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil)
        Customer.phoneNumber = Int(phoneTextField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil))!
        
        
        activityScroller.startAnimating()
        activityScroller.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        BookerAPI().createCustomer { (success, message) in
            guard success else {
                
                print("error while creating customers and logging in: \(message)")
                DispatchQueue.main.async {
                    self.alert = UIAlertController(title: "uh oh!", message: message.lowercased(), preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(self.alert!, animated: true, completion: nil)
                    self.activityScroller.stopAnimating()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                return
            }
            
            
            do {
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: Customer.email, accessGroup: KeychainConfiguration.accessGroup)
                
                // Save the password for the new item.
                try passwordItem.savePassword(Customer.password)
            }
            catch {
                fatalError("Error updating keychain - \(error)")
            }
        
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.activityScroller.stopAnimating()
                self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: .presentHome, object: nil)
                }

            }
            
        }
        
    }
    
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func loginButton(_ sender: Any) {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("CreateAccountView", screenClass: "app")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.cornerRadius = 4
        loginButton.layer.masksToBounds = true
        loginButton.layer.borderColor = Design.Colors.brown.cgColor
        loginButton.layer.borderWidth = 1.0
        
        signUpButton.layer.cornerRadius = 4
        signUpButton.layer.masksToBounds = true
        signUpButton.layer.borderColor = Design.Colors.brown.cgColor
        signUpButton.layer.borderWidth = 1.0
        
    
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        initialPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
        dobField.delegate = self
        
        phoneTextField.addToolbarButtonToKeyboard(myAction:  #selector(self.phoneTextField.resignFirstResponder), title: "Done")
        
        initialPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        
        //add tags and next buttons for each of the items so that you can go through them easily
        firstNameTextField.tag = 0
        lastNameTextField.tag = 1
        initialPasswordTextField.tag = 2
        confirmPasswordTextField.tag = 3
        emailTextField.tag = 4
        phoneTextField.tag = 5
        dobField.tag = 6
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        activityScroller.hidesWhenStopped = true
        activityScroller.stopAnimating()
        
        //setting up Date of Birth field's date picker
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        let toolbar = UIToolbar(); //Format Date Picker Toolbar
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton,doneButton], animated: false)
        dobField.inputAccessoryView = toolbar
        dobField.inputView = datePicker

    }
    
    @objc func doneDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        dobField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }

    func loadingScreen(action: Bool) { //Thread Safe
        DispatchQueue.main.async {
            self.view.endEditing(true)
            UIApplication.shared.isNetworkActivityIndicatorVisible = action
            /*
                for subview in self.view.subviews {
                    subview.isHidden = action
                }
               */
            if action {
                self.activityScroller.startAnimating()
            } else {
                self.activityScroller.stopAnimating()
            }
        }
        
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    
    @objc func keyboardWillShow(notification: Notification) {
        
        guard let userInfo = notification.userInfo else {
            print("error")
            return
        }
        guard var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 50
        scrollView.contentInset = contentInset
        
    }

    
}

extension CreateAccountView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            initialPasswordTextField.becomeFirstResponder()
        } else if textField == initialPasswordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            phoneTextField.becomeFirstResponder()
        } else if textField == phoneTextField {
            dobField.becomeFirstResponder()
        } else if textField == dobField {
            signUpButton("")
        }
        
        return false
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(textField.frame, animated: true)
    }
    
}

extension UITextField {
    
    func addToolbarButtonToKeyboard(myAction:Selector?, title: String){
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()
        
        //let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: myAction);
        //@objc func cancelDatePicker(){  self.view.endEditing(true)  }
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: myAction)
        
        let items: [UIBarButtonItem] = [flexSpace,doneButton]
        toolbar.items = items
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
}

//Regular Expression Password Checker (to see if password contains letters and numbers)
func includesNumbersAndLetters(text : String) -> Bool{
    
    let letterPattern  = "[a-zA-Z]+"
    let regexLetters = try! NSRegularExpression(pattern: letterPattern, options: [])
    let matchesLetters = regexLetters.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
    let letterResult = (matchesLetters != [])
    
    let numberPattern  = "[0-9]+"
    let regexNumbers = try! NSRegularExpression(pattern: numberPattern, options: [])
    let matchesNumbers = regexNumbers.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
    let numberResult = (matchesNumbers != [])
    
    return letterResult && numberResult
    
}
