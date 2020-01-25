//
//  AppointmentDetailViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import EventKit
import MapKit
import NVActivityIndicatorView
import MessageUI
import Firebase

class AppointmentDetailView: UIViewController {
    
    let appleEventStore = EKEventStore()
    var calendars: [EKCalendar]?
    var alert: UIAlertController?
    var location: Location? = nil
    
    var activityIndicatorContainerView: UIView! {
        didSet {
            activityIndicatorContainerView.center = view.center
            activityIndicatorContainerView.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            activityIndicatorContainerView.layer.cornerRadius = 4
            activityIndicatorContainerView.layer.masksToBounds = true
            activityIndicatorContainerView.isHidden = true
        }
    }
    var activityIndicator: NVActivityIndicatorView! {
        didSet {
            activityIndicator.center = view.center
            activityIndicator.startAnimating()
            activityIndicator.isHidden = true
        }
    }
    var newBookingView: UIViewController?
    
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var serviceTypeLabel: UILabel!
    
    @IBOutlet weak var serviceTypeLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var serviceDateLabel: UILabel!
    
    @IBOutlet weak var serviceTimeLabel: UILabel!
    
    @IBOutlet weak var addToCalendarButton: UIButton!
    @IBAction func addToCalendarButton(_ sender: Any) { generateEvent() }
    
    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.layer.cornerRadius = 4
            cancelButton.layer.masksToBounds = true
            cancelButton.layer.borderColor = Design.Colors.blue.cgColor
            cancelButton.layer.borderWidth = 1.0
        }
    }
    @IBAction func cancelButton(_ sender: Any) {
        
        alert = UIAlertController(title: "are you sure?", message: "cancelling an appointment removes your name from this timeslot permanently, and it may not be available for booking again.", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "no", style: .cancel, handler: nil))
        alert!.addAction(UIAlertAction(title: "yes, cancel", style: .destructive, handler: {
            UIAlertAction in self.cancelAppointment()
        }))
        present(alert!, animated: true, completion: nil)
        
    }
    
    func cancelAppointment() {
        Customer.appointmentToCancelID = Customer.appointmentSelected?.id
        activityIndicator.isHidden = false
        activityIndicatorContainerView.isHidden = false
        
        CustomerAPI().cancelAppointment(methodCompletion: { (success, error) -> Void in
            guard success else {
                print("Failure to Cancel Appointment: \(error)")
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.activityIndicator.isHidden = true
                    self.activityIndicatorContainerView.isHidden = true
                }
                self.alert = UIAlertController(title: "uh oh!", message: "failed to cancel appointment, please try again later", preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "okay", style: .destructive, handler: nil))
                self.present(self.alert!, animated: true, completion: nil)
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
    }
    
    @IBOutlet weak var modifyButton: UIButton! {
        didSet {
            modifyButton.layer.cornerRadius = 4
            modifyButton.layer.masksToBounds = true
            modifyButton.layer.borderColor = Design.Colors.blue.cgColor
            modifyButton.layer.borderWidth = 1.0
        }
    }
    @IBAction func modifyButton(_ sender: Any) {
        alert = UIAlertController(title: "are you sure?", message: "modifying an appointment will remove your name from this timeslot after you book your new appointment.", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "no", style: .cancel, handler: nil))
        alert!.addAction(UIAlertAction(title: "yes, modify", style: .destructive, handler: {
            UIAlertAction in self.modifyAppointment()
        }))
        present(alert!, animated: true, completion: nil)
        
    }
    
    func modifyAppointment(){
        Customer.appointmentToCancelID = Customer.appointmentSelected?.id
        if newBookingView != nil {
            present(newBookingView!, animated: true, completion: nil)
        } else {
            print("locationView improperly configured")
            alert = UIAlertController(title: "oops!", message: "modifying appointments isn't available right now. please book a different appointment and just cancel this one!", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "no", style: .cancel, handler: nil))
            present(alert!, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var getDirectionsImage: UIImageView! {
        didSet {
            getDirectionsImage.layer.masksToBounds = true
            getDirectionsImage.layer.shadowColor = UIColor.black.cgColor
            getDirectionsImage.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            getDirectionsImage.layer.shadowOpacity = 0.3
        }
    }
    @IBOutlet weak var getDirectionsButton: UIButton!
    @IBAction func getDirectionsButton(_ sender: Any) {

        let latitude: CLLocationDegrees = location!.latitude
        let longitude: CLLocationDegrees = location!.longitude
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location!.name
        mapItem.phoneNumber = location!.phone
        mapItem.openInMaps()
        
    }
    
    @IBOutlet weak var contactButton: UIButton!
    @IBAction func contactButton(_ sender: Any) {
        sendMessage()
    }
    
    @IBOutlet weak var homeButton: UIButton!
    @IBAction func homeButton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Analytics.setScreenName("AppointmentDetailView", screenClass: "app")
        
        Customer.appointmentToCancelID = nil
        
        if Customer.appointmentModified { //closes the base view when an appointment is modified
            Customer.appointmentModified = false;
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.view.addSubview(activityIndicatorContainerView)
        
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(activityIndicator)
        
        let locationID = Customer.appointmentSelected!.locationID!
        getDirectionsImage.image = UIImage(named: "\(locationID)_image") ?? UIImage(named: "placeholder_location_image")
        location = SugaredAndBronzed.locations[locationID]
       
        locationLabel.text = "\(location!.name) - \(location!.street) \(location!.city), \(location!.state) \(location!.zipCode)"
        
        serviceTypeLabel.text = ""
        var numTreatments = Customer.appointmentSelected!.services.count
        for treatment in Customer.appointmentSelected!.services {
            serviceTypeLabel.text?.append(treatment.name.uppercased())
            numTreatments -= 1
            if numTreatments != 0 {
                 serviceTypeLabel.text?.append(", \n") //denote a list
                 serviceTypeLabelHeight.constant += 25
            }
        }
        
        serviceTimeLabel.text = "\(Customer.appointmentSelected!.startTimeHuman) - \(Customer.appointmentSelected!.endTimeHuman)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        serviceDateLabel.text = dateFormatter.string(from: Customer.appointmentSelected!.startDateTime)
        
        guard let storyboard = self.storyboard else {
            return
        }
        let locViewController = (storyboard.instantiateViewController(withIdentifier: "locationViewController") as! LocationView)
        self.newBookingView = UINavigationController(rootViewController: locViewController)
        newBookingView?.modalPresentationStyle = .fullScreen
        locViewController.loadMap()
    
    }
    
    //MARK: - Adding Event to Calendar
    func generateEvent() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch status
        {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            appleEventStore.requestAccess(to: .event, completion: { (granted, error) in
                if (granted) && (error == nil) {
                    DispatchQueue.main.async {
                        self.addAppleEvents()
                    }
                } else {
                    DispatchQueue.main.async{
                        self.alert = UIAlertController(title: "uh oh!", message: "it seems you haven't given us permission to add events to the calendar, to change this visit your Settings app", preferredStyle: .alert)
                        self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(self.alert!, animated: true, completion: nil)
                    }
                }
            })
        case EKAuthorizationStatus.authorized:
            // User has access
            self.addAppleEvents()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            self.alert = UIAlertController(title: "uh oh!", message: "it seems you haven't given us permission to add events to the calendar. to change this visit your Settings app", preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    func addAppleEvents()
    {
        
        var appointmentDescription = "your upcoming appointment consists of the following service(s): \n"
        for service in Customer.appointmentSelected!.services {
            appointmentDescription.append("\(service.name) \n")
        }
        appointmentDescription.append(" -- preferably come prepared with dark, loose fitting clothing and arrive at least 5 minutes before your scheduled appointment time")
        
        
        //theres a bug with this! it is not adjusted for time zones!
        let startDate: Date = (Customer.appointmentSelected!.startDateTime).addingTimeInterval(7.0 * 60.0 * 60.0) //adjusting for UTC (+07:00)
        let endDate = (Customer.appointmentSelected!.endDateTime).addingTimeInterval(7.0 * 60.0 * 60.0) //adjusting for UTC (+07:00)
        
        let event:EKEvent = EKEvent(eventStore: appleEventStore)
        event.title = "SUGARED + BRONZED Appointment"
        event.startDate = startDate
        event.endDate = endDate
        event.location = location!.name
        event.notes = appointmentDescription
        event.calendar = appleEventStore.defaultCalendarForNewEvents
        
        var eventAlreadyExists = false
        let predicate = appleEventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let existingEvents = appleEventStore.events(matching: predicate)
        for singleEvent in existingEvents {
            if singleEvent.title == "SUGARED + BRONZED Appointment" && singleEvent.startDate == startDate {
                eventAlreadyExists = true
            }
        }
        if !eventAlreadyExists {
            do {
                try appleEventStore.save(event, span: .thisEvent)
                self.alert = UIAlertController(title: "congrats!", message: "your appointment has been added to your calendar", preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(self.alert!, animated: true, completion: nil)
            } catch let e as NSError {
                print(e.description)
                self.alert = UIAlertController(title: "uh oh!", message: "something went wrong adding your appointment to the calendar! please try again later", preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(self.alert!, animated: true, completion: nil)
                return
            }
        } else {
            self.alert = UIAlertController(title: "uh oh!", message: "you've already added this appointment to your calendar!", preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(self.alert!, animated: true, completion: nil)
        }
    }

}

//MARK: - Handling Contact Location Texting
extension AppointmentDetailView:  MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            
        controller.dismiss(animated: true, completion: nil)
        
        if result == .sent {
            let alert = UIAlertController(title: "success!", message: "you've successfully sent your message to \(location!.name)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else if result == .cancelled {
            print("cancelled - no message sent")
        }
    }
    
    func sendMessage() {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.recipients = [location!.phone]
            controller.body = "Hi \(location!.name)"
            controller.messageComposeDelegate = self
            self.present(controller, animated: false, completion: nil)
        } else {
            let alert = UIAlertController(title: "bummer!", message: "it looks like your device is ineligble to send text messages, please try again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}
