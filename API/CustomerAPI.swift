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

let dateFormatter = DateFormatter()

class CustomerAPI {
    
    func login(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void) { //login
    
        func login() {
            Customer.cards = []
            let loginURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/customer/login"
            let loginParameters: [String: Any] = [
                "Email": Customer.email,
                "Password": Customer.password,
                "client_id": SugaredAndBronzed.key,
                "client_secret": SugaredAndBronzed.password,
                "LocationID": 18336
            ]
            
            Requests().POST(url: loginURL, parameters: loginParameters, headerType: "request", completion: { (success: Bool, data: Data?, error: String?)->Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
                
                let errorType = json["error_description"].stringValue
                let errorMessage = json["error"].stringValue
                
                guard errorMessage == "" else {
                    methodCompletion(false, "login request failed with error [\(errorType): \(errorMessage)]")
                    return
                }
                
                Customer.accessToken = json["access_token"].stringValue
                //"expires_in" : "5400"
                Customer.expiresOn = Date().addingTimeInterval(TimeInterval(1500)).timeIntervalSince1970
                
                Customer.id = json["Customer"]["CustomerID"].intValue
                Customer.firstName = json["Customer"]["Customer"]["FirstName"].stringValue
                Customer.lastName = json["Customer"]["Customer"]["LastName"].stringValue
                Customer.dobFormatted = json["Customer"]["Customer"]["DateOfBirthOffset"].stringValue
                
                if Customer.dobFormatted == ""  { //no customer date of birth
                    Customer.age = 18
                    Customer.dob = ""
                } else {
                    
                    dateFormatter.timeZone =  TimeZone(abbreviation: "UTC")
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxxxx"
                    let birthdate = dateFormatter.date(from: Customer.dobFormatted)
                    guard birthdate != nil else { //error parsing birthdate object
                        Customer.age = 18
                        Customer.dob = ""
                        return
                    }
                    
                    dateFormatter.dateFormat = "MM/dd/yyyy"
                    Customer.dob = dateFormatter.string(from: birthdate!)
                    
                    let now = Date()
                    let calendar = Calendar.current
                    
                    let ageComponents = calendar.dateComponents([.year], from: birthdate!, to: now)
                    let age: Int = ageComponents.year!
                    
                    Customer.age = age
                }
                
                Customer.email = json["Customer"]["Customer"]["Email"].stringValue
                Customer.phoneNumber = Int(json["Customer"]["Customer"]["CellPhone"].string ?? json["Customer"]["Customer"]["HomePhone"].string ?? json["Customer"]["Customer"]["WorkPhone"].string ?? "0")!
                
                //LocationID not possible to obtain from customer login
                
                Customer.allowRecieveSMS = json["Customer"]["Customer"]["AllowReceiveSMS"].boolValue
                Customer.allowRecieveEmails = json["Customer"]["Customer"]["AllowReceiveEmails"].boolValue
                Customer.AllowReceivePromotionalEmails = json["Customer"]["Customer"]["AllowReceivePromotionalEmails"].boolValue
                
                let cards = json["Customer"]["Customer"]["CustomerCreditCards"].arrayValue
                for card in cards {
                    
                    let cardInfo = card.dictionaryValue
                    let name = cardInfo["CreditCard"]!["NameOnCard"].stringValue
                    let exp = cardInfo["CreditCard"]!["ExpirationDateOffset"].stringValue //v5 Date
                    let number = cardInfo["CreditCard"]!["Number"].stringValue //obfuscated
                    let code = cardInfo["CreditCard"]!["SecurityCode"].stringValue //usually null
                    let type = cardInfo["CreditCard"]!["Type"]["ID"].intValue
                    let zip = cardInfo["CreditCard"]!["Address"]["Zip"].intValue
                    
                    Customer.cards.append(Card(name: name, number: number, exp: exp, code: code, type: type, zip: zip))
                }
                
                
                Analytics.setUserProperty("\(Customer.firstName) \(Customer.lastName)", forName: "name")
                Analytics.setUserID("\(Customer.id)")
                
                Analytics.logEvent("login", parameters: [:])
                
                methodCompletion(true, errorMessage)
                
            })
        }
        
        if Date().timeIntervalSince1970 > SugaredAndBronzed.expiresOn {
            BookerAPI().getAccessToken { (success, error) in
                guard success else {
                    methodCompletion(false, "error getting refreshed access token")
                    return
                }
                login()
            }
        } else {
            login()
        }
    }
    
    
     /**********************   *********************/
    
    
    func logout(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void) {
        func logout() {
            let logoutURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/logout?access_token=\(Customer.accessToken)"
            let logoutParameters: [String: Any] = ["access_token": Customer.accessToken]
            Requests().POST(url: logoutURL, parameters: logoutParameters, headerType: "request", completion: { (success: Bool, data: Data?, error: String?)->Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
                
                let errorMessage = json["ErrorMessage"].stringValue
                
                guard errorMessage == "" else {
                    methodCompletion(false, errorMessage)
                    return
                }
                
                Analytics.logEvent("logout", parameters: [:])
                methodCompletion(true, "")
            })
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            Analytics.logEvent("logout", parameters: [:])
            methodCompletion(true, "")
        } else {
            logout()
        }
    }
    
    
    /**********************   *********************/
    
    

    func createAppointment(methodCompletion: @escaping (_ success: Bool, _ error: String) -> Void){ //CreateAppointment
        
        func createAppointment() {
    
            let appointmentSelected = AppointmentSearch.appointmentSelected!
            var treatmentTimeSlots: [[String: Any]] = []
            for service in appointmentSelected.services {
                treatmentTimeSlots.append(["StartDateTimeOffset": service.startTime, "TreatmentID": service.id])
            }
            
            let createAppointmentURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/appointment/create"
            let createAppointmentParameters: [String: Any] = ["access_token": Customer.accessToken, "LocationID": AppointmentSearch.location!.id, "Customer": ["ID": Customer.id], "ItineraryTimeSlotList": [["StartDateTimeOffSet": appointmentSelected.v5Time, "TreatmentTimeSlots": treatmentTimeSlots ]]]
            
            Requests().POST(url: createAppointmentURL, parameters: createAppointmentParameters, headerType: "customerRequest", completion: { (success: Bool, data: Data?, error: String?) -> Void in
                
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
                
                guard json["IsSuccess"].boolValue else {
                    methodCompletion(false, json["ErrorMessage"].stringValue)
                    return
                }
                
                AppointmentSearch.appointmentCreatedID = json["Appointment"]["ID"].stringValue
                
                Analytics.logEvent("book_appointment", parameters: [ "appointment_id" : AppointmentSearch.appointmentCreatedID as NSObject, "price": AppointmentSearch.availableAppointmentsPrice ]) //Logs a Custom Booking Event in Crashlytics Answers

                methodCompletion(true, "nil")
                
            })
            
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                createAppointment()
            })
        } else {
            createAppointment()
        }
    }
    
    
     /**********************   *********************/
    
    
    func viewAppointments(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func viewAppointments() {
            Customer.activeAppointments = []
            let viewAppointmentsURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/appointments"
            let currentTime = Int(Date().timeIntervalSince1970 * 1000)
            var counter = 0
            
            //Checks for "Booked" Appointments
            if SugaredAndBronzed.locations.count == 0 {
                methodCompletion(false, "locations not yet loaded")
            }
            
            func viewAppointments(withStatusID: Int, requestsLogger: DispatchGroup, locationID: Int) {
                
                let viewAppointmentsParameters: [String: Any] = ["access_token": Customer.accessToken, "SortBy": [["SortBy": "StartDateTime", "SortDirection": 0]], "FromStartDate":"/Date(\(currentTime))/", "UsePaging": false, "CustomerID": Customer.id, "LocationID": locationID , "AppointmentStatusID": withStatusID,  "OnlyClassAppointments": false, "ShowAppointmentIconFlags": true, "ExcludeEnrollmentAppointments": false, "IncludeAppointmentsForDependents": false, "IncludeFieldValuesInResults": true]
                
                requestsLogger.enter()
                
                Requests().POST(url: viewAppointmentsURL, parameters: viewAppointmentsParameters, headerType: "request", completion:  { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        if error!.contains("status code: 500") {
                            print("was it my fault?:", viewAppointmentsParameters)
                        }
                        Customer.activeAppointments = []
                        return
                    }
                    
                    let json = JSON(data!)
                    guard json["IsSuccess"].boolValue else {
                        methodCompletion(false, json["ErrorMessage"].stringValue)
                        return
                    }
                    
                    guard json["TotalResultsCount"].intValue > 0 else {
                        requestsLogger.leave()
                        return
                    }
                    
                    for appointment in json["Results"].arrayValue {
                        
                        let appointmentID = appointment["ID"].stringValue
                        
                        let locationID = appointment["LocationID"].intValue
                        let location = SugaredAndBronzed.locations[locationID]
                        guard location != nil else {
                            print("error retrieving valid location")
                            return
                        }
                        
                        let startDateTime = appointment["StartDateTimeOffset"].stringValue
                        
                        let startDate = convertv5DateToDate(dateTimeStringLong: startDateTime, locationID: locationID)
                        let endDate = convertv5DateToDate(dateTimeStringLong: appointment["EndDateTimeOffset"].stringValue, locationID: locationID)
                        guard startDate != nil && endDate != nil else {
                            methodCompletion(false, "failure to properly convert date")
                            return
                        }
                        
                        let startTime = convertDateToReadableTime(date: startDate!)
                        let endTime = convertDateToReadableTime(date: endDate!)
         
                        var services: [Service] = []
                        for appointmentTreatment in appointment["AppointmentTreatments"].arrayValue {
                    
                            let treatmentID = appointmentTreatment["Treatment"]["ID"].stringValue
                            
                            //TODO: - Change this mapping to services.bookerName == treatmentType
                            if let matchingService = location!.services.first(where: { (service) -> Bool in service.id == treatmentID }) {
                                services.append(matchingService)
                            } else {
                                print("error - failed to match service to existing")
                                services.append(Service( id: treatmentID, name: appointmentTreatment["Treatment"]["Name"].stringValue, price: 0, description: "", duration: 0, membershipCorrelated: ""))
                            }
                            
                        }
                        
                        Customer.activeAppointments.append(Appointment(id: appointmentID, v5Time: startDateTime, startDateTime: startDate!, endDateTime: endDate!, startTimeHuman: startTime, endTimeHuman: endTime, services: services, locationID: locationID))
                    
                    }
                    requestsLogger.leave()
                })
            }
            
            
            let myRequests = DispatchGroup()
            
            for location in SugaredAndBronzed.locations {
            
                viewAppointments(withStatusID: 2, requestsLogger: myRequests, locationID: location.key) //checks for booked appointments
                viewAppointments(withStatusID: 3, requestsLogger: myRequests, locationID: location.key) //checks for confirmed appointments
                
            }
            
            myRequests.notify(queue: .main) {
                Analytics.logEvent("view_appointments", parameters: [:])
                methodCompletion(true, "successful!")
            }
        }
        
        
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                viewAppointments()
            })
        } else {
            viewAppointments()
        }
    }
    
    
     /**********************   *********************/
    
    

    func viewPastAppointments(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func viewPastAppointments() {
            Customer.pastAppointments = []
            let viewPastAppointmentsURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/appointments"
      
            let myRequests = DispatchGroup()
        
            for location in SugaredAndBronzed.locations {
                myRequests.enter()
                
                let viewPastAppointmentsParameters: [String: Any] = [
                    "access_token": SugaredAndBronzed.accessToken,
                    "SortBy": [[
                        "SortBy": "StartDateTime",
                        "SortDirection": 0
                        ]],
                    "UsePaging": false,
                    "CustomerID": Customer.id,
                    "LocationID": location.key,
                    "AppointmentStatusID": 5,
                    "OnlyClassAppointments": false,
                    "ShowAppointmentIconFlags": true,
                    "ExcludeEnrollmentAppointments": false,
                    "IncludeAppointmentsForDependents": false,
                    "IncludeFieldValuesInResults": true,
                    "OnlyActiveAppointments": false
                ]
                
                Requests().POST(url: viewPastAppointmentsURL, parameters: viewPastAppointmentsParameters, headerType: "request", completion:  { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        Customer.pastAppointments = []
                        return
                    }
                    
                    let json = JSON(data!)

                    guard json["IsSuccess"].boolValue else {
                        methodCompletion(false, json["ErrorMessage"].stringValue)
                        return
                    }
                    
                    guard json["TotalResultsCount"].intValue > 0 else {
                        myRequests.leave()
                        return
                    }
                    
                    for appointment in json["Results"].arrayValue {
                        
                        let id = appointment["ID"].stringValue
                        
                        let locationID = appointment["LocationID"].intValue
                        let startDateTime = appointment["StartDateTimeOffset"].stringValue
                        let startDate = convertv5DateToDate(dateTimeStringLong: startDateTime, locationID: locationID)
                        guard startDate != nil else {
                            methodCompletion(false, "failure to properly convert date")
                            return
                        }
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        let startDateHuman = dateFormatter.string(from: startDate!)

                        var services: [Service] = []
                        for appointmentTreatment in appointment["AppointmentTreatments"].arrayValue {
                            
                            let treatmentID = appointmentTreatment["Treatment"]["ID"].stringValue
                            let price = Int(appointmentTreatment["Treatment"]["Price"]["Amount"].stringValue)!
                    
                            let treatmentName = appointmentTreatment["Treatment"]["Name"].stringValue.lowercased()
                            var name = ""
                            if treatmentName.contains("sugaring") && treatmentName.contains("upgrade") {
                                name = "service upgrade"
                                
                            } else if treatmentName.contains("sugaring") && treatmentName.contains("trainee") {
                                name = "trainee sugaring"
                                
                            } else if treatmentName.contains("tan") && treatmentName.contains("trainee") {
                                name = "trainee service"
                                
                            } else if treatmentName.contains("sprinkle") {
                                name = "sprinkle"
                                
                            } else if treatmentName.contains("teaspoon") {
                                name = "teaspoon"
                                
                            } else if treatmentName.contains("tablespoon") {
                                name = "tablespoon"
                                
                            } else if treatmentName.contains("spoonful") {
                                name = "spoonful"

                            } else if treatmentName.contains("ladle") {
                                name = "ladle"

                            } else if treatmentName.contains("brazilian") {
                                name =  "brazilian sugaring"
                 
                            } else if treatmentName.contains("bikini") {
                                name = "bikini sugaring"

                            } else if treatmentName.contains("tan") {
                                name = "custom airbrush tan"

                            } else if treatmentName.contains("sugaring") {
                                name = "sugaring service"
                                
                            } else {
                                name = "product"
                            }
                            
                            services.append(Service(id: treatmentID, name: name, price: price, duration: 0, membershipCorrelated: ""))
                        }
                    
                        Customer.pastAppointments.append(Appointment(id: id, v5Time: startDateTime, startDateTime: startDate!, endDateTime: Date(), startTimeHuman: startDateHuman, endTimeHuman: "", services: services, locationID: locationID))
                    }
                    
                    myRequests.leave()
                })
                
            }
            
            myRequests.notify(queue: .main) {
                Analytics.logEvent("view_past_appointments", parameters: [:])
                methodCompletion(true, "successful!")
            }
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                viewPastAppointments()
            })
        } else {
            viewPastAppointments()
        }
    }
    
    
     /**********************   *********************/
    
    
    
    func cancelAppointment(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func cancelAppointments() {
            
            let cancelAppointmentURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/appointment/cancel"
            
            guard Customer.appointmentToCancelID != nil else {
                methodCompletion(false, "invalid Customer.appointmentToCancelID")
                return
            }
            
            let appointmentToCancelID = Customer.appointmentToCancelID
            
            //apointmentToCancel has no member "ID" //
            
            let cancelAppointmentParameters: [String: Any] = ["access_token": Customer.accessToken, "ID": appointmentToCancelID!, "RequireCancellationReason": false]

            
            Requests().PUT(url: cancelAppointmentURL, parameters: cancelAppointmentParameters, completion: { (success: Bool, data: Data?, error: String?) -> Void in
                
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    Customer.activeAppointments = []
                    return
                }
                
                let json = JSON(data!)
                
                guard json["IsSuccess"].boolValue else {
                    methodCompletion(false, json["ErrorMessage"].stringValue)
                    return
                }
                Customer.appointmentToCancelID = nil
                Analytics.logEvent("cancel_appointment", parameters: [:])
                methodCompletion(true, "you  don't stink!")
            })
        }
    
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                cancelAppointments()
            })
        } else {
            cancelAppointments()
        }
    }

    
     /**********************   *********************/
    
    
    
    
    //Updating Customer Information
    
    func updateInfo(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){ //UpdateCustomer
        
        //is the locationID gonna mess up the client location??
        
        func updateInfo(){
        
            let updateCustomerURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/customer/\(Customer.id)"
            let updateCustomerParameters: [String: Any] = ["Email": Customer.email, "LocationID": 18336, "FirstName": Customer.firstName, "LastName": Customer.lastName, "CellPhone": Customer.phoneNumber, "access_token": Customer.accessToken, "DateOfBirthOffset": Customer.dobFormatted, "AllowReceiveSMS": Customer.allowRecieveSMS, "AllowReceiveEmail": Customer.allowRecieveEmails]
            
            Requests().PUT(url: updateCustomerURL, parameters: updateCustomerParameters, completion: { (success: Bool, data: Data?, error: String?)->Void in
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
                
                //log customer back in to update information on screen
                self.login(methodCompletion: { (success, error) in
                    guard success else {
                        methodCompletion(false, "logging back in failure: \(error)")
                        return
                    }
                
                    methodCompletion(true, "successful!")
                })
                
               
            })
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                updateInfo()
            })
        } else {
            updateInfo()
        }
        
    }

    

     /**********************   *********************/
    

//MARK - Membership Calls
    
    func updatePaymentForMembership(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){ //UpdateCustomerMembershipCreditCardOnFile
        
        func updateCustomerPayment(){
            
            let updateCustomerURL = "https://\(SugaredAndBronzed.baseURL)/v5/"
            let updateCustomerParams: [String: Any] = [:]
            
            Requests().POST(url: updateCustomerURL, parameters: updateCustomerParams, headerType: "customerRequest", completion: { (success: Bool, data: Data?, error: String?) -> Void in
                
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
                //print(json)
                
                //TODO: - Fill out this return breakdown
                
                methodCompletion(true, "successful!")
            })
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                updateCustomerPayment()
            })
        } else {
            updateCustomerPayment()
        }
        
    }

    
     /**********************   *********************/
    
    
    func findMemberships(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void) { //findCustomerMemberships
        
        func findMemberships(){
                Customer.memberships = []
                let findMembershipsURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/customer/memberships"
                let findMembershipsParams: [String: Any] = ["access_token" : Customer.accessToken, "LocationID": 18336, "CustomerID": Customer.id]
                Requests().POST(url: findMembershipsURL, parameters: findMembershipsParams, headerType: "customerRequest", completion: { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    let json = JSON(data!)
   
                    guard json["IsSuccess"].boolValue else {
                        methodCompletion(false, "Booker Request Failure: \(json["ErrorMessage"].stringValue)")
                        return
                    }
                    
                    let results = json["Results"].arrayValue
                    for result in results {
                        let membershipInfo = result.dictionaryValue
                        
                        let membershipBookerName = membershipInfo["LevelName"]!.stringValue
            
                        guard let membership = SugaredAndBronzed.memberships.first(where: { (membership) -> Bool in
                            membershipBookerName.contains(membership.bookerName)
                            
                        }) else {
                            methodCompletion(false, "error matching up customer membership to existing one, not valid. Name = \(membershipBookerName)")
                            return
                        }
                        
                        if let existingMembership = Customer.memberships.first(where: { (m) -> Bool in m.equals(m2: membership) }) {
                            
                            existingMembership.addBenefit() //if the membership is already known, just add this additional benefit to the quantity
                            
                        } else { //otherwise, add detail and append a newfound membership
                            
                            Customer.memberships.append(Membership(idWest:  membership.idWest, idNYC: membership.idNYC, name: membership.name, bookerName: membership.bookerName, description: membership.description, priceWest:  membership.priceWest, priceNYC: membership.priceNYC, quantity: 1, status: .active, eligibleServiceNames: membership.eligibleServiceNames))
                        }
                        
                    }
                     methodCompletion(true, "successful!")
                    
                })
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
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
    
    
    
    /**********************   *********************/
    
    
 
    func purchaseMembership(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){  //PurchaseMembership
        
        func purchaseMembership(){
            
            let myRequests = DispatchGroup()
            
            for membership in MembershipPurchase.membershipsSelected {
                myRequests.enter()
                
                var price = membership.priceWest               
                var id = membership.idWest
                if MembershipPurchase.location!.upcharge {
                    id = membership.idNYC
                    price = membership.priceNYC
                }
                
                var purchaseParams: [String: Any]
                if MembershipPurchase.cardSelected!.securityCode != "" {
                     purchaseParams = [
                        "access_token": Customer.accessToken,
                        "LocationID": MembershipPurchase.location!.id,
                        "MembershipProgramID": id,
                        "CustomerID" : Customer.id,
                        "CustomerFirstName": Customer.firstName,
                        "CustomerLastName": Customer.lastName,
                        "CustomerPhone": Customer.phoneNumber,
                        "CustomerEmail": Customer.email,
                        "PaymentItem": [
                            "Amount": [
                                "Amount": price, "CurrencyCode": "USD"
                            ],
                            "CreditCard": [
                                "BillingZip": MembershipPurchase.cardSelected!.zip,
                                "ExpirationDateOffset": MembershipPurchase.cardSelected!.expiryDate,
                                "NameOnCard": MembershipPurchase.cardSelected!.cardHolderName,
                                "Number": MembershipPurchase.cardSelected!.number,
                                "SecurityCode": MembershipPurchase.cardSelected!.securityCode,
                                "Type": ["ID": MembershipPurchase.cardSelected!.type]
                            ],
                            "Method": ["ID": 1] //credit card purchase
                        ]
                    ]
                } else {
                    purchaseParams = [
                        "access_token": Customer.accessToken,
                        "LocationID": MembershipPurchase.location!.id,
                        "MembershipProgramID": id,
                        "CustomerID" : Customer.id,
                        "CustomerFirstName": Customer.firstName,
                        "CustomerLastName": Customer.lastName,
                        "CustomerPhone": Customer.phoneNumber,
                        "CustomerEmail": Customer.email,
                        "PaymentItem": [
                            "Amount": [
                                "Amount": price, "CurrencyCode": "USD"
                            ],
                            "CreditCard": [ //accepting obfuscated credit card numbers for payment
                                "ExpirationDateOffset": MembershipPurchase.cardSelected!.expiryDate,
                                "NameOnCard": MembershipPurchase.cardSelected!.cardHolderName,
                                "Number": MembershipPurchase.cardSelected!.number,
                                "Type": ["ID": MembershipPurchase.cardSelected!.type]
                            ],
                            "Method": ["ID": 1] //credit card purchase
                        ]
                    ]
                }
                
                print("params!: ", purchaseParams)
                Requests().POST(url: "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/membership/purchase", parameters: purchaseParams, headerType: "customerRequest", completion: { (success: Bool, data: Data?, error: String?) -> Void in
                    
                    guard success else {
                        methodCompletion(false, "Internet Request Failure: \(error!)")
                        return
                    }
                    
                    let json = JSON(data!)
                    print(json)
                    guard json["IsSuccess"].boolValue else {
                        methodCompletion(false, json["ErrorMessage"].stringValue)
                        return
                    }
                    
                   myRequests.leave()
                })
            }
            
            myRequests.notify(queue: .main) {
                Analytics.logEvent("purchased_membership", parameters: [:])
                methodCompletion(true, "successful!")
            }
        }
           
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            login(methodCompletion: { (success, error) -> Void in
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error)")
                    return
                }
                purchaseMembership()
            })
        } else {
            purchaseMembership()
        }
        
    }
    
    
    
    func getOrder(methodCompletion: @escaping (_ success: Bool, _ error: String)-> Void){
        
        func getOrder() {
            let getOrderURL = "https://\(SugaredAndBronzed.baseURL)/v4.1/customer/order/\(Customer.orderID!)"
            let getOrderParameters: [String: Any] = ["access_token": Customer.accessToken]
            Requests().POST(url: getOrderURL, parameters: getOrderParameters, headerType: "request", completion: { (success: Bool, data: Data?, error: String?)->Void in
                
                guard success else {
                    methodCompletion(false, "Internet Request Failure: \(error!)")
                    return
                }
                
                let json = JSON(data!)
            
                guard json["ErrorMessage"].stringValue == "" else {
                    methodCompletion(false, json["ErrorMessage"].stringValue)
                    return
                }
                
                let order = json["Order"].dictionaryValue

                Customer.locationID = order["LocationID"]?.intValue
                guard Customer.locationID != nil else {
                    methodCompletion(false, "order request failed with JSON formatting issues")
                    return
                }
                
                let items = order["Items"]?.arrayValue
                guard items != nil, items!.count > 0 else {
                    methodCompletion(false, "order request failed with JSON formatting issues")
                    return
                }
                guard let item = items![0].dictionary else {
                    methodCompletion(false, "order request failed with JSON formatting issues")
                    return
                }
                
                Customer.employeeID = item["EmployeeID"]?.intValue
                Customer.employeeName = item["EmployeeName"]?.stringValue ?? ""
                guard Customer.employeeID != nil && Customer.employeeName != "" else {
                    methodCompletion(false, "order request failed with JSON formatting issues")
                    return
                }
            
                Analytics.logEvent("getOrderForReview", parameters: [:])
                methodCompletion(true, "")
            })
        }
        
        if Date().timeIntervalSince1970 > Customer.expiresOn {
            methodCompletion(true, "")
        } else {
            getOrder()
        }
    }
    

}
