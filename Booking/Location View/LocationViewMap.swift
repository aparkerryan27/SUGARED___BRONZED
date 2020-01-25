//
//  LocationViewMap.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Mapbox
import MapboxDirections
import CoreLocation


//MARK: - Configuring the appearance and data of the MapView
extension LocationView: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        
        //MARK: - Add Features to the Loaded Map
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("error - error retrieving FileManager objects")
            return
        }
        
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: documentDirectoryUrl.appendingPathComponent("locations.geojson"))
                
                guard let style = mapView.style else {
                    print("style unset")
                    return
                }
                self.style = style
                
                let feature = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLShapeCollectionFeature
                
                guard style.source(withIdentifier: "store-locations") == nil else {
                    print("store-locations source already exists")
                    return
                }
                
                let source = MGLShapeSource(identifier: "store-locations", shape: feature, options: nil)
                style.addSource(source)
                
                style.setImage((self.unselectedMarker), forName: "unselected_marker")
                style.setImage((self.selectedMarker), forName: "selected_marker")
                
                self.features = feature.shapes as! [MGLPointFeature]
                
                guard style.layer(withIdentifier: "store-locations") == nil else {
                    print("store-locations layer already added")
                    //style.removeLayer(style.layer(withIdentifier:  "store-locations")!) removing and re-adding causes crash
                    return
                }
                
                let symbolLayer = MGLSymbolStyleLayer(identifier: "store-locations", source: source)
                symbolLayer.iconImageName = NSExpression(forConstantValue: "unselected_marker")
                symbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: 1)
                
                style.addLayer(symbolLayer)
                
                DispatchQueue.main.async {
                    mapView.isHidden = false
                }
                
                
            } catch {
                print("error loading in .geojson file or creating map impression from shape data: \(error)")
                self.turnOffMap(disableMap: true)
                return
            }
     
            DispatchQueue.main.async {
                if self.delayedSetupForMapConfiguration {
                    guard CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse else {
                        print("error - location updated but authorization has changed")
                        self.turnOffMap()
                        self.alert = UIAlertController(title: "", message: "to gain access to full map view features, please go to Settings > SUGARED + BRONZED > allow location access", preferredStyle: .alert)
                        self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(self.alert!, animated: true, completion: nil)
                        return
                    }
            
                    if !self.firstLocationSet {
                        self.recenterMap()
                        self.addUserLocation(to: self.style!)
                        self.firstLocationSet = true
                    }
                    
                    if !self.populatedFeaturesWithRoutes {
                        self.populateFeaturesWithRoutes()
                    }
                }
            }
        }
    }
    
    // MARK: Use a custom user location dot.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        }
        return nil
    }
    
    // MARK: Functions to lookup features in data.
    func getKeyForFeature(feature: MGLPointFeature) -> String {
        
        guard let selectFeature = feature.attribute(forKey: "phone") as? String else {
            print("error! key for feature does not exist!")
            turnOffMap(disableMap: true)
            return ""
        }
        return selectFeature
    }

    func getIndexForFeature(feature: MGLPointFeature) -> Int {
        
        guard let index = features.index(of: feature) else {
            print("error! index of feature does not exist!")
            turnOffMap(disableMap: true)
            return 0
        }
        return index
    }
    
}


//MARK: - Handling User Location
extension LocationView: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard self.style != nil else {
            //print("style is unset, delaying location setup to later")
            delayedSetupForMapConfiguration = true
            return
        }
        
        guard CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse else {
            print("error - location updated but authorization has changed")
            return
        }
        
        if !firstLocationSet {
            recenterMap()
            addUserLocation(to: self.style!)
            firstLocationSet = true
        }
        
        if !populatedFeaturesWithRoutes {
            populateFeaturesWithRoutes()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            
        default:
            print("Location Access Not Available -- Disabling Location Orientated Functions")
            turnOffMap()
        }
    }
    
    func addUserLocation(to style: MGLStyle) {
        mapView.showsUserLocation = true
        
        guard locationManager.location != nil && CLLocationCoordinate2DIsValid((locationManager.location?.coordinate)!) else {
            print("no user location found, not adding to map")
            return
        }
        
        userLocationFeature.coordinate = (locationManager.location?.coordinate)!
        userLocationSource = MGLShapeSource(identifier: "user-location", features: [userLocationFeature], options: nil)
        if let stySource = style.source(withIdentifier: "user-location") {
            style.removeSource(stySource)
        }
        style.addSource(userLocationSource!)
    }
    
    func recenterMap(){
        
        guard let longitude = locationManager.location?.coordinate.longitude, let latitude = locationManager.location?.coordinate.latitude else {
            mapView?.setCenter(unitedStatesCoordinate, zoomLevel: 8, animated: false)
            print("user location coordinates not legitamate")
            return
        }
        mapView?.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoomLevel: 8, animated: false)
        routeTypeSelectorInvisible = false
        if mapView.isHidden == false { routeTypeSelector.isHidden = false }
        
    }
}

class CustomUserLocationAnnotationView: MGLUserLocationAnnotationView { //the user location dot
    let size: CGFloat = 20
    var border: CALayer!
    var dot: CALayer!
    var color: UIColor = .blue
    
    // -MARK: Update Appearance (called many times a second, keep it lightweight)
    override func update() {
        super.update() //do i need this
        
        if frame.isNull {
            frame = CGRect(x: 0, y: 0, width: size, height: size)
            return setNeedsLayout()
        }
        
        // Check whether we have the user’s location yet.
        if CLLocationCoordinate2DIsValid(userLocation!.coordinate) {
            //MARK: - Set up Backgroup Dot
            if dot == nil {
                dot = CALayer()
                dot.bounds = CGRect(x: 0, y: 0, width: size, height: size)
                dot.cornerRadius = size / 2 //turn this layer into a circle.
                dot.backgroundColor = color.cgColor
                dot.borderWidth = 4
                dot.borderColor = UIColor.white.cgColor
                layer.addSublayer(dot)
            }
            //MARK: Set up Border and Inner Dot
            if border == nil {
                border = CALayer()
                border.bounds = bounds
                border.cornerRadius = border.bounds.width / 2
                border.backgroundColor = color.cgColor
                border.opacity = 0.0
                dot = CALayer()
                dot.bounds = CGRect(x: 0, y: 0, width: size * 4 / 5, height: size * 4 / 5)
                dot.cornerRadius = dot.bounds.width / 2 
                dot.backgroundColor = color.cgColor
                dot.opacity = 0.0
                layer.addSublayer(border)
                layer.addSublayer(dot)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
    }
    
    
 
    
    required init?(coder aDecoder: NSCoder) {
        //this is a fatalError, which crashes the app if unexpected behavior occurs
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


//MARK: - Adding methods for computations with Coordinates
extension CLLocationCoordinate2D {
    
    //this does not account for locations crossing the Prime Meridian (where values switch back to 0 and such)
    func middleLocationWith(location:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        
        let lon1 = longitude * .pi / 180
        let lon2 = location.longitude * .pi / 180
        let lat1 = latitude * .pi / 180
        let lat2 = location.latitude * .pi / 180
        let dLon = lon2 - lon1
        let x = cos(lat2) * cos(dLon)
        let y = cos(lat2) * sin(dLon)
        
        let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
        let lon3 = lon1 + atan2(y, cos(lat1) + x)
        
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / .pi, lon3 * 180 / .pi)
        return center
    }
}
