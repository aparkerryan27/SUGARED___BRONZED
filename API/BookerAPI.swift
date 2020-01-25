//
//  BookerAPI.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 6/24/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//


import Foundation
import SwiftyJSON
import Firebase

class BookerAPI {
   
    func getAccessToken(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void) { //Token - Authorization
        
        let getAccessTokenURL = "https://\(SugaredAndBronzed.baseURL)/v5/auth/connect/token"
        let getAccessTokenParameters: [String: Any] = ["grant_type":"client_credentials", "client_secret": SugaredAndBronzed.password, "client_id": SugaredAndBronzed.key, "scope": "customer"]
        Requests().POST(url: getAccessTokenURL, parameters: getAccessTokenParameters, headerType: "accessToken", completion: { (success: Bool, data: Data?, error: String?)->Void in
            guard success else {
                methodCompletion(false, "Getting Access Token error: \(error!)")
                return
            }
            
            let json = JSON(data!)
            
            guard json["error"].stringValue.isEmpty else {
                methodCompletion(false, "Booker Error! \(json["ErrorMessage"].stringValue)")
                return
            }
            SugaredAndBronzed.accessToken = json["access_token"].stringValue
            SugaredAndBronzed.expiresOn = Date().addingTimeInterval(TimeInterval(1500)).timeIntervalSince1970
            
            Analytics.logEvent("get_accessToken", parameters: [:])
            methodCompletion(true, "none")
            
        })
        
    }

    
    /**********************   *********************/
    
    
    
    func createCustomer(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){ //CreateCustomerAndUserAccount
        func createCustomer() {
            
            let newCustomerParameters: [String: Any] = ["Email": Customer.email, "Password": Customer.password, "LocationID": 18336, "FirstName": Customer.firstName, "LastName": Customer.lastName, "CellPhone": Customer.phoneNumber, "DateOfBirthOffset": Customer.dobFormatted, "access_token": SugaredAndBronzed.accessToken, "AllowReceiveEmails": true, "AllowReceiveSMS": true]
       
            //no matching customer found, create a new customer!
            let createCustomerURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/customer/account"
            
            Requests().POST(url: createCustomerURL, parameters: newCustomerParameters , headerType: "request", completion: { (success: Bool, data: Data?, error: String?)->Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
                let isSuccess = json["IsSuccess"].boolValue
                let errorMessage = json["ErrorMessage"].stringValue
                
                guard isSuccess else {
                    methodCompletion(false, errorMessage)
                    return
                }
                Customer.id = json["CustomerID"].intValue
                
                CustomerAPI().login(methodCompletion: { (success, message) in
                    guard success else {
                        methodCompletion(false, message.lowercased())
                        return
                    }
                })
                Analytics.logEvent("signup", parameters: [:])
                methodCompletion(true, errorMessage)
                UserDefaults.standard.setValue(Customer.email, forKey: "email")
            })
        }
        
        if Date().timeIntervalSince1970 > SugaredAndBronzed.expiresOn {
            getAccessToken(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                createCustomer()
            })
        } else {
           createCustomer()
        }
    }
    
    
    /**********************   *********************/
    
    
    func getLocationsAndServices(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        
        SugaredAndBronzed.locations = [:]
        SugaredAndBronzed.locationIDsByState = [:]
        
        let getLocationsAndServicesParameters: [String: Any] = ["unique_id": "10Locations!", "request_for": "locations"]
        //replace with https
        Requests().POST(url: "https://sugaredandbronzed.com/appInfo_\(SugaredAndBronzed.runType).php", parameters: getLocationsAndServicesParameters, headerType: "sugaredandbronzed", completion: { (success: Bool, data: Data?, error: String?)->Void in
            
            guard success else {
                methodCompletion(false, "Request error with details: \(error!)")
                return
            }
            
            let json = JSON(data!)
            guard json["IsSuccess"].boolValue else { //not sure if this is the nil error case
                methodCompletion(false, "Booker Error! \(json["ErrorMessage"].stringValue)")
                return
            }
            
            let locations = json["Locations"].arrayValue
           
            var geoFeatures: [[String: Any]] = []
            var geoJSONArray: [String: Any] = ["type": "FeatureCollection", "features": geoFeatures ]
            
            for location in locations {

                let ID = location["ID"].intValue
                let name = location["Name"].stringValue
                
                let upcharge = location["Upcharge"].boolValue
                
                let email = location["Email"].stringValue
                let phone: String = location["Phone"].stringValue
                
                let locationInfo = location["Location"].dictionaryValue
                
                let timeZone = locationInfo["TimeZone"]!.stringValue
                
                let zipCode =  locationInfo["ZipCode"]!.stringValue
                let state = locationInfo["State"]!.stringValue
                let city = locationInfo["City"]!.stringValue
                let street = locationInfo["Street"]!.stringValue
                let address = "\(street) \(city), \(state) \(zipCode)"

                let long = locationInfo["Longitude"]!.doubleValue
                let lat = locationInfo["Latitude"]!.doubleValue
                
                let singleFeature: [String : Any] = ["type": "Feature", "properties": ["name": name, "ID": "\(ID)", "hours": "Mon-Fri 9am-11pm ~ Sat-Sun 10am-5pm", "address": address, "phone": phone, "description": "Description..."], "geometry": ["type": "Point", "coordinates": [long, lat]]]
                geoFeatures.append(singleFeature)
                
                if SugaredAndBronzed.locationIDsByState[state] == nil {
                    SugaredAndBronzed.locationIDsByState[state] = []
                }
                SugaredAndBronzed.locationIDsByState[state]!.append(ID)
                
                
                var servicesOrder: [Int: String] = [:]
                var services: [Service] = []
                var sugaringIndex = 0
                
                for service in location["Services"].arrayValue {
                    let serviceInfo = service.dictionaryValue
                        
                    let id = serviceInfo["ID"]!.stringValue

                    var type: ServiceType = .unknown
                    switch serviceInfo["Type"]!.stringValue {
                    case "sugaring":
                        type = .sugaring
                        servicesOrder[sugaringIndex] = id
                        sugaringIndex += 1
                    case "tanning":
                        type = .tanning
                        servicesOrder[10] = id
                    default:
                        type = .unknown
                    }
                    
                    services.append(Service(type: type, id: id, name: serviceInfo["Name"]!.stringValue, price: serviceInfo["Price"]!.intValue, description: serviceInfo["Description"]!.stringValue, duration: serviceInfo["Duration"]!.intValue, membershipCorrelated: serviceInfo["CorrespondingMembershipName"]!.stringValue))
                }
                
                SugaredAndBronzed.locations[ID] = Location(name: name, upcharge: upcharge, id: ID, timeZone: timeZone, state: state, city: city, street: street, zipCode: zipCode, latitude: lat, longitude: long, email: email, phone: phone, services: services, servicesOrder: servicesOrder)
                
            }
            
            //MARK: - Convert Array into Data File
            geoJSONArray = ["type": "FeatureCollection", "features": geoFeatures]
            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileUrl = documentDirectoryUrl.appendingPathComponent("locations.geojson")
            do {
                let data = try JSONSerialization.data(withJSONObject: geoJSONArray, options: [])
                try data.write(to: fileUrl, options: [])
            } catch {
                methodCompletion(false, "geojson serialization failed with error: \(error)!")
            }
            
            Analytics.logEvent("get_locations", parameters: [:])
            methodCompletion(true, "no error!")
            
        })
    }
    
    func getLocationImages(methodCompletion: @escaping (_ success: Bool, _ error: String) -> Void) {
        
        let updateDate = UserDefaults.standard.object(forKey: "image_\(SugaredAndBronzed.locations.first!.key)_updateDate") as? Date ?? Date.init(timeIntervalSince1970: .zero)
        let isUpdateRecent = Date().timeIntervalSince(updateDate) < TimeInterval(60 * 60 * 24 * 30) //check to see if it was updated in the last month
        
        let pathBase = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        let myRequests = DispatchGroup()
        
        for location in SugaredAndBronzed.locations {
            myRequests.enter()
            
            let file = pathBase.appending("/image_\(location.key)")
            if let cachedImage = UIImage(contentsOfFile: file), isUpdateRecent {
                location.value.attachImage(image: cachedImage)
                myRequests.leave()
                
            } else {
                //change back to https
                Requests().GET(url: "https://sugaredandbronzed.com/app_location_images/\(location.key).jpg", completion: { (success, data, error) in
                    
                    guard success else {
                        methodCompletion(false, "error obtaining images from url: \(error!) on location ID: \(location.key)")
                        return
                    }
                    
                    guard let image = UIImage(data: data!) else {
                        
                        methodCompletion(false, "error creating image from data")
                        return
                    }
                
                    do {
                        try data!.write(to: URL.init(fileURLWithPath: file))
                        location.value.attachImage(image: image)
                        UserDefaults.standard.set(Date(), forKey: "image_\(location.key)_updateDate")
                        myRequests.leave()
                        
                    } catch {
                        methodCompletion(false, "error writing data: \(error))")
                    }
                    
                   
                })
            }
            
            
        }
        myRequests.notify(queue: .main) {
            methodCompletion(true, "successful!")
        }
        

    }
   

    /**********************   *********************/
    
    func getServicesImages(methodCompletion: @escaping (_ success: Bool, _ error: String) -> Void) {
        
        func imageName(for service: Service) -> String {
            return service.name.replacingOccurrences(of: " ", with: "_").lowercased()
        }
        
        
        let updateDate = UserDefaults.standard.object(forKey: "image_\(imageName(for: AppointmentSearch.location!.services.first!))_updateDate") as? Date ?? Date.init(timeIntervalSince1970: .zero)
        let isUpdateRecent = Date().timeIntervalSince(updateDate) < TimeInterval(60 * 60 * 24 * 30) //check to see if it was updated in the last month
        
        let pathBase = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        let myRequests = DispatchGroup()
        
        for service in AppointmentSearch.location!.services {
            myRequests.enter()
            
            let file = pathBase.appending("/image_\(imageName(for: service))")
            if let cachedImage = UIImage(contentsOfFile: file), isUpdateRecent {
                service.attachImage(image: cachedImage)
                myRequests.leave()
                
            } else {
                let imageURL = "https://sugaredandbronzed.com/services_images/\(imageName(for: service)).jpeg"
                //change back to https
                Requests().GET(url: imageURL, completion: { (success, data, error) in
                    
                    guard success else {
                        methodCompletion(false, "error obtaining image from url: \(imageURL) with error: \(error!)")
                        return
                    }
                    
                    guard let image = UIImage(data: data!) else {
                        
                        methodCompletion(false, "error creating image from data")
                        return
                    }
                    
                    do {
                        try data!.write(to: URL.init(fileURLWithPath: file))
                        service.attachImage(image: image)
                        UserDefaults.standard.set(Date(), forKey: "image_\(imageName(for: service))_updateDate")
                        myRequests.leave()
                        
                    } catch {
                        methodCompletion(false, "error writing data: \(error))")
                    }
                })
            }
        }
        myRequests.notify(queue: .main) {
            methodCompletion(true, "successful!")
        }
        
        
    }
    
    
    /**********************   *********************/
    
    

//MARK -- Booker Availability API Calls //
    func checkAvailableAppointments(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void) {
        
        func checkAvailableAppointments() {
            AppointmentSearch.availableAppointments.removeAll()
            
            if AppointmentSearch.selectedServices.count == 1 {
                let checkAvailableAppointmentsURL = "https://\(SugaredAndBronzed.baseURL)/v5/realtime_availability/availability/1day/?LocationId=\(AppointmentSearch.location!.id)&fromDateTime=\(AppointmentSearch.startTime)&serviceId[]=\(AppointmentSearch.selectedServices[0].id)"
                print(checkAvailableAppointmentsURL)
                Requests().GET(url: checkAvailableAppointmentsURL, completion: { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    let json = JSON(data!)
                    guard json != JSON.null else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(false, "Internet Request Failure due to unknown error")
                        return
                    }
                    
                    let appointmentObjectArray = json.arrayValue
                    guard appointmentObjectArray.count > 0 else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(true, "no appointments available on this date")
                        return
                    }
                    
                    let appointmentInfoDictionary = appointmentObjectArray[0]["serviceCategories"][0]["services"][0].dictionaryValue
                    
                    var totalDuration: Int = 0
                    var totalPrice = 0
                    for service in AppointmentSearch.selectedServices {
                        let matchingService = AppointmentSearch.location!.services.first(where: { (s) -> Bool in s.id == service.id })!
                        totalDuration += matchingService.duration
                        totalPrice += matchingService.price
                    }
                    AppointmentSearch.availableAppointmentsDuration = totalDuration
                    AppointmentSearch.availableAppointmentsPrice = totalPrice
                    
                    let appointmentTimes = appointmentInfoDictionary["availability"]!.arrayValue
                    
                    guard appointmentTimes.count > 0 else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(true, "no appointments available on this date")
                        return
                    }
                    
                    for appointmentObject in appointmentTimes {
      
                        let appointmentTime = appointmentObject["startDateTime"].stringValue //v5time
                        
                        print("appointmentTime: ", appointmentTime)
                        
                        let startDate = convertv5DateToDate(dateTimeStringLong: appointmentTime, locationID: AppointmentSearch.location!.id)
                        guard startDate != nil else {
                            methodCompletion(false, "error parsing date object from \(appointmentTime)")
                            return
                        }
                        let endDate = startDate!.addingTimeInterval(Double(AppointmentSearch.availableAppointmentsDuration) * 60.0)
                        
                        let startTime = convertDateToReadableTime(date: startDate!)
                        let endTime = convertDateToReadableTime(date: endDate)
                        
                        guard (startTime != "") && (endTime != "") else {
                            methodCompletion(false, "error parsing start date string from \(appointmentTime)")
                            return
                        }
                        
                        let services: [Service] = [Service(type: .unknown, id: AppointmentSearch.selectedServices[0].id, name: "", price: 0, description: "", duration: 0, startTime: appointmentTime, membershipCorrelated: "")]
                        AppointmentSearch.availableAppointments.append(Appointment(v5Time: appointmentTime, startDateTime: startDate!, endDateTime: endDate, startTimeHuman: startTime, endTimeHuman: endTime, services: services, locationID: AppointmentSearch.location!.id))
                        
                    }
                    Analytics.logEvent("check_available", parameters: [:])
                    methodCompletion(true, "no errors")
                    
                })
            } else {
                
                let checkAvailableAppointmentsURL = "https://\(SugaredAndBronzed.baseURL)/v5/realtime_availability/itinerary/1day"
                
                var itineraryItems: [[String: String]] = []
                for service in AppointmentSearch.selectedServices {
                    itineraryItems.append(["serviceId": service.id])
                }
                
                let checkAvailableAppointmentsParams: [String: Any] = ["locationId": AppointmentSearch.location!.id, "fromDateTime": AppointmentSearch.startTime, "access_token": SugaredAndBronzed.accessToken, "itineraries": [ [ "itineraryItems": itineraryItems  ] ] ]
           
                print(checkAvailableAppointmentsParams)
                
                Requests().POST(url: checkAvailableAppointmentsURL, parameters: checkAvailableAppointmentsParams, headerType: "request") { (success, data, error) in
                    
                    guard success else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    guard data != nil else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(false, "Internet Request Failure due to unknown error")
                        return
                    }
                    
                    let json = JSON(data!)
                    
                    let itineraries = json["itineraryList"].arrayValue
                
                    guard itineraries.count > 0 else {
                        AppointmentSearch.availableAppointments = []
                        methodCompletion(true, "no appointments available on this date")
                        return
                    }
                    
                    var totalDuration: Int = 0
                    var totalPrice = 0
                    for service in AppointmentSearch.selectedServices {
                        let matchingService = AppointmentSearch.location!.services.first(where: { (s) -> Bool in s.id == service.id })!
                        totalDuration += matchingService.duration
                        totalPrice += matchingService.price
                    }
                    AppointmentSearch.availableAppointmentsDuration = totalDuration
                    AppointmentSearch.availableAppointmentsPrice = totalPrice
                    
                    let appointments = itineraries[0]["availabilities"].arrayValue
                    
                    for appointment in appointments {
                        let appointmentTime = appointment["startDateTime"].stringValue   //v5Time
                        
                        let startDate = convertv5DateToDate(dateTimeStringLong: appointmentTime, locationID: AppointmentSearch.location!.id)
                        guard startDate != nil else {
                            methodCompletion(false, "error parsing date object from \(appointmentTime)")
                            return
                        }
                        let endDate = startDate!.addingTimeInterval(Double(AppointmentSearch.availableAppointmentsDuration) * 60.0)
                        
                        let startTime = convertDateToReadableTime(date: startDate!)
                        let endTime = convertDateToReadableTime(date: endDate)
                        
                        guard (startTime != "") && (endTime != "") else {
                            methodCompletion(false, "error parsing date from \(appointmentTime)")
                            return
                        }
                        
                        var services: [Service] = []
            
                        for appointmentInfo in appointment["availabilityItems"].arrayValue {
                            services.append(Service(type: .unknown, id: appointmentInfo["serviceId"].stringValue, name: "", price: 0, description: "", duration: 0, startTime: appointmentInfo["startDateTime"].stringValue, membershipCorrelated: ""))
                        }
                        
                        AppointmentSearch.availableAppointments.append(Appointment(v5Time: appointmentTime, startDateTime: startDate!, endDateTime: endDate, startTimeHuman: startTime, endTimeHuman: endTime, services: services, locationID: AppointmentSearch.location!.id))
                    }
                
                    Analytics.logEvent("check_available", parameters: [:])
                    methodCompletion(true, "no errors")
                }
            }

        }
        
        if Date().timeIntervalSince1970 > SugaredAndBronzed.expiresOn {
            getAccessToken(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                checkAvailableAppointments()
            })
        } else {
            checkAvailableAppointments()
        }

    }
    

    
    /**********************   *********************/
    
    
    
    func checkFirstDateAvailableForAppointment(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func checkFirstDateAvailableForAppointment(){
            
            AppointmentSearch.firstDateAvailable = nil
            
            if AppointmentSearch.selectedServices.count == 1 {
                
                let checkFirstDateAvailableForAppointmentURL = "https://\(SugaredAndBronzed.baseURL)/v5/realtime_availability/AvailableDates?locationIds=\(AppointmentSearch.location!.id)&fromDate=\(AppointmentSearch.startTime)&serviceId=\(AppointmentSearch.selectedServices[0].id)&toDate=\(AppointmentSearch.endTime)"
                
                Requests().GET(url: checkFirstDateAvailableForAppointmentURL, completion: { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        AppointmentSearch.firstDateAvailable = Date()
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    let json = JSON(data!)
                    
                    let appointmentObjectArray = json.arrayValue
                    guard appointmentObjectArray.count > 0 else {
                        AppointmentSearch.firstDateAvailable = Date()
                        methodCompletion(true, "no appointments available for a whole month!")
                        return
                    }
                    
                    let availableDates = appointmentObjectArray[0]["serviceCategories"][0]["services"][0]["availability"].arrayValue
                    
                    let dateString = availableDates[0].stringValue
                    
                    let firstDateAvailable = convertv5DateToDate(dateTimeStringLong: dateString, locationID: AppointmentSearch.location!.id)?.addingTimeInterval(60 * 60 * 12) //returns correct start of day regardless of offset, overcompensates
                    
                    guard firstDateAvailable != nil else {
                        methodCompletion(false, "error parsing date from \(dateString)")
                        return
                    }
                    AppointmentSearch.firstDateAvailable = Calendar.current.startOfDay(for: firstDateAvailable!)
                    
                    Analytics.logEvent("check_first_date_available", parameters: [:])
                    methodCompletion(true, "successful!")
                })
                
            } else {
                
                let checkFirstDateAvailableForAppointmentURL = "https://\(SugaredAndBronzed.baseURL)/v5/realtime_availability/ItineraryDates"
                
                var itineraryItems: [[String: String]] = []
                for service in AppointmentSearch.selectedServices {
                    itineraryItems.append(["serviceId": service.id])
                }
                
                let checkFirstDateAvailableForAppointmentParams: [String: Any] = ["locationId": AppointmentSearch.location!.id, "fromDateTime": AppointmentSearch.startTime, "toDateTime": AppointmentSearch.endTime, "itineraries": [ [ "itineraryItems": itineraryItems  ] ] ]
                
                Requests().POST(url: checkFirstDateAvailableForAppointmentURL, parameters: checkFirstDateAvailableForAppointmentParams, headerType: "request", completion:  { (success, data, error) in
               
                    guard success else {
                        AppointmentSearch.firstDateAvailable = Date()
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    let json = JSON(data!)
                    
                    let dates = json["availability"].arrayValue
                    guard dates.count > 0 else {
                        AppointmentSearch.firstDateAvailable = Date()
                        methodCompletion(true, "no appointments available for a whole month!")
                        return
                    }
                    
                    let dateString = dates[0].stringValue
                    
                    let firstDateAvailable = convertv5DateToDate(dateTimeStringLong: dateString, locationID: AppointmentSearch.location!.id)?.addingTimeInterval(60 * 60 * 12) //returns correct start of day regardless of offset, overcompensates
                    
                    guard firstDateAvailable != nil else {
                        methodCompletion(false, "error parsing date from \(dateString)")
                        return
                    }
                    AppointmentSearch.firstDateAvailable = Calendar.current.startOfDay(for: firstDateAvailable!)
                    
                    Analytics.logEvent("check_first_date_available", parameters: [:])
                    methodCompletion(true, "successful!")
            
                })
            }

        }
        
        if Date().timeIntervalSince1970 > SugaredAndBronzed.expiresOn {
            getAccessToken(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                checkFirstDateAvailableForAppointment()
            })
        } else {
            checkFirstDateAvailableForAppointment()
        }
    }
    
    
    
    /***************************************************************/
    
    
    
    //MARK: - Find Memberships
    func findMemberships(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func findMemberships(){
            SugaredAndBronzed.memberships = []
            //change back to https
            let findMembershipsURL = "https://sugaredandbronzed.com/appInfo_\(SugaredAndBronzed.runType).php"
            let findMembershipsParams: [String: Any] = ["unique_id": "10Locations!", "request_for": "memberships"]
            
            Requests().POST(url: findMembershipsURL, parameters: findMembershipsParams, headerType: "request", completion: { (success: Bool, data: Data?, error: String?) -> Void in
                
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
         
                guard json["IsSuccess"].boolValue else {
                    methodCompletion(false, "Booker Request Failure: \(json["ErrorMessage"].stringValue)")
                    return
                }
                
                for membershipData in json["Memberships"].arrayValue {
                    let membershipInfo = membershipData.dictionaryValue
      
                    let idWest = membershipInfo["IDWest"]!.intValue
                    let idNYC = membershipInfo["IDNYC"]!.intValue
                    
                    let priceWest = membershipInfo["PriceWest"]!.intValue
                    let priceNYC = membershipInfo["PriceNYC"]!.intValue
                    let name = membershipInfo["Name"]!.stringValue
                    let bookerName = membershipInfo["BookerName"]!.stringValue
                    let description = membershipInfo["Description"]!.stringValue
                    
                    let benefitsQuantity = membershipInfo["BenefitQuantity"]!.intValue
                    let eligibleServiceNames = membershipInfo["ServicesEligible"]!.arrayValue.map { $0.stringValue }
                    var serviceType: ServiceType
                    switch membershipInfo["Type"]!.stringValue {
                    case "sugaring":
                        serviceType = .sugaring
                    case "tanning":
                        serviceType = .tanning
                    default:
                        serviceType = .combo
                    }
                    
                    SugaredAndBronzed.memberships.append(Membership(idWest: idWest, idNYC: idNYC, name: name, bookerName: bookerName, description: description, priceWest: priceWest, priceNYC: priceNYC, quantity: benefitsQuantity, type: serviceType, eligibleServiceNames: eligibleServiceNames))
                }

                methodCompletion(true, "successful!")
            })
        }
        
        if Date().timeIntervalSince1970 > SugaredAndBronzed.expiresOn {
            getAccessToken(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                findMemberships()
            })
        } else {
            findMemberships()
        }
        
    }
}





func convertv5DateToDate(dateTimeStringLong: String, locationID: Int) -> Date? {
    
    let dateTimeStringEnd = dateTimeStringLong.index(dateTimeStringLong.endIndex, offsetBy: -6)
    //let timeZoneString = String(dateTimeStringLong[dateTimeStringEnd..<dateTimeStringLong.endIndex])
    // the -0x:00 attached to end of ISO8601 that indicates local timezone
    
    let dateTimeString = String(dateTimeStringLong[dateTimeStringLong.startIndex..<dateTimeStringEnd]) //the rest of the timeStamp
       
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let dateTime = dateFormatter.date(from: dateTimeString)
    guard dateTime != nil else {
        print("error parsing date object from \(dateTimeString)")
        return nil
        
    }
    
    return dateTime
}

func convertDateToReadableTime(date: Date) -> String {
    dateFormatter.dateFormat = "h:mm a"
    let formattedTimeString = dateFormatter.string(from: date).lowercased()
    return formattedTimeString
}
