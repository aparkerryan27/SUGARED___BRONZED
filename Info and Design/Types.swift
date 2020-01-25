//
//  Customer.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 6/28/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import UIKit

//MARK: - Appointment
class Appointment {
    
    let id: String? //used for existing appointments, not for unknown ones
    
    let v5Time: String //format in ISO8601
    let startDateTime: Date //previously StartDateTime
    let endDateTime: Date
    let startTimeHuman: String //previously StartTime
    let endTimeHuman: String //previously EndTime
    
    let services: [Service]
    
    let locationID: Int?
    
    init(id: String? = nil, v5Time: String, startDateTime: Date, endDateTime: Date, startTimeHuman: String, endTimeHuman: String, services: [Service], locationID: Int) {
        self.id = id
        self.v5Time = v5Time
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.startTimeHuman = startTimeHuman
        self.endTimeHuman = endTimeHuman
        self.services = services
        self.locationID = locationID
    }
}


//MARK: - Service
enum ServiceType {
    case sugaring //a.k.a. simple
    case tanning
    case combo //a.k.a. sophisticated / sweet / vip
    case unknown
}

class Service {
    let type: ServiceType
    let id: String
    let name: String
    let price: Int
    let description: String // (optional)
    let duration: Int
    
    let startTime: String
    
    var membershipCorrelated: String
    
    var image: UIImage?
  
    init(type: ServiceType = .unknown, id: String, name: String = "", price: Int, description: String = "", duration: Int, startTime: String = "", membershipCorrelated: String) {
        self.name = name
        self.id = id
        self.type = type
        self.price = price
        self.description = description
        self.duration = duration
        self.startTime = startTime
        
        self.membershipCorrelated = membershipCorrelated
    }
    
    func equals(s2: Service?) -> Bool {
        guard s2 != nil else {
            return false
        }
        return self.id == s2!.id
    }
    
    func attachImage(image: UIImage) {
        self.image = image
    }
}

//MARK: - Card
class Card {
    let cardHolderName: String
    let number: String
    let expiryDate: String
    let securityCode: String
    let type: Int
    let zip: Int
    
    init(name: String, number: String, exp: String, code: String, type: Int, zip: Int) {
        self.cardHolderName = name
        self.number = number
        self.expiryDate = exp
        self.securityCode = code
        self.type = type
        self.zip = zip
    }
    
    func equals(c2: Card) -> Bool {
        return self.number.suffix(4) == c2.number.suffix(4) && self.expiryDate == c2.expiryDate
    }

}


//MARK: - Membership
enum MembershipStatus {
    case active
    case availableForPurchase
}

class Membership {
    let idWest: Int
    let idNYC: Int
    
    let priceWest: Int
    let priceNYC: Int
    
    let name: String
    let bookerName: String
    let description: String
    
    var quantity: Int
    // for CustomerMemberships: quantity of Benefit Remaining
    // for LocationMemberships: quantity of Benefits per Month
    
    let type: ServiceType
    let status: MembershipStatus
    
    let eligibleServiceNames: [String]
    
    init(idWest: Int, idNYC: Int, name: String, bookerName: String, description: String, priceWest: Int, priceNYC: Int, quantity: Int, type: ServiceType = .unknown, status: MembershipStatus = .availableForPurchase, eligibleServiceNames: [String] = []) {
        self.name = name
        self.bookerName = bookerName
        self.idWest = idWest
        self.idNYC = idNYC
        self.description = description
        self.priceWest = priceWest
        self.priceNYC = priceNYC
        self.quantity = quantity
        self.type = type
        self.status = status
        self.eligibleServiceNames = eligibleServiceNames
    }
    
    func addBenefit(){
        self.quantity += 1
    }
    
    func quantityOfBenefits() -> Int {
        switch status {
        case .availableForPurchase:
            return self.quantity
        default:
            return self.quantity - 1 //removing the fake benefit added in Customer.memberships to make it visible
        }
    }
    
    func equals(m2: Membership) -> Bool {
        return self.idNYC == m2.idNYC || self.idWest == m2.idWest
    }
    
    func print() {
        Swift.print(self.name, " IDWest: ", self.idWest, " IDNYC: ", self.idNYC, self.description )
    }
}


//MARK: - Location
class Location {
    let name: String
    let id: Int
    
    let upcharge: Bool
    
    let timeZone: String
    let state: String
    let city: String
    let street: String
    let zipCode: String
    let latitude: Double
    let longitude: Double
    
    var distance: Double = 0
    var distanceLabel = ""
    
    let email: String
    let phone: String
    
    let services: [Service]
    let servicesOrder: [Int: String] //indexPath.row: serviceID (sugaring starts at 0, tanning starts at 10)
    
    var image: UIImage? = nil
    
    init(name: String, upcharge: Bool, id: Int, timeZone: String, state: String, city: String, street: String, zipCode: String, latitude: Double, longitude: Double, email: String, phone: String, services: [Service], servicesOrder: [Int: String]) {
        self.name = name
        self.id = id
        
        self.upcharge = upcharge
        
        self.timeZone = timeZone
        self.state = state
        self.city = city
        self.street = street
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        
        self.email = email
        self.phone = phone
        
        self.services = services
        self.servicesOrder = servicesOrder
     }
    
    func attachImage(image: UIImage) {
        self.image = image
    }
    
    func print() {
        Swift.print(self.name, self.id )
    }

 }



