//
//  ServicesViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import NVActivityIndicatorView
import Firebase
import BonMot
import GMStepper

class ServicesView: UIViewController {
    
    var foundMemberships = false
    var gotServiceImages = false
    
    var alert: UIAlertController?
    
    var firstLoad = true
    
    var activityIndicator: NVActivityIndicatorView! {
        didSet {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        }
    }
    var activityIndicatorContainerView: UIView! {
        didSet {
            activityIndicatorContainerView.isHidden = false
            activityIndicatorContainerView.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            activityIndicatorContainerView.layer.cornerRadius = 4
            activityIndicatorContainerView.layer.masksToBounds = true
        }
    }
    
    var cellInfo: [Int: ServicePageCellInfo] = [:]
    var cellHeights: [IndexPath : CGFloat] = [:]
  
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func segmentControl(_ sender: Any) {
        servicesTableView.reloadData()
        if segmentControl.selectedSegmentIndex == 1  { //tanning
            if servicesTableView.numberOfRows(inSection: 0) > 0 { //prevents scrollToRow from scrolling to null
                let firstRow = IndexPath.init(row: 0, section: 0)
                servicesTableView.scrollToRow(at: firstRow, at: .none, animated: true)
            }
            segmentControl.tintColor = Design.Colors.brown
        } else { //sugaring
            segmentControl.tintColor = Design.Colors.blue
        }
    }
    
    @IBOutlet weak var servicesTableView: UITableView! {
        didSet {
            servicesTableView.isHidden = true
        }
    }

    @IBOutlet weak var confirmButtonSpacer: UIButton!
    
    @IBOutlet weak var confirmButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var confirmButton: UIButton!
    @IBAction func confirmButton(_ sender: Any) {
        if !MembershipPurchase.membershipsSelected.isEmpty {
            performSegue(withIdentifier: "toMembershipsSegue", sender: nil)
        } else if AppointmentSearch.selectedServices.count != 0 {
            performSegue(withIdentifier: "toDateSegue", sender: nil)
        } else {
            alert = UIAlertController(title: "uh oh!", message: "you'll need to have at least once service in order to proceed with your booking. tap to select an appointment to continue", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
        }
    }
    
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //MARK: - Set Back Navigation Button
        let backButton: UIButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back_arrow"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        backButton.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.navigationItem.leftBarButtonItems = [backBarButton]
        
        //MARK: - Create Activity Indicator
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.view.addSubview(activityIndicatorContainerView)
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: view.center.x - 30, y: view.center.y, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(activityIndicator)
        
        //MARK: - Set Up Tables
        servicesTableView.dataSource = self
        servicesTableView.delegate = self
        
        //MARK: - Set Continue Button
        setContinueButton()
    }
    
    
    lazy var runOnce : Void = {
        
        BookerAPI().getServicesImages(methodCompletion: { (imageSuccess, imageError) in
            
            DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
            
            guard imageSuccess else {
                print("Failure to Get Services Images: \(imageError)")
                NotificationCenter.default.post(name: .alertToPresent, object: "it seems there was an issue retrieving the services. please try again later")
                return
            }
            self.gotServiceImages = true
            NotificationCenter.default.post(name: .finishedAPIRun, object: nil)
        })
        
        CustomerAPI().findMemberships(methodCompletion: { (success, error) in
            guard success else {
                NotificationCenter.default.post(name: .alertToPresent, object: "it seems there was an issue viewing your active memberships. please try again later")
                print("failed to view memberships: \(error)")
                return
            }
            self.foundMemberships = true
            NotificationCenter.default.post(name: .finishedAPIRun, object: nil)
        })
        
    }()
    
    @objc func finishedAPIRun(notification: Notification) {
        guard foundMemberships && gotServiceImages else {
            return
        }
        
        DispatchQueue.main.async {
            self.cellInfo = [:]
            self.servicesTableView.reloadData()
            self.servicesTableView.isHidden = false
            self.activityIndicator.isHidden = true
            self.activityIndicatorContainerView.isHidden = true
        }
    }

    @objc func presentAlert(notification: Notification){
        
        DispatchQueue.main.async {
            guard let message = notification.object as? String else {
                print("error: no message available")
                return
            }
            
            let presentedAlert = UIAlertController(title: "uh oh!", message: message, preferredStyle: .alert)
            presentedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(presentedAlert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        Analytics.setScreenName("ServicesView", screenClass: "app")
        if firstLoad {
            firstLoad = false
        } else {
            servicesTableView.reloadData()
        }
        
        //MARK: - Set Up Observers
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectRow), name:
            .cellButtonTapped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(serviceQuantityChange), name:
            .serviceQuantityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentAlert), name: .alertToPresent, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishedAPIRun), name: .finishedAPIRun, object: nil)
        
        //MARK: - Get Customer's Memberships and Service Images
        let _ = runOnce
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityIndicatorContainerView.center = view.center
        activityIndicator.center = view.center
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func computedIndex(indexPath: IndexPath) -> Int {
        var index = indexPath.row
        if segmentControl.selectedSegmentIndex == 1 { index += 10 }
        return index
    }
    
    @objc func serviceQuantityChange(fromNotification: Notification) {
        
        let pickerValue = fromNotification.object as! Int

        guard let indexPath = servicesTableView.indexPath(for: (fromNotification.userInfo as! [String: UITableViewCell])["cell"]!) else {
            print("error - failed to get indexPath for cell")
            return
        }
        let index = computedIndex(indexPath: indexPath)
        
        let service = AppointmentSearch.location!.services.first { (service) -> Bool in service.id == AppointmentSearch.location!.servicesOrder[index] }
        guard service != nil else {
            print("error indexing services -- service quantity not changed")
            return
        }
        
        if cellInfo[index]!.stepperValue < pickerValue { //increase button selected
            
            let DISABLE_MULTI_SERVICE = true
            guard !DISABLE_MULTI_SERVICE else {
                let alert = UIAlertController(title: "sorry!", message: "multiple service booking isn't available right now, but check back on our next update!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            AppointmentSearch.selectedServices.appendService(service: service!)
            
        } else { //decrease button selected
            if let itemIndex = AppointmentSearch.selectedServices.firstIndex(where: { (s) -> Bool in s.equals(s2: service) }) {
                AppointmentSearch.selectedServices.remove(at: itemIndex)
            } else {
                print("error - no service to remove")
            }
        }
        
        cellInfo[index]!.stepperValue = pickerValue //reset stepperValue
        setContinueButton()
    }

    func setContinueButton(){
        
        if !MembershipPurchase.membershipsSelected.isEmpty {
            confirmButton.setTitle("CONTINUE", for: .normal)
            confirmButtonHeight.constant = 50
            confirmButtonSpacer.isHidden = false
            confirmButton.isHidden = false
        } else if AppointmentSearch.selectedServices.count == 0 {
            confirmButtonHeight.constant = 0
            confirmButtonSpacer.isHidden = true
            confirmButton.isHidden = true
        } else {
            let treatmentCount = AppointmentSearch.selectedServices.count + MembershipPurchase.membershipsSelected.count
            if treatmentCount == 1 {
                confirmButton.setTitle("CONTINUE BOOKING", for: .normal)
            } else {
                confirmButton.setTitle("CONTINUE BOOKING (\(treatmentCount))", for: .normal)
            }
            
            confirmButtonHeight.constant = 50
            confirmButtonSpacer.isHidden = false
            confirmButton.isHidden = false
        }
    }
    
}

//MARK: - Configuring Data for Cells
extension ServicesView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard AppointmentSearch.location!.services.count != 0 else {
            return 0
        }
        
        if segmentControl.selectedSegmentIndex == 1 {
            return 1 //tanning
        } else {
            return 7 //sugaring
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //MARK: - Adjust Settings for Type of Service
        let index = computedIndex(indexPath: indexPath)
        var color = Design.Colors.blue
        if segmentControl.selectedSegmentIndex == 1 {
            color = Design.Colors.brown
        }
        
        //MARK: - Service for Cell
        guard let service = (AppointmentSearch.location!.services.first { (service) -> Bool in service.id == AppointmentSearch.location!.servicesOrder[index] }) else {
            print("error indexing services")
            return tableView.dequeueReusableCell(withIdentifier: "serviceCell") as! ServiceCell
        }
        
        //MARK: - Set Initial Values for Cell Data
        if cellInfo.index(forKey: index) == nil {
            
            /* ADDED TO DISABLE MEMEBERSHIPS */
            
            cellInfo[index] = ServicePageCellInfo(selection: .noSelection, color: color, stepperValue: 1, stepperState: .hidden, type:  .serviceNoMembershipCell(service))
            
            /* REMOVED TO DISABLE MEMBERSHIPS
            
            if Customer.memberships.first(where: { (m) -> Bool in m.eligibleServiceNames.contains(service.name.lowercased()) }) != nil  {
                //There is a match between customer memberships benefits and cell's service customer's current memberships
                cellInfo[index] = ServicePageCellInfo(selection: .noSelection, color: color, stepperValue: 1, stepperState: .hidden, type:  .membershipServiceCell(service))
                
            } else if let membership = SugaredAndBronzed.memberships.first(where: { (m) -> Bool in m.name == service.membershipCorrelated })  {
                //The present service is not eligible for any of the customer's current memberships
                cellInfo[index] = ServicePageCellInfo(selection: .noSelection, color: color, stepperValue: 1, stepperState: .hidden, type:  .serviceCell(service, membership))
            } else {
                cellInfo[index] = ServicePageCellInfo(selection: .noSelection, color: color, stepperValue: 1, stepperState: .hidden, type:  .serviceNoMembershipCell(service))
            }
            */
        }
        cellInfo[index]!.color = color //force color reset regardless of full cell reset
        
        //MARK: Set Data for Each Cell Type
        switch cellInfo[index]!.type {
        case .membershipServiceCell:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "membershipServiceCell") as! MembershipServiceCell
        
            cell.setCellColors(color: cellInfo[index]!.color, selection: cellInfo[index]!.selection)
            cell.stepperState = cellInfo[index]!.stepperState
            cell.serviceImageView.image = service.image
            cell.service = service
            return cell
            
        case .serviceCell(_, let membership):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "serviceCell") as! ServiceCell
            cell.membership = membership
    
            cell.setCellColors(color: cellInfo[index]!.color, selection: cellInfo[index]!.selection)
            cell.stepperState = cellInfo[index]!.stepperState
            cell.serviceImageView.image = service.image
            cell.service = service
        
            return cell
            
        case .serviceNoMembershipCell(let service):
            let cell = tableView.dequeueReusableCell(withIdentifier: "serviceNoMembershipCell") as! ServiceNoMembershipCell
            cell.service = service
            
            cell.setCellColors(color: cellInfo[index]!.color, selection: cellInfo[index]!.selection)
            cell.stepperState = cellInfo[index]!.stepperState
            cell.serviceImageView.image = service.image
            
            return cell
        }
    }

}

extension ServicesView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Nothing happens here because the individual button selection already handles
    }

    
    @objc func didSelectRow(fromNotification: Notification) {
        
        let buttonType = fromNotification.object as! String
        
        guard let indexPath = servicesTableView.indexPath(for: (fromNotification.userInfo as! [String: UITableViewCell])["cell"]!) else {
            print("error - failed to get indexPath for cell")
            return
        }
        let index = computedIndex(indexPath: indexPath)
        
        //MARK: - ServiceCell ~ membership button
        if buttonType == "membershipButton" {
            
            
            
            let DISABLE_MEMBERSHIPS = true
            guard !DISABLE_MEMBERSHIPS else {
                let alert = UIAlertController(title: "sorry!", message: "membership purchasing isn't available yet through the app, stay tuned!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            

            
            switch cellInfo[index]!.selection {
            case .noSelection, .singleService:
                cellInfo[index]!.selection = .membership
            default:
                cellInfo[index]!.selection = .noSelection
            }
        
        //MARK: - ServiceCell ~ single service button
        } else if buttonType == "serviceButton" {
            
            switch cellInfo[index]!.selection {
            case .noSelection, .membership:
                
                
                /* MAKING MULTI - SERVICE NOT AVAILALE UNTIL BOOKER FIXES ITS SHIT */
                
                
                
                guard AppointmentSearch.selectedServices.count < 1 else  {
                    let alert = UIAlertController(title: "sorry!", message: "multiple service booking isn't available right now, but check back on our next update!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return                 }
                cellInfo[index]!.selection = .singleService
            default:
                cellInfo[index]!.selection = .noSelection
            }
            
        //MARK: - MembershipServiceCell ~ service button, uses membership tag
        } else if buttonType == "membershipServiceButton" {

            switch cellInfo[index]!.selection {
            case .noSelection:
                cellInfo[index]!.selection = .singleService
            default:
                cellInfo[index]!.selection = .noSelection

            }
        }
        
        switch cellInfo[index]!.type {
        case .membershipServiceCell(let service):
            
            //MARK: - MembershipService Cell Cases
            switch cellInfo[index]!.selection {
            case .singleService:
                AppointmentSearch.selectedServices.appendService(service: service)
                
                if ["sprinkle", "teaspoon", "tablespoon", "spoonful", "ladle"].contains(service.name.lowercased()) {
                    cellInfo[index]!.stepperState = .visible
                }
                
            default:
                cellInfo[index]!.stepperState = .hidden
                AppointmentSearch.selectedServices.removeAll(where: { (s) -> Bool in s.equals(s2: service) })
            }
            
        case .serviceCell(let service, let membership):
            
            //MARK: - Service Cell Cases
            switch cellInfo[index]!.selection {
            case .membership:
                
                if AppointmentSearch.selectedServices.first(where: { (s) -> Bool in s.equals(s2: service) }) == nil {
                    AppointmentSearch.selectedServices.appendService(service: service)
                }
                MembershipPurchase.membershipsSelected.append(membership)
                
                cellInfo[index]!.stepperState = .hidden
                
            case .singleService:
                
                if AppointmentSearch.selectedServices.first(where: { (s) -> Bool in s.equals(s2: service) }) == nil {
                    AppointmentSearch.selectedServices.appendService(service: service)
                }
                MembershipPurchase.membershipsSelected.removeAll(where: { (m) -> Bool in  m.equals(m2: membership ) } )
                
                
                if ["sprinkle", "teaspoon", "tablespoon", "spoonful", "ladle"].contains(service.name.lowercased()) {
                    cellInfo[index]!.stepperState = .visible
                }
                
            case .noSelection:
                
                MembershipPurchase.membershipsSelected.removeAll(where: { (m) -> Bool in  m.equals(m2: membership ) } )
                AppointmentSearch.selectedServices.removeAll(where: { (s) -> Bool in s.equals(s2: service)  })
                cellInfo[index]!.stepperState = .hidden
            }
            
            
        case .serviceNoMembershipCell(let service):
            switch cellInfo[index]!.selection {
            case .singleService:
                AppointmentSearch.selectedServices.appendService(service: service)
                
                if ["sprinkle", "teaspoon", "tablespoon", "spoonful", "ladle"].contains(service.name.lowercased()) {
                    cellInfo[index]!.stepperState = .visible
                }
                
            case .noSelection, .membership:
                cellInfo[index]!.stepperState = .hidden
                AppointmentSearch.selectedServices.removeAll(where: { (s) -> Bool in s.equals(s2: service) })
            }
        }
        
        //MARK: - Reload the Cell
        servicesTableView.reloadRows(at: [indexPath], with: .none)
        
        //MARK: - Reset Bottom Continue Bar
        setContinueButton()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //Adjusting for various text sizes of the descriptions
        var index = indexPath.row
        if segmentControl.selectedSegmentIndex == 1 {
            index += 10 //tanning
        } else {
            index = indexPath.row
        }
        
        let service = AppointmentSearch.location!.services.first { (service) -> Bool in service.id == AppointmentSearch.location!.servicesOrder[index] }
        guard service != nil else {
            print("error indexing services")
            return 300
        }
        
        let lineCount = 1 + (service!.description.count / 50)
        var lineSize = 17
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2688: //iPhone XsMax
                lineSize = 22
            default: //other size
                break
            }
        }
        var baseCellSize = 0
        if Customer.memberships.first(where: { (m) -> Bool in m.eligibleServiceNames.contains(service!.name.lowercased()) }) != nil {
            //Membership Cell
            baseCellSize = 350
        } else {
            baseCellSize = 360
        }
        let size = CGFloat(baseCellSize + (lineCount * lineSize))
        return size
        
    }
    

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 350.0 //setting estimated height prevents cell jumping on reload
    }
}



//MARK: - Standard Service or Membership Cell
class ServiceCell: UITableViewCell {
    
    var service: Service? {
        didSet {
            nameLabel.text = service!.name.uppercased()
            descriptionLabel.text = service!.description
            singleServicePriceLabel.text = "$\(service!.price)/service"
            durationLabel.text = "∙ \(service!.duration) min ∙"
        }
    }
    
    var membership: Membership? {
        didSet {
            guard membership != nil else {
                return
            }
            if AppointmentSearch.location!.upcharge {
                membershipPriceLabel.text = "$\(membership!.priceNYC)/month"
            } else {
                membershipPriceLabel.text = "$\(membership!.priceWest)/month"
            }
            
        }
    }
    
    @IBOutlet weak var serviceImageView: UIImageView!
    
    @IBOutlet weak var membershipButton: UIButton! {
        didSet {
            membershipButton.layer.cornerRadius = 4
            membershipButton.layer.masksToBounds = true
            membershipButton.layer.borderWidth = 2.0
            membershipButton.titleLabel!.numberOfLines = 0
            membershipButton.titleLabel!.lineBreakMode = .byWordWrapping
            membershipButton.titleLabel!.textAlignment = .center
        }
    }
    
    @IBAction func membershipButton(_ sender: Any) {
        NotificationCenter.default.post(name: .cellButtonTapped, object: "membershipButton", userInfo: ["cell": self] )
    }
    @IBOutlet weak var singleServiceButton: UIButton! {
        didSet {
            singleServiceButton.layer.cornerRadius = 4
            singleServiceButton.layer.masksToBounds = true
            singleServiceButton.layer.borderWidth = 1.0
            
            //CHANGE BACK TO ONE-TIME APPOINTMENT
            
            
            singleServiceButton.setTitle(" SELECT ", for: .normal)
            singleServiceButton.titleLabel!.numberOfLines = 0
            singleServiceButton.titleLabel!.lineBreakMode = .byWordWrapping
            singleServiceButton.titleLabel!.textAlignment = .center
        }
    }
    @IBAction func singleServiceButton(_ sender: Any) {
        NotificationCenter.default.post(name: .cellButtonTapped, object: "serviceButton", userInfo: ["cell": self] )
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var singleServicePriceLabel: UILabel!
    @IBOutlet weak var membershipPriceLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    private var stepperSpacerValue: CGFloat = 0
    private var stepperWidthValue: CGFloat = 0
    private var stepperLabelWidthValue: CGFloat = 0
    
    @IBOutlet weak var stepperLabel: UILabel!
    @IBOutlet weak var serviceQuantityStepper: GMStepper! {
        didSet {
            serviceQuantityStepper.labelFont = UIFont(name: "AvenirNext-Medium", size: 12)!
        }
    }
    @IBAction func serviceQuantityStepper(_ sender: GMStepper) {
        NotificationCenter.default.post(name: .serviceQuantityChanged, object: Int(sender.value), userInfo: ["cell": self] )
    }
    
    @IBOutlet weak var stepperWidth: NSLayoutConstraint! {
        didSet {
            if stepperWidth.constant != 0 {
                stepperWidthValue = stepperWidth.constant
            }
        }
    }
    
    @IBOutlet weak var stepperSpacer: NSLayoutConstraint! {
        didSet {
            if stepperSpacer.constant != 0 {
                stepperSpacerValue = stepperSpacer.constant
            }
        }
    }
    
    @IBOutlet weak var stepperLabelWidth: NSLayoutConstraint! {
        didSet {
            if stepperLabelWidth.constant != 0 {
                stepperLabelWidthValue = stepperLabelWidth.constant
            }
        }
    }
    
    //MARK: - Show/Hide the Stepper
    var stepperState: StepperState? {
        didSet {
            switch stepperState! {
            case .visible:
                guard stepperSpacerValue != 0 else {
                    return
                }
                stepperWidth.constant = stepperWidthValue
                stepperSpacer.constant = stepperSpacerValue
                stepperLabelWidth.constant = stepperLabelWidthValue
                
            case .hidden:
                stepperWidth.constant = 0
                stepperSpacer.constant = 0
                stepperLabelWidth.constant = 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    func setCellColors(color: UIColor, selection: ServiceSelectionType) {
        singleServiceButton.layer.borderColor = color.cgColor
        membershipButton.layer.borderColor = color.cgColor
        singleServicePriceLabel.textColor = color
        membershipPriceLabel.textColor = color
        durationLabel.textColor = color
        
        //MARK: - Set Selection Coloration
        switch selection {
        case .membership: //membership selected, singleService deselected
            membershipButton.backgroundColor = color
            membershipButton.setAttributedTitle( membershipButtonString(withColor: .white), for: .normal)
            singleServiceButton.backgroundColor = .white
            singleServiceButton.setTitleColor(color, for: .normal)
        case .singleService: //singleService selected, membership deselected
            singleServiceButton.backgroundColor = color
            singleServiceButton.setTitleColor(.white, for: .normal)
            membershipButton.backgroundColor = .white
            membershipButton.setAttributedTitle( membershipButtonString(withColor: color), for: .normal)
        case .noSelection: //neither selected
            membershipButton.backgroundColor = .white
            membershipButton.setAttributedTitle( membershipButtonString(withColor: color), for: .normal)
            singleServiceButton.backgroundColor = .white
            singleServiceButton.setTitleColor(color, for: .normal)
        }
    }
    
    func membershipButtonString(withColor: UIColor) -> NSAttributedString{
        return "<header>MEMBERSHIP</header> <BON:nextLine/><bold>SAVE 20%</bold>".styled(with:
            .color(withColor), .xmlRules([
                .style("header", StringStyle( .font( UIFont(name: "AvenirNext-Regular", size: 15)! ))),
                .style("bold", StringStyle( .font( UIFont(name: "AvenirNext-DemiBold", size: 13)! ))),
                ])
        )
    }
    
}

///MARK: - Existing Membership Cell
class MembershipServiceCell: UITableViewCell {
    
    var service: Service? { //the service attached with a customer's membership
        didSet {
            nameLabel.text = service!.name.uppercased()
            descriptionLabel.text = service!.description
            durationLabel.text = "∙ \(service!.duration) min ∙"
        }
    }
    
    @IBOutlet weak var serviceImageView: UIImageView!
    @IBOutlet weak var membershipButton: UIButton! {
        didSet {
            membershipButton.layer.cornerRadius = 4
            membershipButton.layer.masksToBounds = true
            membershipButton.layer.borderWidth = 1.0
            membershipButton.setTitle("MEMBERSHIP \nSERVICE", for: .normal)
            membershipButton.titleLabel!.numberOfLines = 0
            membershipButton.titleLabel!.lineBreakMode = .byWordWrapping
            membershipButton.titleLabel!.textAlignment = .center
        }
    }
    @IBAction func membershipButton(_ sender: Any) {
        NotificationCenter.default.post(name: .cellButtonTapped, object: "membershipServiceButton", userInfo: ["cell": self])
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    private var stepperSpacerValue: CGFloat = 0
    private var stepperWidthValue: CGFloat = 0
    private var stepperLabelWidthValue: CGFloat = 0
    
    @IBOutlet weak var serviceQuantityStepper: GMStepper! {
        didSet {
            serviceQuantityStepper.labelFont = UIFont(name: "AvenirNext-Medium", size: 12)!
        }
    }
    @IBAction func serviceQuantityStepper(_ sender: GMStepper) {
        NotificationCenter.default.post(name: .serviceQuantityChanged, object: Int(sender.value), userInfo: ["cell": self] )
    }
    
    @IBOutlet weak var stepperWidth: NSLayoutConstraint! {
        didSet {
            if stepperWidth.constant != 0 {
                stepperWidthValue = stepperWidth.constant
            }
        }
    }
    
    @IBOutlet weak var stepperSpacer: NSLayoutConstraint! {
        didSet {
            if stepperLabelWidth.constant != 0 {
                stepperSpacerValue = stepperSpacer.constant
            }
        }
    }
    
    @IBOutlet weak var stepperLabelWidth: NSLayoutConstraint! {
        didSet {
            if stepperLabelWidth.constant != 0 {
                stepperLabelWidthValue = stepperLabelWidth.constant
            }
        }
    }

    var stepperState: StepperState? {
        didSet {
            switch stepperState! {
            case .visible:
                guard stepperWidthValue != 0 else {
                    print("unset values for showing")
                    return
                }
                stepperWidth.constant = stepperWidthValue
                stepperSpacer.constant = stepperSpacerValue
                stepperLabelWidth.constant = stepperLabelWidthValue
 
            case .hidden:
                stepperWidth.constant = 0
                stepperSpacer.constant = 0
                stepperLabelWidth.constant = 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func setCellColors(color: UIColor, selection: ServiceSelectionType) {
        membershipButton.layer.borderColor = color.cgColor
        durationLabel.textColor = color
    
        switch selection {
        case .singleService: // selected
            membershipButton.backgroundColor = color
            membershipButton.setTitleColor(.white, for: .normal)
        default: // deselected
            membershipButton.backgroundColor = UIColor.white
            membershipButton.setTitleColor(color, for: .normal)
        }
    }
    
}

//MARK: - Service w/o Membership Attached Cell
class ServiceNoMembershipCell: UITableViewCell {
    
    var service: Service? { //the service attached with a customer's membership
        didSet {
            nameLabel.text = service!.name.uppercased()
            descriptionLabel.text = service!.description
            durationLabel.text = "∙ \(service!.duration) min ∙"
            priceLabel.text = "$\(service!.price)/service"
        }
    }
    
    @IBOutlet weak var serviceImageView: UIImageView!
    @IBOutlet weak var singleServiceButton: UIButton! {
        didSet {
            
            singleServiceButton.layer.cornerRadius = 4
            singleServiceButton.layer.masksToBounds = true
            singleServiceButton.layer.borderWidth = 1.0
            singleServiceButton.setTitle(" SELECT ", for: .normal)
            singleServiceButton.titleLabel!.numberOfLines = 0
            singleServiceButton.titleLabel!.lineBreakMode = .byWordWrapping
            singleServiceButton.titleLabel!.textAlignment = .center
        }
    }
    @IBAction func singleServiceButton(_ sender: Any) {
        NotificationCenter.default.post(name: .cellButtonTapped, object: "serviceButton", userInfo: ["cell": self])
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    private var stepperSpacerValue: CGFloat = 0
    private var stepperWidthValue: CGFloat = 0
    private var stepperLabelWidthValue: CGFloat = 0
    
    @IBOutlet weak var serviceQuantityStepper: GMStepper! {
        didSet {
            serviceQuantityStepper.labelFont = UIFont(name: "AvenirNext-Medium", size: 12)!
        }
    }
    @IBAction func serviceQuantityStepper(_ sender: GMStepper) {
        NotificationCenter.default.post(name: .serviceQuantityChanged, object: Int(sender.value), userInfo: ["cell": self] )
    }
    
    @IBOutlet weak var stepperWidth: NSLayoutConstraint! {
        didSet {
            if stepperWidth.constant != 0 {
                stepperWidthValue = stepperWidth.constant
            }
        }
    }
    
    @IBOutlet weak var stepperSpacer: NSLayoutConstraint! {
        didSet {
            if stepperLabelWidth.constant != 0 {
                stepperSpacerValue = stepperSpacer.constant
            }
        }
    }
    
    @IBOutlet weak var stepperLabelWidth: NSLayoutConstraint! {
        didSet {
            if stepperLabelWidth.constant != 0 {
                stepperLabelWidthValue = stepperLabelWidth.constant
            }
        }
    }
    
    var stepperState: StepperState? {
        didSet {
            switch stepperState! {
            case .visible:
                guard stepperWidthValue != 0 else {
                    print("unset values for showing")
                    return
                }
                stepperWidth.constant = stepperWidthValue
                stepperSpacer.constant = stepperSpacerValue
                stepperLabelWidth.constant = stepperLabelWidthValue
                
            case .hidden:
                stepperWidth.constant = 0
                stepperSpacer.constant = 0
                stepperLabelWidth.constant = 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func setCellColors(color: UIColor, selection: ServiceSelectionType) {
        singleServiceButton.layer.borderColor = color.cgColor
        durationLabel.textColor = color
        priceLabel.textColor = color
        
        switch selection {
        case .singleService: //service selected
            singleServiceButton.backgroundColor = color
            singleServiceButton.setTitleColor(.white, for: .normal)
        default: //service deselected
            singleServiceButton.backgroundColor = UIColor.white
            singleServiceButton.setTitleColor(color, for: .normal)
        }
    }
}


//MARK: - Organization and Structures for ServiceView
struct ServicePageCellInfo {
    var selection: ServiceSelectionType
    var color: UIColor
    var stepperValue: Int
    var stepperState: StepperState
    var type: ServicePageCell
    
    init(selection: ServiceSelectionType, color: UIColor, stepperValue: Int, stepperState: StepperState, type: ServicePageCell){
        self.selection = selection
        self.color = color
        self.stepperValue = stepperValue
        self.stepperState = stepperState
        self.type = type
    }
}

enum ServicePageCell {
    case membershipServiceCell(Service)
    case serviceCell(Service, Membership)
    case serviceNoMembershipCell(Service)
}

enum ServiceSelectionType {
    case membership
    case singleService
    case noSelection
}

enum StepperState {
    case visible
    case hidden
}

extension Notification.Name {
    static let cellButtonTapped = Notification.Name("cellButtonTapped")
    static let serviceQuantityChanged = Notification.Name("serviceQuantityChanged")
    static let finishedAPIRun = Notification.Name("finishedAPIRun")
}


//this extension keeps the services in the correct order for booking, first sugaring, then tanning
extension Array where Element: Service {
    mutating func appendService(service: Element){
        switch service.type { //ServiceType
        case .sugaring:
            self.insert(service, at: 0) //should be booked first
            break
        default: //tanning, other
            self.append(service) //add to end of list
            break
        }
    }
}
