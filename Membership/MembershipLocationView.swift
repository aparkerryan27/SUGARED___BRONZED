//
//  MembershipLocationView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import NVActivityIndicatorView
import Firebase

class MembershipLocationView: UIViewController {
    

    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var activityIndicator: NVActivityIndicatorView!
    var activityIndicatorContainerView: UIView!
    var alert: UIAlertController?
    
    
    //Table View
    @IBOutlet weak var locationTableView: UITableView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("MembershipLocationView", screenClass: "app")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This disables the navigation bar divider that cut off the top shadow
        let img = UIImage()
        self.navigationController?.navigationBar.shadowImage = img
        self.navigationController?.navigationBar.setBackgroundImage(img, for: .default)
            
        locationTableView.delegate = self
        locationTableView.dataSource = self

        definesPresentationContext = true
        locationTableView.reloadData()
    
    }
    
}


extension MembershipLocationView: UITableViewDataSource {
    
    // MARK: - Configuring Cells
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return SugaredAndBronzed.locationIDsByState.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let index = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
        let state = SugaredAndBronzed.locationIDsByState.keys[index]
        guard let locations = SugaredAndBronzed.locationIDsByState[state] else {
            print("error retrieving state for locations page")
            return 0
        }
        return locations.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var state = ""
        
        let section = indexPath.section
        let index = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
        state = SugaredAndBronzed.locationIDsByState.keys[index]
        
        
        let ID = SugaredAndBronzed.locationIDsByState[state]![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell") as! LocationCell
        
        let locationName = SugaredAndBronzed.locations[ID]!.name
        let locationAddress = SugaredAndBronzed.locations[ID]!.street
        let locationPhone = SugaredAndBronzed.locations[ID]!.phone
        let locationHours = "Mon-Fri: 9am-11pm ~ Sat-Sun: 10am–5pm"
    
        cell.locationImage.image = SugaredAndBronzed.locations[ID]!.image ?? UIImage(named: "placeholder_location_image")
        cell.locationName.text = locationName
        cell.hiddenLocationID.text = "\(ID)"
        
        cell.locationDescription.text = "\(locationPhone)\n\(locationHours)\n\(locationAddress)"
        
        cell.locationView.layer.cornerRadius = 4
        cell.locationView.layer.masksToBounds = true
        cell.locationView.backgroundColor = UIColor.white
        cell.backgroundColor = tableView.backgroundColor
        
        cell.selectionStyle = .none
        
        return cell
    }
    
}


extension MembershipLocationView: UITableViewDelegate {
    
    // MARK: - Handling Cell Selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MembershipPurchase.location = SugaredAndBronzed.locations[Int((tableView.cellForRow(at: indexPath) as! LocationCell).hiddenLocationID.text!)!]!
        self.performSegue(withIdentifier: "toMembershipsViewSegue", sender: self)
        MembershipPurchase.membershipsSelected = []
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Handling Header/Footer View
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 450
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        var headerHeight: CGFloat = 20; if section == 0 { headerHeight = 40 }
        let headerLabel = UILabel(frame: CGRect(x: 20, y: 0 , width:
            tableView.bounds.size.width, height: headerHeight))
        headerLabel.font = UIFont(name: "AvenirNext-Medium", size: 20)
        headerLabel.textColor = Design.Colors.gray
        
        let sectionIndex = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
        headerLabel.text = SugaredAndBronzed.locationIDsByState.keys[sectionIndex]
        
        headerView.addSubview(headerLabel)
        return headerView
    }
}
