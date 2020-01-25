//
//  MembershipsView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import NVActivityIndicatorView
import Firebase

class MembershipsView: UIViewController {
    
    var alert: UIAlertController?
    
    var activityIndicator: NVActivityIndicatorView!
    var activityIndicatorContainerView: UIView!
    
    let imageNames = ["bronzed_standard", "sugared_tablespoon", "sugared_sprinkle", "sugared_teaspoon", "sugared_brazillian", "sugared_bikini", "sugared_sprinkle", "sugared_teaspoon", "sugared_tablespoon", "sugared_spoonful", "sugared_ladle", "bronzed_standard", "sugared_brazillian", "sugared_bikini", "sugared_sprinkle"] //NEED MORE IMAGES
    

  
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func segmentControl(_ sender: Any) {
        membershipsTableView.reloadData()
        membershipsTableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .none, animated: true)
        switch segmentControl.selectedSegmentIndex {
            
        case 2: //Combo
            segmentControl.tintColor = Design.Colors.gray.withAlphaComponent(0.7)

        case 1: //Tanning
            segmentControl.tintColor = Design.Colors.brown
            
        case 0: // Sugaring
            segmentControl.tintColor = Design.Colors.blue
            
        default:
            break
            
        }
    }
    */
    
    @IBOutlet weak var membershipsTableView: UITableView!

    @IBOutlet weak var confirmButtonSpacer: UIButton!
    @IBOutlet weak var confirmButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var confirmButton: UIButton!
    @IBAction func confirmButton(_ sender: Any) {
        if !MembershipPurchase.membershipsSelected.isEmpty {
            performSegue(withIdentifier: "toConfirmationViewSegue", sender: nil)
        } else {
            alert = UIAlertController(title: "uh oh!", message: "you'll need to have selected a membership in order to proceed with your purchase. tap to select an appointment to continue", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert!, animated: true, completion: nil)
        }
    }
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("MembershipsView", screenClass: "app")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MembershipPurchase.membershipsSelected = []
        
        membershipsTableView.dataSource = self
        membershipsTableView.delegate = self
        
        if MembershipPurchase.membershipsSelected.isEmpty {
            confirmButtonHeight.constant = 0
            confirmButtonSpacer.isHidden = true
            confirmButton.isHidden = true
        } else {
            confirmButtonHeight.constant = 60
            confirmButtonSpacer.isHidden = false
            confirmButton.isHidden = false
        }
        
        
    
    }

    
    
   

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        /*
        var type: ServiceType = .unknown
        switch segmentControl.selectedSegmentIndex {
        case 2: //Combo
            type = .combo
        case 1: //Tanning
            type = .tanning
        case 0: //Hair Removal
            type = .sugaring
        default:
            break
        }
         let membership = SugaredAndBronzed.memberships.filter( { (membership) in membership.type == type })[indexPath.row]
        */
        
        let membership = SugaredAndBronzed.memberships[indexPath.row]
        let text = membership.description
        let lineCount = 1 + (text.count / 50)
        var lineSize = 17
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2688: //iPhone XsMax
                lineSize = 22
            default: //other size
                break
            }
        }
        let size = CGFloat(320 + (lineCount * lineSize))
        return size
        
    }

}

extension MembershipsView: UITableViewDataSource {
    
     // MARK: - Configuring Cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SugaredAndBronzed.memberships.count
        /*
        switch segmentControl.selectedSegmentIndex {
        case 2: //Combo
            return 2
        case 1: //Tanning
            if SugaredAndBronzed.runType == "PROD" {
                return 4
            } else {
                return 2 //no savvy memberships on the test server
            }
        case 0: //Hair Removal
            return 7
        default:
            return 0
        }
         */
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "membershipInfoCell") as! MembershipCell
        cell.buttonLabel.layer.cornerRadius = 4
        cell.buttonLabel.layer.masksToBounds = true
        cell.buttonLabel.layer.borderWidth = 1.0
        
        cell.selectionStyle = .none
        
        let mainColor = Design.Colors.blue
        /*
        var type: ServiceType = .unknown
        FOR ORGANIZING BY TYPE - DEPRECATED
        switch segmentControl.selectedSegmentIndex {
        case 2: //Combo
            type = .combo
            mainColor = Design.Colors.gray.withAlphaComponent(0.7)
        case 1: //Tanning
            type = .tanning
            mainColor = Design.Colors.brown
        case 0: //Hair Removal
            type = .sugaring
            mainColor = Design.Colors.blue
            
        default:
            break
        }
         let membership = SugaredAndBronzed.memberships.filter( { (membership) in membership.type == type })[indexPath.row]
         */
        
        let membership = SugaredAndBronzed.memberships[indexPath.row]
        
        cell.nameLabel.text = membership.name
        cell.descriptionLabel.text = membership.description
        if MembershipPurchase.location!.upcharge  {
             cell.priceLabel.text = "$\(membership.priceNYC)" ////+$10 for NYC locations!
        } else {
            cell.priceLabel.text = "$\(membership.priceWest)"
        }
       
        cell.quantityLabel.text = "\(membership.quantityOfBenefits())x per month"
        
        
        //change this to an actual service image! and modify the type so that it aligns with the variable type as well!!!
        cell.membershipImageView.image = UIImage(named: imageNames[indexPath.row])
        
        cell.buttonLabel.layer.borderColor = mainColor.cgColor
        
        //sets the selected or unselected style each time the table resets
        if !MembershipPurchase.membershipsSelected.isEmpty &&  MembershipPurchase.membershipsSelected.contains(where: { (m) -> Bool in  m.equals(m2: membership ) }) {
            //selected style
            cell.buttonLabel.backgroundColor = mainColor
            cell.buttonLabel.textColor = UIColor.white
            cell.buttonLabel.text = "SELECTED"
        } else {
            //unselected style
            cell.buttonLabel.backgroundColor = UIColor.white
            cell.buttonLabel.textColor = mainColor
            cell.buttonLabel.text = "SELECT"
        }
        return cell
    }
}

extension MembershipsView: UITableViewDelegate {
    
    // MARK: - Handling Cell Selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let mainColor = Design.Colors.blue
        
        /*
        var type: ServiceType = .unknown
        switch segmentControl.selectedSegmentIndex {
        case 2: //Combo
            type = .combo
            mainColor = Design.Colors.gray.withAlphaComponent(0.7)
        case 1: //Tanning
            type = .tanning
            mainColor = Design.Colors.brown
        case 0: //Hair Removal
            type = .sugaring
            mainColor = Design.Colors.blue
        default:
            break
        }
        let membership = SugaredAndBronzed.memberships.filter( { (membership) in membership.type == type })[indexPath.row]
         */
        
        let membership = SugaredAndBronzed.memberships[indexPath.row]
        
        
        if MembershipPurchase.membershipsSelected.isEmpty ||  !MembershipPurchase.membershipsSelected.contains(where: { (m) -> Bool in  m.equals(m2: membership ) } ) {
            MembershipPurchase.membershipsSelected.append(membership)
            
            //sets the selected style when the cell is clicked
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.backgroundColor = mainColor
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.textColor = UIColor.white
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.text = "SELECTED"
            
            
        } else {
            MembershipPurchase.membershipsSelected.removeAll(where: { (m) -> Bool in  m.equals(m2: membership ) } )
            
            //sets the selected style when the cell is clicked
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.backgroundColor = UIColor.white
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.textColor = mainColor
            (tableView.cellForRow(at: indexPath) as! MembershipCell).buttonLabel.text = "SELECT"
        
        }
        
        if MembershipPurchase.membershipsSelected.isEmpty {
            confirmButtonHeight.constant = 0
            confirmButtonSpacer.isHidden = true
            confirmButton.isHidden = true
        } else {
            confirmButtonHeight.constant = 60
            confirmButtonSpacer.isHidden = false
            confirmButton.isHidden = false
        }
        //tableView.reloadData() //change selection to automatically scroll to the next page, no need for multiservice UI
        //tableView.scrollToRow(at: indexPath, at: .none, animated: false)
    }
}

class MembershipCell: UITableViewCell {
    
    @IBOutlet weak var membershipImageView: UIImageView!
    @IBOutlet weak var buttonLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!

    
}
