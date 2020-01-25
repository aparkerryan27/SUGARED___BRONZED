//
//  LocationViewTableView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import UIKit

extension LocationView: UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if !sortedStates.isEmpty {
            let state = sortedStates[section]
            return SugaredAndBronzed.locationIDsByState[state]!.count
        } else {
            let index = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
            let state = SugaredAndBronzed.locationIDsByState.keys[index]
            guard let locations = SugaredAndBronzed.locationIDsByState[state] else {
                print("error retrieving state for locations page")
                return 0
            }
            return locations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var state = ""
        if !sortedStates.isEmpty {
            state = sortedStates[indexPath.section]
        } else {
            let section = indexPath.section
            let index = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
            state = SugaredAndBronzed.locationIDsByState.keys[index]
        }
        
        let ID = SugaredAndBronzed.locationIDsByState[state]![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell") as! LocationCell
        
        let locationName = SugaredAndBronzed.locations[ID]!.name
        let locationAddress = SugaredAndBronzed.locations[ID]!.street
        let locationPhone = SugaredAndBronzed.locations[ID]!.phone
        let locationHours = "Mon-Fri: 9am-11pm ~ Sat-Sun: 10am–5pm"
        let distanceLabel = SugaredAndBronzed.locations[ID]!.distanceLabel
   
        cell.locationImage.image = SugaredAndBronzed.locations[ID]!.image ?? UIImage(named: "placeholder_location_image")
        
        cell.locationName.text = locationName
        cell.hiddenLocationID.text = "\(ID)"
        
        cell.locationDescription.text = "\(locationPhone)\n\(locationHours)\n\(locationAddress)"
        
        cell.locationDistanceView!.isHidden = true
        
        cell.locationDistanceLabel!.text = distanceLabel
        cell.locationDistanceLabelWidth!.constant = distanceLabel.count > 15 ? 110 : 100
        cell.locationDistanceView!.isHidden = distanceLabel.count == 0
        
        cell.backgroundColor = tableView.backgroundColor
        
        cell.selectionStyle = .none
        
        return cell
    }
}

//MARK: - Configuring TableView Selection
extension LocationView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 450
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SugaredAndBronzed.locationIDsByState.keys.count
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
        
        if !sortedStates.isEmpty {
            headerLabel.text = sortedStates[section]
        } else {
            let sectionIndex = SugaredAndBronzed.locationIDsByState.keys.index(SugaredAndBronzed.locationIDsByState.keys.startIndex, offsetBy: section)
            headerLabel.text = SugaredAndBronzed.locationIDsByState.keys[sectionIndex]
            
        }
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppointmentSearch.location = SugaredAndBronzed.locations[Int((tableView.cellForRow(at: indexPath) as! LocationCell).hiddenLocationID.text!)!]!
        MembershipPurchase.location = SugaredAndBronzed.locations[Int((tableView.cellForRow(at: indexPath) as! LocationCell).hiddenLocationID.text!)!]!
        self.performSegue(withIdentifier: "toServicesSegue", sender: self)
        AppointmentSearch.selectedServices = []
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// MARK: - Location View Table Cell
class LocationCell: UITableViewCell {
    
    
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var locationDescription: UILabel!
    @IBOutlet weak var bookButton: UILabel!
    @IBOutlet weak var locationView: UIView! {
        didSet {
            locationView.layer.cornerRadius = 4
            locationView.layer.masksToBounds = true
            locationView.backgroundColor = UIColor.white
        }
    }
    @IBOutlet weak var locationDistanceView: UIView? {
        didSet {
            locationDistanceView!.layer.cornerRadius = 15
            locationDistanceView!.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var locationDistanceLabel: UILabel?
    @IBOutlet weak var locationDistanceLabelWidth: NSLayoutConstraint? //usually 70, increases to 80 with larger numbers
    @IBOutlet weak var hiddenLocationID: UILabel!
    
}
