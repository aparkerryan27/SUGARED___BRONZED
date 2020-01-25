//
//  Login ViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import SafariServices
import Firebase

class LoginView: UIViewController {

    var alert: UIAlertController?
    var keyboardDisplayed: Bool = false
    
    @IBOutlet weak var loginLabel: UILabel!
    
    @IBOutlet weak var activityScroller: UIActivityIndicatorView!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBAction func emailTextField(_ sender: Any) {
        
        
    }

    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBAction func passwordTextField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBAction func forgotPasswordButton(_ sender: Any) {
        let url = URL(string: "https://go.booker.com/#/location/sbsantamonica/reset-password")!
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }
    
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func loginButton(_ sender: Any) {
        
        
        guard activityScroller.isHidden == true else {
            //print("currently working on logging you in")
            return
        }
    
        self.view.endEditing(true)
        
        guard (emailTextField.text != nil && emailTextField.text != "") && (emailTextField.text?.contains("@"))! && (emailTextField.text?.contains("."))! && (emailTextField.text?.count)! > 3 else {
            emailTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "it seems you have entered an invalid email. please try again", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        guard (passwordTextField.text != nil && passwordTextField.text != "") else {
            passwordTextField.text = ""
            alert = UIAlertController(title: "uh oh!", message: "it seems you have forgotten to enter a password. please try again", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
            return
        }
        
        loadingScreen(action: true)
        
        Customer.email = self.emailTextField.text!
        Customer.password = self.passwordTextField.text!
        
        UserDefaults.standard.setValue(Customer.email, forKey: "email")
        
        CustomerAPI().login { (success, errorMessage) in
            var message = errorMessage.lowercased()
            guard success else {
                if message == ""  { message = "something went wrong! please try again later." }
                DispatchQueue.main.async {
                    self.alert = UIAlertController(title: "uh oh!", message: message, preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(self.alert!, animated: true, completion: nil)
                }
                self.loadingScreen(action: false)
                return
            }
           
            DispatchQueue.main.async {
                
                do {
                    var passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: Customer.email, accessGroup: KeychainConfiguration.accessGroup)
                    
                    // Save the password for the new item.
                    try passwordItem.renameAccount(Customer.email)
                    try passwordItem.savePassword(Customer.password)
                }
                catch {
                    fatalError("Error updating keychain - \(error)")
                }

                 self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: .presentHome, object: nil)
                 }
            
            }
            
        }
        
    }
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBAction func signUpButton(_ sender: Any) {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        activityScroller.hidesWhenStopped = true
        activityScroller.stopAnimating()
        
        signUpButton.layer.cornerRadius = 4
        signUpButton.layer.masksToBounds = true
        signUpButton.layer.borderColor = Design.Colors.brown.cgColor
        signUpButton.layer.borderWidth = 1.0
        
        loginButton.layer.cornerRadius = 4
        loginButton.layer.masksToBounds = true
        loginButton.layer.borderColor = Design.Colors.brown.cgColor
        loginButton.layer.borderWidth = 1.0
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.setScreenName("LoginView", screenClass: "app")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillAppear() {
        keyboardDisplayed = true
    }
    
    @objc func keyboardWillDisappear() {
        keyboardDisplayed = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func loadingScreen(action: Bool) { //Thread Safe
        DispatchQueue.main.async {
            self.view.endEditing(true)
            UIApplication.shared.isNetworkActivityIndicatorVisible = action
            if action {
                self.activityScroller.startAnimating()
            } else {
                self.activityScroller.stopAnimating()
            }
        }
        
    }
}

extension LoginView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButton("")
        }
        
        return false
    }
    
}
