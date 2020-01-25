//
//  HomeView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 6/20/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import AVKit
import AVFoundation
import CoreLocation
import Firebase
import Crashlytics
import OneSignal
import MessageUI
import SafariServices
import SwiftyJSON

class HomeView: UIViewController {
    
    var locationViewController: LocationView?
    var locationNavController: UINavigationController?
    var mapTransitionAllowed = false
    
    var menuExposed: Bool = false
    var buttonAdjusted = false
    
    var effect: UIVisualEffect!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    let locationManager = CLLocationManager()
    
    var segueInQueue = ""
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    var alert: UIAlertController?

    var firstLoad = true
    
    @IBOutlet weak var backgroundView: UIImageView!
    
    var activityIndicator: NVActivityIndicatorView! {
        didSet {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = true
        }
    }
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var coverView: UIView!
    
    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var greetingLabel: UILabel!
    
    @IBOutlet weak var appointmentTableTop: UIView!
    
    @IBOutlet weak var appointmentsTable: UITableView! {
        didSet {
            appointmentsTable.tag = 1
            appointmentsTable.isHidden = false
        }
    }
    
    @IBOutlet weak var bookButtonTableTop: UIView!
    
    @IBOutlet weak var bookButtonTableHeight: NSLayoutConstraint!
    @IBOutlet weak var bookButtonTable: UITableView! {
        didSet {
            bookButtonTable.tag = 0
        }
    }
    
    @IBOutlet weak var appointmentsTableHeight: NSLayoutConstraint!
    let appointmentCellHeight = 90
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var bookButton: UIButton!
    @IBAction func bookButton(_ sender: Any) {
        if !menuExposed {
            present(locationNavController!, animated: true, completion: nil)
            //self.performSegue(withIdentifier: "toLocationViewSegue", sender: nil)
        }
    }
    
    @IBAction func menuButton(_ sender: Any) {
        revealMenu()
    }

    //MARK: - Handling menu appearances
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (parent!.parent! as! HomeContainerView).leftEdgeConstraint.constant != 0 {
            blurView.effect = nil
        }
        
        greetingLabel.text = "hey \(Customer.firstName.lowercased())!"
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func revealMenu() {
        
        let containerView = parent!.parent! as! HomeContainerView
        
        if menuExposed { //If the menu is exposed, pull it off the screen
            menuExposed = false
            containerView.leftEdgeConstraint.constant = containerView.view.frame.width * ((-4)/5)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.blurView.effect = nil
            }) {(success: Bool) in
                self.blurView.isHidden = true
            }
            
        } else { //If the menu is off the screen, pull it on
            menuExposed = true
            containerView.leftEdgeConstraint.constant = 0
            
            blurView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.blurView.effect = self.effect
            }
        }
        
        UIView.animate(withDuration: 0.5) {
            containerView.view.layoutIfNeeded()
        }
    }
    
    @objc func closeMenu() {
        if menuExposed { //if the menu is exposed, pull it off the screen
            revealMenu()
        }
    }
    
    @objc func allowTransitionToMap() {
        mapTransitionAllowed = true
        DispatchQueue.main.async {
            (self.bookButtonTable.cellForRow(at: IndexPath(row: 0, section: 0)) as! BookCell).status = .ready
        }
    
     
    }
    
    @objc func checkSegue() {
        if segueInQueue != "" {
            self.performSegue(withIdentifier: segueInQueue, sender: nil)
            segueInQueue = ""
        }
    }
    
    //MARK: - Configuring Views
    override func viewDidLoad() {
        super.viewDidLoad()
        

        //TODO: - are these alpha values necessary to set
        self.logo.alpha = 0
        self.playerView.alpha = 1
        self.appointmentsTable.alpha = 1
        self.bookButtonTable.alpha = 1
        
        locationManager.delegate = self
        
        //MARK: - Disable Navigation Bar Cutoff
        let img = UIImage()
        self.navigationController?.navigationBar.shadowImage = img
        self.navigationController?.navigationBar.setBackgroundImage(img, for: .default)
        
        //MARK: - Enable Tables
        appointmentsTable.dataSource = self
        appointmentsTable.delegate = self
        bookButtonTable.dataSource = self
        bookButtonTable.delegate = self
        
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(activityIndicator)
        
        blurView.isHidden = true
        effect = blurView.effect
        blurView.effect = nil
        self.view.bringSubviewToFront(blurView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeMenu))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        //MARK: - Calculate Table Size
        let numCells = Customer.activeAppointments.count != 0 ? Customer.activeAppointments.count: 1
        self.appointmentsTableHeight.constant = CGFloat(self.appointmentCellHeight * numCells)
        self.activityIndicator.center = self.appointmentsTable.center
        
        //MARK: - Add Notification Observer
        NotificationCenter.default.addObserver(self, selector: #selector(checkSegue), name:
            .homeViewDidBecomeVisible, object: nil)
        
        //MARK: - Preload MapView
        prepareLocationView()
    }
    
    @objc func presentAlert(notification: Notification){
        DispatchQueue.main.async {
            
            guard let message = notification.object as? String else {
                print("error: no message available")
                return
            }
            
            self.alert = UIAlertController(title: "uh oh!", message: message, preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityIndicator.center = appointmentsTable.center
        
        //MARK: - Adjust BookButton when Spacer Present
        if bookButton.frame.height > 0 && !buttonAdjusted {
            bookButtonTableHeight.constant -= 20; buttonAdjusted = true
        }
    }
    
    @objc func prepareLocationView(){
        //MARK: - Prepare MapView Setup
        guard let storyboard = self.storyboard else {
            print("error initializing storyboard")
            return
        }
        self.locationViewController = (storyboard.instantiateViewController(withIdentifier: "locationViewController") as! LocationView)
        self.locationNavController = UINavigationController(rootViewController: self.locationViewController!)
        locationNavController?.modalPresentationStyle = .fullScreen
        self.locationViewController!.loadMap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if firstLoad {
            firstLoad = false
        } else {
            self.bookButtonTable.reloadData() //checks if map view is ready and resets spinner
            viewAppointments()
        }
        
        //MARK: - Clear Variables to avoid Side Menu Conflicts
        MembershipPurchase.membershipsSelected = []
        AppointmentSearch.selectedServices = []
        
        //MARK: - Set Observers
        NotificationCenter.default.addObserver(self, selector: #selector(allowTransitionToMap), name: .mapPreloadCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(prepareLocationView), name: .returnedHomeFromCompletion, object: nil)
    }
    
    func viewAppointments(){
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.appointmentsTable.isHidden = true
            self.activityIndicator.isHidden = false
        }

        CustomerAPI().viewAppointments(methodCompletion: { (success, error) -> Void in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.appointmentsTable.isHidden = false
                self.activityIndicator.isHidden = true
            }
    
            guard error != "locations not yet loaded" else {
                print("locations not yet loaded, running viewAppointments again!!!")
                self.viewAppointments()
                return
            }
            
            guard success else {
                print("Failure to Get Appointments: \(error)")
                self.viewAppointments()
                return
            }
            
            DispatchQueue.main.async {
                
                self.appointmentsTable.reloadData()
                //MARK: - Calculate Table Size
                let numCells = Customer.activeAppointments.count != 0 ? Customer.activeAppointments.count: 1
                self.appointmentsTableHeight.constant = CGFloat(self.appointmentCellHeight * numCells)
                self.activityIndicator.center = self.appointmentsTable.center
                
                
            }
        })
    }
    
}

//MARK: - Configuring Cells
extension HomeView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //the number of active appointments, with the book now button
        guard tableView.tag == 1 else {
            return 1
        }
        guard Customer.activeAppointments.count != 0 else {
            return 1
        }
        
        return Customer.activeAppointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard tableView.tag == 1 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell") as! BookCell
            cell.selectionStyle = .none
            if mapTransitionAllowed {
                cell.status = .ready
            } else {
                cell.status = .loading
            }
            
            return cell
        }
        guard Customer.activeAppointments.count != 0 else {
            
            //refer a friend
            let cell = tableView.dequeueReusableCell(withIdentifier: "referCell") as! ReferCell
            cell.selectionStyle = .none
            cell.nameLabel.text = "REFER A FRIEND"
            
         
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "appointmentItemCell") as! AppointmentItemCell
        
        cell.selectionStyle = .none
        let start = Customer.activeAppointments[indexPath.row].startTimeHuman.uppercased()
        let date = Customer.activeAppointments[indexPath.row].startDateTime
        let formatter = DateFormatter()
        let weekday = formatter.shortWeekdaySymbols[(Calendar.current.component(.weekday, from: date) - 1)].uppercased()
        
        let day = Calendar.current.dateComponents([.day], from: date).day!
        let month = formatter.shortMonthSymbols[Calendar.current.component(.month, from: date) - 1].uppercased()
        
        cell.timeLabel.text = "\(weekday), \(month) \(day), \(start)"
        return cell
        
    }
    
}

//MARK: - Configuring View Selection and Headers/Footers
extension HomeView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(appointmentCellHeight)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard !menuExposed else {
            return
        }
        guard tableView.tag == 1 else {
            
            present(locationNavController!, animated: true, completion: nil)
            return
        }
        
        guard Customer.activeAppointments.count != 0 else {
            
            //the refer button
            guard (MFMessageComposeViewController.canSendText()) else {
                let alert = UIAlertController(title: "uh oh!", message: "it looks like your device is ineligble to send text messages, please try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            
            appointmentsTable.isHidden = true
            activityIndicator.isHidden = false
            let controller = MFMessageComposeViewController()
            controller.body = "Book an appointment on the SUGARED + BRONZED app and we'll both get something sweet! You'll get a new client special and I'll get a $10 referral credit. Make sure you mention my name upon check-in! \nhttps://www.sugaredandbronzed.com"
            controller.messageComposeDelegate = self
            self.present(controller, animated: false, completion: {
                DispatchQueue.main.async {
                    self.appointmentsTable.isHidden = false
                    self.activityIndicator.isHidden = true
                    
                }
            })
            return
        }
        
        Customer.appointmentSelected = Customer.activeAppointments[indexPath.row]
        self.performSegue(withIdentifier: "toAppointmentDetailSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "toRequestLocationPermissionSegue" || segue.identifier == "toNotificationPermissionSegue" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        }
    }
}

//MARK: - Handling Location Permission
extension HomeView: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            DispatchQueue.main.async {
                if self == self.navigationController?.visibleViewController {
                    self.performSegue(withIdentifier: "toRequestLocationPermissionSegue", sender: nil)
                } else {
                    print("didn't show location - view not currently visible")
                    self.segueInQueue = "toRequestLocationPermissionSegue"
                }
            }
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied, .restricted:
            print("Location Access Denied")
        }
    }
    
}

//MARK: - Handling Messager for REFER A FRIEND
extension HomeView: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        self.dismiss(animated: true, completion: {
            
        })
        if result == .sent {
            let alert = UIAlertController(title: "congrats!", message: "you've successfully sent your referral text, you're practically glowing!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}

class AppointmentItemCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
}

class BookCell: UITableViewCell {
    
    var status: BookCellStatus! = .loading {
        didSet {
            switch status! {
            case .loading:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                continueImage.isHidden = true
                self.isUserInteractionEnabled = false
            case .ready:
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                continueImage.isHidden = false
                self.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var continueImage: UIImageView!
    
    
}

enum BookCellStatus {
    case loading
    case ready
}

class ReferCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
}

extension Notification.Name {
    static let homeViewDidBecomeVisible = Notification.Name("homeViewDidBecomeVisible")
    static let homeViewDidBecomeInvisible = Notification.Name("homeViewDidBecomeInvisible")
    static let returnedHomeFromCompletion = Notification.Name("returnedHomeFromCompletion")
}


/*
Deprecated Segue (desired look, undesired functionality)
 
class MyCustomSeguePushForward: UIStoryboardSegue {
    override func perform() {
        let preV: UIView = source.view
        let newV: UIView = destination.view
    
        let window: UIWindow = UIApplication.shared.delegate!.window!!
        newV.center = CGPoint(x: preV.center.x + preV.frame.size.width, y: newV.center.y)
        window.insertSubview(newV, aboveSubview:preV)
        
        UIView.animate(withDuration: 0.4, animations: {
            newV.center = CGPoint(x: preV.center.x, y: newV.center.y)
            preV.center = CGPoint(x: 0 - preV.center.x, y: newV.center.y)
        }) { (finished) in
            preV.removeFromSuperview()
            window.rootViewController = self.destination
        }
    }
}

class MyCustomSeguePushBackward: UIStoryboardSegue {
    override func perform() {
        let preV: UIView = source.view
        let newV: UIView = destination.view
        
        let window: UIWindow = UIApplication.shared.delegate!.window!! 
        newV.center = CGPoint(x: preV.center.x - preV.frame.size.width, y: newV.center.y)
        window.insertSubview(newV, aboveSubview:preV)
        
        UIView.animate(withDuration: 0.4, animations: {
            newV.center = CGPoint(x: preV.center.x, y: newV.center.y)
            preV.center = CGPoint(x: preV.center.x + preV.frame.size.width, y: newV.center.y)
        }) { (finished) in
            preV.removeFromSuperview()

        }
    }
}

 */
