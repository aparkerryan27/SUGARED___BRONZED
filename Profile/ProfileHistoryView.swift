//
//  LocationPermissionRequestView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import CoreLocation
import NVActivityIndicatorView
import Firebase

class ProfileHistoryView: UIViewController {
    
    var billingIndicatorContainer: UIView! {
        didSet {
            billingIndicatorContainer.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            billingIndicatorContainer.layer.cornerRadius = 4
            billingIndicatorContainer.layer.masksToBounds = true
            billingIndicatorContainer.isHidden = false
        }
    }
    var billingIndicator: NVActivityIndicatorView! {
        didSet {
            billingIndicator.startAnimating()
            billingIndicator.isHidden = false
        }
    }
    
    var membershipsIndicatorContainer: UIView! {
        didSet {
            membershipsIndicatorContainer.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            membershipsIndicatorContainer.layer.cornerRadius = 4
            membershipsIndicatorContainer.layer.masksToBounds = true
            membershipsIndicatorContainer.isHidden = false
        }
    }
    var membershipsIndicator: NVActivityIndicatorView! {
        didSet {
            membershipsIndicator.startAnimating()
            membershipsIndicator.isHidden = false
        }
    }
    
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var billingTableView: UITableView! {
        didSet {
            billingTableView.tag = 0
            billingTableView.isHidden = true
        }
    }
    
    @IBOutlet weak var membershipsTableView: UITableView! {
        didSet {
            membershipsTableView.tag = 1
            membershipsTableView.isHidden = true
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        billingIndicatorContainer.center = billingTableView.center
        billingIndicator.center = billingTableView.center
        membershipsIndicatorContainer.center = membershipsTableView.center
        membershipsIndicator.center = membershipsTableView.center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("ProfileHistoryView", screenClass: "app")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - Set up Activity Indicators
        billingIndicatorContainer = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.view.addSubview(billingIndicatorContainer)
        billingIndicator = NVActivityIndicatorView(frame: CGRect(x: billingIndicatorContainer.center.x - 30, y: billingIndicatorContainer.center.y-20, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(billingIndicator)
    
        membershipsIndicatorContainer = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.view.addSubview(membershipsIndicatorContainer)
        membershipsIndicator = NVActivityIndicatorView(frame: CGRect(x: membershipsIndicatorContainer.center.x - 30, y: membershipsIndicatorContainer.center.y-20, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(membershipsIndicator)
        
        //MARK: - Retrieve Past Appointments
        CustomerAPI().viewPastAppointments { (success, error) in
            DispatchQueue.main.async {
                self.billingIndicator.isHidden = true
                self.billingIndicatorContainer.isHidden = true
                self.billingTableView.reloadData()
                self.billingTableView.isHidden = false
            }
            guard success else {
                let alert = UIAlertController(title: "uh oh!", message: "it seems there was an issue viewing your past appointments. please try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async { self.present(alert, animated: true, completion: nil) }
                print("failed to view past appointments: \(error)")
                return
            }
        }
        
        CustomerAPI().findMemberships(methodCompletion: { (success, error) in
            DispatchQueue.main.async {
                self.membershipsIndicator.isHidden = true
                self.membershipsIndicatorContainer.isHidden = true
                self.membershipsTableView.reloadData()
                self.membershipsTableView.isHidden = false
            }
            guard success else {
                let alert = UIAlertController(title: "uh oh!", message: "it seems there was an issue viewing your active memberships. please try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async { self.present(alert, animated: true, completion: nil) }
                print("failed to view memberships: \(error)")
                return
            }

        })
        
        //MARK: - Set TableView Controllers
        billingTableView.delegate = self
        billingTableView.dataSource = self
        membershipsTableView.delegate = self
        membershipsTableView.dataSource = self
        
        //MARK: - Set up Observers
        NotificationCenter.default.addObserver(self, selector: #selector(presentAlert), name: .alertToPresent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(confirmationInfo), name: .confirmInfoNeeded, object: nil)
       
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
         NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Get Confirmation Info for each Membership Action
    @objc func confirmationInfo(notification: Notification) {
        
        let membership = Customer.memberships[membershipsTableView.indexPath(for: notification.object as! MembershipBillingCell)!.row]
        
        switch notification.userInfo!["action"] as! MembershipAction {
        case .cancel:
            
            let alert = UIAlertController(title: "are you sure?", message: "Any unused/accrued membership services will expire 30 days from your last billed date.  Are you sure you want to cancel?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "no", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "yes, i understand", style: .destructive, handler: { (alert) in
                self.performSegue(withIdentifier: "cancelOptionsSegue", sender: membership)
            }))
            self.present(alert, animated: true)
            
        case .freeze:
        
            self.performSegue(withIdentifier: "freezeOptionsSegue", sender: membership)
            
        /*
        case .update:
            1. segue to payment view
            2. verify payment with the UpdateMembershipPayment
            3. sendMembershipEmail(type: .update(name: "UPDATE"), membership: membership)
        */
        default:
            print("error - invalid membership action for this view")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "freezeOptionsSegue" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
            
            (segue.destination as! FreezeOptionsView).membership = (sender as! Membership)
        } else if segue.identifier == "cancelOptionsSegue" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
            
            (segue.destination as! CancelOptionsView).membership = (sender as! Membership)
        }
    }
    
    //MARK: - Present an Alert Triggered by TableViewCell Selection
    @objc func presentAlert(notification: Notification) {
        DispatchQueue.main.async {
            let info = notification.userInfo as! [String: Any]
            
            guard info["success"] as! Bool else {
                let alert = UIAlertController(title: "uh oh!", message: "it seems there was an issue sending your request. please try again later or contact membership@sugaredandbronzed.com", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let alert = UIAlertController(title: "all set!", message: "your membership request has been processed. please keep in mind that you have 30 days from your last billed date to use any unused/accrued membership services. remaining services will expire 30 days from your last billed date. in the case of a freeze: services will not be available during the duration of the freeze, but will remain on file and be available once the membership is reactivated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

//MARK: - Table View Data Sources
extension ProfileHistoryView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView.tag {
        case 0: //billing
            return Customer.pastAppointments.count
        
        default: //memberships
            guard Customer.memberships.count > 0 else {
                return 1
            }
            return Customer.memberships.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 { //APPOINTMENTS
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "appointmentBillingCell") as! AppointmentBillingCell
            cell.selectionStyle = .none
            
            let appointment = Customer.pastAppointments[indexPath.row]
            cell.dateLabel.text = (appointment.startTimeHuman) //only Itinerary getting loaded into the appointment definition, no startDate or locID
            
            for service in appointment.services {
                cell.priceLabel.text = "$\(service.price)"
                cell.serviceLabel.text = service.name.uppercased() //names aren't getting pulled through correctly in the BookerAPI handlers 100% of the time - possibly an issue with multiservice appointments? dictionaries aren't ordered so it would include unexpected behavior
            }

            return cell
            
        } else { // MEMBERSHIPS
            
            guard Customer.memberships.count != 0 else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "purchaseMembershipCell") as! ShowMembershipsCell
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "membershipBillingCell") as! MembershipBillingCell
            cell.selectionStyle = .none
        
            cell.membershipTypeLabel.text = Customer.memberships[indexPath.row].name.uppercased()
            
            return cell
        }
        
    }
}

//MARK: - Table View Delegates
extension ProfileHistoryView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        if tableView.tag == 1 && Customer.memberships.count == 0  { // BUY A MEMBERSHIP
            let alert = UIAlertController(title: "want to purchase a membership?", message: "click the hamburger icon on the home page, select PURCHASE MEMBERSHIP, and you're on your way!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}


class AppointmentBillingCell: UITableViewCell {
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
}

class ShowMembershipsCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
}

class MembershipBillingCell: UITableViewCell {
    
    @IBOutlet weak var membershipTypeLabel: UILabel!
    
    @IBOutlet weak var freezeButton: UIButton!
    @IBAction  func freezeButton(_ sender: Any) {
        
        NotificationCenter.default.post(name: .confirmInfoNeeded, object: self, userInfo: ["action": MembershipAction.freeze])
        
    }
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction  func cancelButton(_ sender: Any) {
        
        NotificationCenter.default.post(name: .confirmInfoNeeded, object: self, userInfo: ["action": MembershipAction.cancel])
       
    }
    
}

func sendMembershipEmail(type: MembershipAction, membership: Membership, freezeDuration: Int? = nil, medicalImageString: String = "", reason: String){

    
    var emailParams: [String: Any]
    var timing = "Post-Cutoff"
    
    let day = Calendar.current.dateComponents([.day], from: Date()).day!
    if day < 25 {
        timing = "Pre-Cutoff"
    }
    
    //MARK: - Configure Action Specific Variables
    switch type {
    case .purchase:
        
        emailParams = [ "Messages" : [
            [
                "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B" ],
                "To": [ [ "Email": Customer.email, "Name": Customer.firstName ] ],
                "CC": [ [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B"] ],
                "TemplateID": 983128,
                "TemplateLanguage": true,
                "Subject": "Membership Purchase on the S+B App",
                "Variables": [
                    "CustomerName": Customer.firstName,
                    "CustomerEmail": Customer.email,
                    "MembershipName": membership.name, //"SAVVY EXPRESS"
                ]
            ]
        ] ]
        
    case .cancel:
        emailParams = [ "Messages" : [
            [
                "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B" ],
                "To": [ [ "Email": Customer.email, "Name": Customer.firstName ] ],
                "TemplateID": 999627,
                "TemplateLanguage": true,
                "Subject": "Request of Membership Change on the S+B App",
                "Variables": [
                    "CustomerName": Customer.firstName,
                    "MembershipName": membership.name, //"SAVVY EXPRESS"
                ]
            ],
            [
                "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B iOS App Membership Notifier" ],
                "To": [ [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B" ] ],
                "TemplateID": 999631,
                "TemplateLanguage": true,
                "Subject": "Notification of Membership Change - S+B APP",
                "Variables": [
                    "CustomerName": "\(Customer.firstName) \(Customer.lastName)",
                    "CustomerEmail": Customer.email,
                    "MembershipType": membership.name,
                    "FreezeDuration": freezeDuration ?? 0,
                    "CustomerID": Customer.id,
                    "MembershipID": membership.idWest,
                    "Reason" : reason,
                    "Timing": timing
                ]
            ]
        ]
        ]
    case .freeze:
        
        //add or remove attachments
        if medicalImageString == "" {
            emailParams = [ "Messages" : [
                [
                    "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B" ],
                    "To": [ [ "Email": Customer.email, "Name": Customer.firstName ] ],
                    "TemplateID": 999628,
                    "TemplateLanguage": true,
                    "Subject": "Request of Membership Change on the S+B App",
                    "Variables": [
                        "CustomerName": Customer.firstName,
                        "MembershipName": membership.name, //"SAVVY EXPRESS"
                    ]
                ],
                [
                    "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B iOS App Membership Notifier" ],
                    "To": [ [ "Email": SugaredAndBronzed.membershipEmail, "Name": "Parker" ] ],
                    "TemplateID": 999630,
                    "TemplateLanguage": true,
                    "Subject": "Notification of Membership Change - S+B APP",
                    "Variables": [
                        "CustomerName": "\(Customer.firstName) \(Customer.lastName)",
                        "CustomerEmail": Customer.email,
                        "MembershipType": membership.name,
                        "FreezeDuration": freezeDuration ?? 0,
                        "CustomerID": Customer.id,
                        "MembershipID": membership.idWest,
                        "Reason" : reason,
                        "Timing": timing
                    ]
                ]
            ]
            ]
        } else {
            emailParams = [ "Messages" : [
                [
                    "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B" ],
                    "To": [ [ "Email": Customer.email, "Name": Customer.firstName ] ],
                    "TemplateID": 999628,
                    "TemplateLanguage": true,
                    "Subject": "Request of Membership Change on the S+B App",
                    "Variables": [
                        "CustomerName": Customer.firstName,
                        "MembershipName": membership.name, //"SAVVY EXPRESS"
                    ]
                ],
                [
                    "From": [ "Email": SugaredAndBronzed.membershipEmail, "Name": "S+B iOS App Membership Notifier" ],
                    "To": [ [ "Email": SugaredAndBronzed.membershipEmail, "Name": "Parker" ] ],
                    "TemplateID": 999630,
                    "TemplateLanguage": true,
                    "Subject": "Notification of Membership Change - S+B APP",
                    "Variables": [
                        "CustomerName": "\(Customer.firstName) \(Customer.lastName)",
                        "CustomerEmail": Customer.email,
                        "MembershipType": membership.name,
                        "FreezeDuration": freezeDuration ?? 0,
                        "CustomerID": Customer.id,
                        "MembershipID": membership.idWest,
                        "Reason" : reason,
                        "Timing": timing
                    ],
                    
                    "Attachments": [
                        [
                            "ContentType": "image/jpg",
                            "Filename": "medicalImage.jpg",
                            "Base64Content": medicalImageString
                        ]
                    ]
                ]
            ]
            ]
        }
        
            
        //, .update(let name):
    }
    
    
    //MARK: - Send Info to the Customer
    Requests().POST(url: "https://api.mailjet.com/v3.1/send", parameters: emailParams, headerType: "mail") { (success, data, error) in
        
        guard success else {
            print("failed to send email - \(error!)")
            NotificationCenter.default.post(name: .alertToPresent, object: nil, userInfo: ["success": false, "type": type])
            return
        }
        
        NotificationCenter.default.post(name: .alertToPresent, object: nil, userInfo: ["success": true, "type": type])
    }
}


enum MembershipAction {
    case purchase
    case freeze
    case cancel
    //case update(name: String)
}

extension Notification.Name {
    
    static let alertToPresent = Notification.Name("alertToPresent")
    static let confirmInfoNeeded = Notification.Name("confirmInfoNeeded")
    static let backToProfile = Notification.Name("backToProfile")
}
