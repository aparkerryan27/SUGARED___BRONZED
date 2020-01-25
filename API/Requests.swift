//
//  Requests.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 6/28/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation

class Requests {
    
    func GET(url: String, headerType: String = "booker", completion: @escaping (_ success:Bool, _ data:Data?, _ error: String?) -> Void) {
        
        // Set up the URL request
        guard let URL = URL(string: url) else {
            completion(false, nil, "Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: URL)
        if headerType == "booker" {
            urlRequest.setValue("Bearer \(SugaredAndBronzed.accessToken)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue(SugaredAndBronzed.subscription_key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        }
        
        // make the request
        let task = URLSession(configuration: .default).dataTask(with: urlRequest) {
            (data, response, error) in
            
            
            guard let httpResponse = response as! HTTPURLResponse? else {
                completion(false, nil, "invalid response with details: \(String(describing: error?.localizedDescription))")
                return
            }
            let statusCode = httpResponse.statusCode
            
            guard error == nil && (statusCode == 200 || statusCode == 201 || statusCode == 202 || statusCode == 203 || statusCode == 204) else {
                completion(false, data, "status code: \(statusCode)")
                return
            }
            guard error == nil else {
                completion(false, nil, "\(error!)" )
                return
            }
        
            guard let responseData = data else {
                completion(false, nil, "Error: did not receive data")
                return
            }
            //send the data as the result of the function
            completion(true, responseData, nil)
        }
        task.resume()
        
    }
    
    func POST(url: String, parameters: [String: Any], headerType: String, completion: @escaping (_ success:Bool, _ data:Data?, _ error: String?) -> Void) {
        
        guard let URL = URL(string: url) else {
            completion(false, nil, "Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: URL)
        urlRequest.httpMethod = "POST"
        
        
        
        if headerType == "accessToken" { //Authorization API
            urlRequest.setValue(SugaredAndBronzed.subscription_key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let urlParams = parameters.compactMap({ (key, value) -> String in
                return "\(key)=\(value)"
            }).joined(separator: "&")
            let requestData = urlParams.data(using: String.Encoding.ascii)
            urlRequest.httpBody = requestData
            
        } else if headerType == "request" { //Customer API calls with no login required
            urlRequest.setValue(SugaredAndBronzed.subscription_key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            
            if SugaredAndBronzed.accessToken != "" {
                urlRequest.setValue("Bearer \(SugaredAndBronzed.accessToken)", forHTTPHeaderField: "Authorization")
            }
        
        } else if headerType == "customerRequest" { //Customer API calls
            urlRequest.setValue(SugaredAndBronzed.subscription_key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            
        } else if headerType == "mail" { // mailjet request
          
            let passString = "ae867245b938f9edf06f796aa11c9a76:ec5f17877787d066b91cdaaebeac186d"
            let base64EncodedCredential = Data(passString.utf8).base64EncodedString()
            urlRequest.setValue("Basic \(base64EncodedCredential)", forHTTPHeaderField: "Authorization")
    
        } else if headerType == "sugaredandbronzed" { // personal API request
        
           
        } else {
            completion(false, nil, "Error creating request")
        }
        
        if headerType != "accessToken" {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let jsonParameters = try JSONSerialization.data(withJSONObject: parameters, options: [])
                urlRequest.httpBody = jsonParameters
            } catch {
                completion(false, nil, "Error creating JSON")
                return
            }
        }
        
        let task = URLSession(configuration: .default).dataTask(with: urlRequest) {
            (data, response, error) in
            
            guard let httpResponse = response as! HTTPURLResponse? else {
                completion(false, nil, "invalid response with details: \(String(describing: error?.localizedDescription))")
                return
            }
            let statusCode = httpResponse.statusCode
         
            guard error == nil && (statusCode == 200 || statusCode == 201 || statusCode == 202) else {
                completion(false, data, "status code: \(statusCode)")
                return
            }
            guard error == nil else {
                completion(false, nil, "\(error!)" )
                return
            }
            guard let responseData = data else {
                completion(false, nil, "did not receive data")
                return
            }
            
            completion(true, responseData, "no errors!")
        }
        task.resume()
    }
    
    func PUT(url: String, parameters: [String: Any], completion: @escaping (_ success:Bool, _ data:Data?, _ error: String?) -> Void) {
        
        guard let URL = URL(string: url) else {
            completion(false, nil, "Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: URL)
        urlRequest.httpMethod = "PUT"
        
        let jsonParameters: Data
        do {
            jsonParameters = try JSONSerialization.data(withJSONObject: parameters, options: [])
            urlRequest.httpBody = jsonParameters
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(SugaredAndBronzed.subscription_key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        } catch {
            completion(false, nil, "cannot create JSON")
            return
        }
    
        let task = URLSession(configuration: .default).dataTask(with: urlRequest) {
            (data, response, error) in
            
            guard let httpResponse = response as! HTTPURLResponse? else {
                completion(false, nil, "invalid response with details: \(String(describing: error?.localizedDescription))")
                return
            }
            let statusCode = httpResponse.statusCode
            
            guard error == nil && (statusCode == 200 || statusCode == 201 || statusCode == 202) else {
                completion(false, data, "status code: \(statusCode)")
                return
            }
            guard error == nil else {
                completion(false, nil, "\(error!)" )
                return
            }
            guard let responseData = data else {
                completion(false, nil, "did not receive data")
                return
            }
            completion(true, responseData, "no errors!")
        }
        task.resume()
    }
    
}
