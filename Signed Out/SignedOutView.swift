//
//  SignedOutView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import Firebase
import FacebookCore
import FBSDKCoreKit
import OneSignal
import SwiftyJSON

class SignedOutView: UIViewController {

    var alert: UIAlertController?
    var player: AVPlayer?
    
    var runningInitialConnections = false
    
    var gotCustomer = false
    var gotLocations = false
    var gotToken = false
    var allowTransition = false
    
    @IBOutlet weak var coverView: UIView!
    
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func signupButton(_ sender: Any) {
        performSegue(withIdentifier: "toCreateAccountSegue", sender: nil)
    }
    
    @IBAction func loginButton(_ sender: Any) {
        performSegue(withIdentifier: "toLoginSegue", sender: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("SignedOutView", screenClass: "app") //Firebase Screen Declaration
        
       /*
        let storeInfoURL: String = "http://itunes.apple.com/lookup?bundleId=com.sugaredandbronzed.app"
        var upgradeAvailable = false
        let currentVersion = 1.1
         
        Requests().GET(url: storeInfoURL) { (success, data, error) in
         
         guard success else {
            print("baddd")
            return
         }
         
         let json = JSON(data: data!)
         
        
        if let infoDictionary = bundle.infoDictionary {
            // The URL for this app on the iTunes store uses the Apple ID for the  This never changes, so it is a constant
         
         
            json["results"][0]["version"]["CFBundleShortVersionString"]
            if version != currentVersion {
                upgradeAvailable = true
            }
        }
         }
         
        */
        
        if !runningInitialConnections {
            runningInitialConnections = true
            initiateConnections()
        }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppEvents.logEvent(AppEvents.Name("app_open")) //Facebook Event
        
        startVideo()
        self.coverView.alpha = 1.0
        loadingScreen(hide: true)
        
        signupButton.layer.cornerRadius = 4
        signupButton.layer.masksToBounds = true
        signupButton.layer.borderColor = Design.Colors.brown.cgColor
        signupButton.layer.borderWidth = 1.0
        
        
        loginButton.layer.cornerRadius = 4
        loginButton.layer.masksToBounds = true
        loginButton.layer.borderColor = Design.Colors.blue.cgColor
        loginButton.layer.borderWidth = 1.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentHome), name: .presentHome, object: nil)
       
    }
    
    @objc func presentHome(notification: Notification) {
        self.dismiss(animated: true, completion: nil) //dismisses any alert present
        performSegue(withIdentifier: "toHomeSegue", sender: nil)
    }
    
    func initiateConnections() {
        
        gotCustomer = false
        gotLocations = false
        gotToken = false
        
        //MARK: - Setting Max Load Time
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if !self.gotToken {
                self.alert = UIAlertController(title: "uh oh!", message: "it appears that your internet connection isn't working, or we're having issues on our end! please try again later. we will try to reconnect after 10 seconds", preferredStyle: .alert)
                self.present(self.alert!, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    self.alert!.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        //MARK: - Getting Access Token and Location Info
        BookerAPI().getAccessToken(methodCompletion: { (success, error) -> Void in
            
            guard success else {
                self.runningInitialConnections = false
                print("Failure to Get Access Token: \(error)")
                self.alert = UIAlertController(title: "uh oh!", message: "it appears that your internet connection isn't working, or we're having issues on our end! please try again later. we will try to reconnect after 10 seconds", preferredStyle: .alert)
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.present(self.alert!, animated: true, completion: nil)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.initiateConnections()
                }
                return
            }
            
            self.gotToken = true
            
            BookerAPI().getLocationsAndServices(methodCompletion: { (locationSuccess, locationError) -> Void in
                guard locationSuccess else {
                    self.runningInitialConnections = false
                    print("Failure to Get Location: \(locationError)")
                    self.alert = UIAlertController(title: "uh oh!", message: "it appears that your internet connection isn't working, or we're having issues on our end! please try again later. we will try to reconnect after 10 seconds", preferredStyle: .alert)
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.present(self.alert!, animated: true, completion: nil)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.initiateConnections()
                    }
                    return
                }
                
                BookerAPI().getLocationImages(methodCompletion: { (imageSuccess, imageError) in
                    guard imageSuccess else {
                        print(imageError)
                        return
                    }
                    
                    self.gotLocations = true
                    if self.gotCustomer {
                        self.loadAppointments()
                    }
                    
                    self.runningInitialConnections = false
                })
            })
        })
        
        //MARK: - Getting Memberships from Intermediary Server
        BookerAPI().findMemberships { (success, error) in
            guard success else {
                print("finding booker memberships error: \(error)")
                return
            }

        }
        
        //MARK: - Process Customer Log In Information
        guard let email = UserDefaults.standard.value(forKeyPath: "email") as? String else {
            loadingScreen(hide: false)
            return
        }
        
        do { // If an account name has been set, read any existing password from the keychain.
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: email, accessGroup: KeychainConfiguration.accessGroup)
            
            Customer.password = try passwordItem.readPassword()
            Customer.email = email
            
            CustomerAPI().login { (success, errorMessage) in
                guard success else {
                    if !errorMessage.contains("Internet Request Failure") { //if the issue is an internet problem, don't interfere with exisiting alerts
                        self.loadingScreen(hide: false) //otherwise if the login just failed, show the login screens
                    }
                    print("loadCustomer failed")
                    return
                }
                
                self.gotCustomer = true
                if self.gotLocations {
                    self.loadAppointments()
                }
            }
        }
        catch {
            print("Error reading password from keychain - \(error)")
            loadingScreen(hide: false)
        }
    }
    
    func loadAppointments(){
        
        DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = true }
        Customer.runningViewAppointments = true
        
        CustomerAPI().viewAppointments(methodCompletion: { (success, error) -> Void in
            DispatchQueue.main.async {  UIApplication.shared.isNetworkActivityIndicatorVisible = false }
            Customer.runningViewAppointments = false
            
            guard error != "locations not yet loaded" else {
                print("locations not yet loaded, running viewAppointments again!!!")
                self.loadAppointments()
                return
            }
            
            guard error == "successful!" || error == "" else {
                print("Failure to Get Appointments: \(error)")
                self.loadingScreen(hide: false)
                return
            }
            
            if self.allowTransition {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil) //dismisses any alert present
                    self.performSegue(withIdentifier: "toHomeSegue", sender: nil)
                }
            } else {
                self.allowTransition = true
            }

        })
    }
   
    func loadingScreen(hide: Bool) {
        DispatchQueue.main.async {
            if hide {
                self.signupButton.isHidden = true
                self.loginButton.isHidden = true
                self.signupButton.alpha = 0
                self.loginButton.alpha = 0
            } else {
                UIView.animate(withDuration: 2) {
                    self.signupButton.isHidden = false
                    self.loginButton.isHidden = false
                    self.signupButton.alpha = 1.0
                    self.loginButton.alpha = 1.0
                }
            }
            
        }
        
    }
    
    private func startVideo() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient) //prevent background music stop
        } catch { }
        
        guard let path = Bundle.main.path(forResource: "SplashLoop", ofType:"m4v") else {
            print("SplashLoop.m4v not found")
            return
        }
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = self.view.frame
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.zPosition = -1
        
        self.view.layer.addSublayer(playerLayer)
        
        player?.seek(to: CMTime.zero)
        player?.play()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 3) {
                self.coverView.alpha = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.allowTransition {
                self.dismiss(animated: true, completion: nil) //dismisses any alert present
                self.performSegue(withIdentifier: "toHomeSegue", sender: nil)
            } else {
                self.allowTransition = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
        }
    }
    
}


extension Notification.Name {

    static let presentHome = Notification.Name("presentHome")
}
