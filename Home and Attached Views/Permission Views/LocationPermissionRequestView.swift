//
//  LocationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

class LocationPermissionRequestView: UIViewController {

    let locationManager = CLLocationManager()
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    var accepted: Bool?
    
    @IBAction func denyButton(_ sender: Any) {
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: .homeViewDidBecomeVisible, object: nil)
        }
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Analytics.setScreenName("LocationPermissionView", screenClass: "app")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
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
    }
    
}

//MARK: - Location Permission Management
extension LocationPermissionRequestView: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: .homeViewDidBecomeVisible, object: nil)
            }
        }
    }
    
}
