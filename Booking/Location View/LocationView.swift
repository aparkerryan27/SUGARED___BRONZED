//
//  LocationViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Mapbox
import MapboxDirections
import MapKit
import CoreLocation
import NVActivityIndicatorView
import Firebase

class LocationView: UIViewController {
    
    var activityIndicator: NVActivityIndicatorView! {
        didSet {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        }
    }
    var activityIndicatorContainerView: UIView! {
        didSet {
            activityIndicatorContainerView.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            activityIndicatorContainerView.layer.cornerRadius = 4
            activityIndicatorContainerView.layer.masksToBounds = true
            activityIndicatorContainerView.isHidden = false
        }
    }
    
    var switchMapOrListButton: UIButton? {
        didSet {
            switchMapOrListButton!.setTitleColor(UIColor.white, for: .normal)
            switchMapOrListButton!.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: 17)
            switchMapOrListButton!.tintColor = UIColor.white
            if locationTableView.isHidden {
                switchMapOrListButton!.setTitle("   LIST  ", for: .normal)
                switchMapOrListButton!.setImage(UIImage(named: "list_icon_white"), for: .normal)
                switchMapOrListButton!.setImage(UIImage(named: "list_icon_white"), for: .highlighted)
            } else {
                switchMapOrListButton!.setTitle("  MAP ", for: .normal)
                switchMapOrListButton!.setImage(UIImage(named: "map_icon_white"), for: .normal)
                switchMapOrListButton!.setImage(UIImage(named: "map_icon_white"), for: .highlighted)
            }
            switchMapOrListButton!.addTarget(self, action: #selector(LocationView.switchMapOrList), for: UIControl.Event.touchUpInside)
        }
    }
    var switchToView = "map"
    
    var routeTypeSelectorInvisible = true
    
    let locationManager = CLLocationManager()
    var alert: UIAlertController?
    var latitude: Double?
    var longitude: Double?
    
    var turnOffTimer: Timer?
    
    //MARK: - Customize these variables to style your map:
    //Marker and Map Styles
    let unselectedMarker = UIImage(named: "blue_unselected_house")!
    let selectedMarker = UIImage(named: "blue_selected_house")!
    let styleURL = MGLStyle.streetsStyleURL
    var style: MGLStyle?
    
    var itemView : LocationItemView! // Keeps track of the current LocationItemView.
    var mapView: MGLMapView! {
        didSet {
            mapView.isHidden = false
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.userTrackingMode = .follow
            mapView.allowsRotating = false
            mapView.isRotateEnabled = false
            mapView.showsUserLocation = false
        }
    }
    var fadeView: UIView! {
        didSet {
            let fade = CAGradientLayer()
            fade.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor]
            fade.locations = [0.0, 1.0]
            fade.frame = CGRect(x: 0.0, y: 0, width: fadeView.frame.width, height: fadeView.frame.height)
            fadeView.layer.insertSublayer(fade, at: 0)
            fadeView.isUserInteractionEnabled = false
            fadeView.backgroundColor = .clear
        }
    }
    
    let userLocationFeature = MGLPointFeature()
    var userLocationSource : MGLShapeSource?
    let unitedStatesCoordinate = CLLocationCoordinate2D(latitude: 37.090240, longitude: -95.712891)
    
    var numberOfLocationsLeftToCalculate = 0
    
    // Properties for the callout.
    var pageViewController : UIPageViewController! {
        didSet {
            pageViewController.view.backgroundColor = .clear
            pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pageViewController.view.translatesAutoresizingMaskIntoConstraints = true
            pageViewController.view.isHidden = true
            pageViewController.isDoubleSided = false
        }
    }
    
    var features : [MGLPointFeature] = []
    var locationItemViewSize = CGRect()
    
    //Sorting and Storage Items
    var featuresWithDrivingRoute : [String : (MGLPointFeature, [CLLocationCoordinate2D], TimeInterval, CLLocationDistance, MGLPointAnnotation)] = [:]
    var featuresWithWalkingRoute : [String : (MGLPointFeature, [CLLocationCoordinate2D], TimeInterval, CLLocationDistance, MGLPointAnnotation)] = [:]
    var sortedStates: [String] = []
    
    var selectedFeature : (MGLPointFeature, [CLLocationCoordinate2D], TimeInterval, CLLocationDistance, MGLPointAnnotation)?
    var currentFeature: MGLFeature?
    
    //Map Interaction Booleans
    var firstLocationSet = false
    var isLocationTapped = false
    var populatedFeaturesWithRoutes = false
    
    var delayedSetupForMapConfiguration = false
    
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var routeTypeSelector: UISegmentedControl! {
        didSet {
            routeTypeSelector.isHidden = true
            routeTypeSelector.layer.cornerRadius = 15
            routeTypeSelector.layer.masksToBounds = true
            routeTypeSelector.layer.borderWidth = 1
            routeTypeSelector.tintColor = Design.Colors.brown
            routeTypeSelector.layer.borderColor = Design.Colors.brown.cgColor
        }
    }
    @IBAction func routeTypeSelector(_ sender: Any) {
        
        guard selectedFeature != nil else { return }
        
        mapView.deselectAnnotation(selectedFeature?.4, animated: true)
        if routeTypeSelector.selectedSegmentIndex == 0 {
            /* Walk */
            if let feature = featuresWithWalkingRoute[getKeyForFeature(feature: selectedFeature!.0)] {
                mapView.selectAnnotation(feature.4, animated: true, completionHandler: nil)
                drawRouteLine(from: feature.1)
            }
        } else {
            /* Drive */
            if let feature = featuresWithDrivingRoute[getKeyForFeature(feature: selectedFeature!.0)] {
                mapView.selectAnnotation(feature.4, animated: true, completionHandler: nil)
                drawRouteLine(from: feature.1)
            }
        }
    }
    
    
    @IBOutlet weak var locationTableView: UITableView! {
        didSet {
            definesPresentationContext = true
            locationTableView.isHidden = true //tableView hidden and map displayed
        }
    }
    
    //MARK: - Initialize the Map View
    func loadMap(){
        mapView = MGLMapView(frame: self.view.bounds, styleURL: self.styleURL)
        mapView.delegate = self //starts running all map building functions
        view.addSubview(mapView)
        mapView.setCenter(unitedStatesCoordinate, zoomLevel: 2.5, animated: false)
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleItemTap(sender:))))
        
        guard fadeView != nil else {
            print("other views not pre-loaded, hieararchy may be incorrect")
            return
        }
        view.insertSubview(mapView, belowSubview: fadeView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = Design.Colors.blue
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - Configure the ActivityIndicator
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        view.addSubview(activityIndicatorContainerView)
        view.addSubview(activityIndicator)
        
        //MARK: - Create Map Fade View
        fadeView = UIView(frame: CGRect(x: 0.0, y: view.frame.size.height - (view.frame.size.height / 3) + navigationController!.navigationBar.frame.height, width: self.view.frame.size.width, height: (view.frame.size.height / 3) - navigationController!.navigationBar.frame.height) )
        view.addSubview(fadeView)
        
        
        //MARK: - Configure the Page View Controller (and create 20 pixel gap for iPhoneX Safe Area)
        var height: CGFloat = 185
        var yValue = self.view.frame.height - height - 8 // coord: (0,0) is top left of view FYI
        switch UIScreen.main.nativeBounds.height {
        case 2436, 2688, 1792: //iPhone X, Xs, XsMax, Xr
            yValue -= 25
            height += 5
        default:
            print("no change needed")
        }
        
        self.locationItemViewSize = CGRect( x: 0, y: yValue, width: self.view.bounds.width, height: height )
        let optionsDict = [UIPageViewController.OptionsKey.interPageSpacing : 5]
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: optionsDict)
        pageViewController.view.frame = locationItemViewSize
        pageViewController.delegate = self
        pageViewController.dataSource = self
        view.addSubview(pageViewController.view)
        
        NotificationCenter.default.addObserver(self, selector: #selector(segueToServices), name: .locationTapped, object: nil)
        
        //MARK: - TableView Setup
        locationTableView.delegate = self
        locationTableView.dataSource = self
        locationTableView.reloadData()
        
        //MARK: - Setup SwitchView Button
        switchMapOrListButton = UIButton(type: .custom)
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: switchMapOrListButton!)]
        
        //MARK: - Location Access
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //MARK: - Configure View Order
        view.bringSubviewToFront(fadeView)
        view.bringSubviewToFront(routeTypeSelector)
        view.bringSubviewToFront(pageViewController.view)
        view.bringSubviewToFront(activityIndicatorContainerView)
        view.bringSubviewToFront(activityIndicator)
        view.bringSubviewToFront(locationTableView)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("LocationView", screenClass: "app")
        
        //MARK: - Clear Variables to avoid Side Menu Conflicts
        //this is needed on home page and here in case home is skipped
        MembershipPurchase.membershipsSelected = []
        AppointmentSearch.selectedServices = []
        
        //MARK: - Location Access
        switch CLLocationManager.authorizationStatus() {
        case .denied:
            print("Location Access Not Available -- Disabling Location Orientated Functions")
            turnOffMap()
            
            alert = UIAlertController(title: "", message: "to gain access to full map view features, please go to Settings > SUGARED + BRONZED > allow location access", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(self.alert!, animated: true, completion: nil)
            
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            
        default:
            //MARK: - Location Access Enabled
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
        
        //MARK: - Internet Delay Handler
        guard turnOffTimer == nil else { print("timer already set"); return }
        turnOffTimer = Timer.scheduledTimer(timeInterval: TimeInterval(6.0), target: self,
            selector: #selector(self.turnOffMapMaybe), userInfo: nil, repeats: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.mapView != nil else {
            print("failed to adjust center")
            return
        }
        activityIndicatorContainerView.center = self.mapView.center
        activityIndicator.center = activityIndicatorContainerView.center
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        turnOffTimer?.invalidate()
        turnOffTimer = nil
    }
    
    @objc func switchMapOrList() {

        if switchToView == "map" {
            
            locationTableView.reloadData()
            locationTableView.isHidden = false
            
            switchMapOrListButton?.setTitle("  MAP ", for: .normal)
            switchMapOrListButton?.setImage(UIImage(named: "map_icon_white"), for: .normal)
            switchMapOrListButton?.setImage(UIImage(named: "map_icon_white"), for: .highlighted)
            
            guard mapView != nil else {
                print("mapView is nil!")
                return
            }
            
            mapView.isHidden = true
            routeTypeSelector.isHidden = true
            locationTableView.isHidden = false
            fadeView.isHidden = true
            switchToView = "list"
            
        } else if switchToView == "list" {
            
            guard mapView != nil else {
                print("mapView is nil!")
                return
            }
            switchMapOrListButton?.setTitle("   LIST  ", for: .normal)
            switchMapOrListButton?.setImage(UIImage(named: "list_icon_white"), for: .normal)
            switchMapOrListButton?.setImage(UIImage(named: "list_icon_white"), for: .highlighted)
            
            mapView.isHidden = false
            
            routeTypeSelector.isHidden = routeTypeSelectorInvisible
            locationTableView.isHidden = true
            fadeView.isHidden = false
            switchToView = "map"
        }
        
        if switchMapOrListButton != nil {
            let barButton = UIBarButtonItem(customView: switchMapOrListButton!)
            self.navigationItem.setRightBarButtonItems([barButton], animated: true)
        } else {
            print("error initializing switchMapOrListButton!")
        }
    }
    
    @objc func turnOffMapMaybe(){
        if !self.activityIndicator.isHidden {
            print("error - too much time taken for map operations")
            self.turnOffMap()
        }
    }
    
    func turnOffMap(disableMap: Bool = false) {
        
        self.activityIndicator.isHidden = true
        self.activityIndicatorContainerView.isHidden = true
        NotificationCenter.default.post(name: .mapPreloadCompleted, object: nil)
        
        //switch to List View if not already there
        if switchToView == "map" {
            switchMapOrList()
        }
        
        //disable switchMapOrList button
        if disableMap == true && switchMapOrListButton != nil {
            switchMapOrListButton!.isEnabled = false // this doesn't actually do anything right now
            let barButton = UIBarButtonItem(customView: switchMapOrListButton!) // FIX IT SO IT DOES!
            self.navigationItem.setRightBarButtonItems([barButton], animated: true)
            
            //display error message
            alert = UIAlertController(title: "", message: "to use the map view, please find a stronger internet connection and restart the application", preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(self.alert!, animated: true, completion: nil)
        } else {
            routeTypeSelectorInvisible = true
            mapView?.setCenter(unitedStatesCoordinate, zoomLevel: 2.5, animated: false)
            
        }
        
    }
    
    
    
    @objc func handleItemTap(sender: UIGestureRecognizer) {
        
        if sender.state == .ended {
            let layers: Set = ["store-locations"]
            let point = sender.location(in: sender.view!)
            
            if mapView.visibleFeatures(at: point, styleLayerIdentifiers: layers).count > 0 {
        
                // If there is an item at the tap's location, change the marker to the selected marker.
                for feature in mapView.visibleFeatures(at: point, styleLayerIdentifiers: layers)
                    where feature is MGLPointFeature {
                        guard currentFeature == nil || !(currentFeature?.coordinate.latitude == feature.coordinate.latitude && currentFeature?.coordinate.longitude == feature.coordinate.longitude) else {
                            return
                        }
                        
                        changeItemColor(feature: feature)
                        generateItemPages(feature: feature as! MGLPointFeature)
                        
                        pageViewController.view.isHidden = false
                        isLocationTapped = true
                }
            } else {
                // If there isn't an item at the tap's location, reset the map by clearing the previously touched object of its select attributes
                changeItemColor(feature: MGLPointFeature())
                
                if let routeLineLayer = mapView.style?.layer(withIdentifier: "route-style") {
                    routeLineLayer.isVisible = false
                }
                
                if mapView.selectedAnnotations.count > 0 {
                    mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
                }
                
                pageViewController.view.isHidden = true
                currentFeature = nil
                
                
            }
        }
    }
    
    func changeItemColor(feature: MGLFeature) {
        guard let layer = mapView.style?.layer(withIdentifier: "store-locations") as? MGLSymbolStyleLayer else {
            print("map layer error!")
            turnOffMap(disableMap: true)
            return
        }
        if let name = feature.attribute(forKey: "name") as? String {
            currentFeature = feature
            // Change the icon to the selected icon based on the feature name. If multiple items have the same name, choose an attribute that is unique.
            layer.iconImageName = NSExpression(format: "TERNARY(name = %@, 'selected_marker', 'unselected_marker')", name)
            
        } else {
            // Deselect all items if no feature was selected.
            layer.iconImageName = NSExpression(forConstantValue: "unselected_marker")
        }
    }
    
    
    //MARK: - Directions
    func getRoute(from origin: CLLocationCoordinate2D, to destination: MGLPointFeature) {
        
        guard let ID = destination.attribute(forKey: "ID") as? NSString else {
            print("error retreiving and parsing locationID from map object data")
            turnOffMap(disableMap: true)
            return
        }
        
        var routeCoordinates : [CLLocationCoordinate2D] = []
        let originWaypoint = Waypoint(coordinate: origin)
        let destinationWaypoint = Waypoint(coordinate: destination.coordinate)
        let locationID = Int(ID.doubleValue)
        
        
        func runFinish() {
            //if all location distances have been found, organize the features and locations by distance
            if !self.isLocationTapped && self.numberOfLocationsLeftToCalculate == 0 {
                
                var sortedLocations = SugaredAndBronzed.locations.sorted(by: { $0.1.distance < $1.1.distance })
                let closestState: String = sortedLocations.first!.1.state
                self.sortedStates = SugaredAndBronzed.locationIDsByState.keys.reversed() //.reversed() makes this the right type
                let index = self.sortedStates.firstIndex(of: closestState)!
                self.sortedStates.swapAt(0, index)
                
                
                let state: String = self.sortedStates.first!
                let IDs: [Int] = SugaredAndBronzed.locationIDsByState[state]!
                var sortedIDs: [Int] = []
                for _ in IDs {
                    let index = sortedLocations.firstIndex(where: { SugaredAndBronzed.locations[$0.key]!.state == state })!
                    let ID = sortedLocations.remove(at: index).key
                    sortedIDs.append(ID)
                }
                SugaredAndBronzed.locationIDsByState[state] = sortedIDs
                
                
                let sortedFeatures = self.featuresWithDrivingRoute.sorted(by: { Int($0.value.3) < Int($1.value.3) })
                let feature: MGLPointFeature? = sortedFeatures.first?.value.0
                self.features.sort(by: {
                    Int(self.featuresWithDrivingRoute[self.getKeyForFeature(feature: $0)]!.3) < Int(self.featuresWithDrivingRoute[self.getKeyForFeature(feature: $1)]!.3)
                })
                
                guard feature != nil else {
                    print("error LocationsView has no closest feature")
                    self.turnOffMap() //locations are all too far to compute any distances
                    return
                }
                
                let closestDistance = Int(self.featuresWithDrivingRoute[self.getKeyForFeature(feature: feature!)]!.3)
                guard closestDistance < 100 else {
                    print("closest location too far")
                    self.turnOffMap() //locations are all too far to be reasonable
                    return
                }
                self.changeItemColor(feature: feature!)
                self.generateItemPages(feature: feature!)
                
                self.pageViewController.view.isHidden = false
                self.isLocationTapped = true
                
                self.locationTableView.reloadData()
                
                self.activityIndicator.isHidden = true
                self.activityIndicatorContainerView.isHidden = true
                NotificationCenter.default.post(name: .mapPreloadCompleted, object: nil)
                
            }
        }
        
        func runDirections(type: MBDirectionsProfileIdentifier) {
            
            
            _ = Directions.shared.calculate(RouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: type)) { (waypoints, routes, error) in
                
                self.numberOfLocationsLeftToCalculate -= 1
                
                guard error == nil else {
                    if !error!.description.hasCommonPrefix(with: "Error Domain=com.mapbox.directions.ErrorDomain Code=-1 \"Route exceeds maximum distance limitation\"") {
                        print("directions error: \(error!) for location \(SugaredAndBronzed.locations[locationID]!.name) ")
                    }
                    runFinish()
                    return
                }
                
                guard let route = routes?.first else {
                    print("error returning a route")
                    self.turnOffMap(disableMap: true) //mapBox computation error
                    return
                }
                
                let routeDistance = route.distance * 0.000621371192 //route distance in miles
                let routeTime = route.expectedTravelTime / 60 //route time in minutes
                routeCoordinates = route.coordinates!
                
                let annotation = MGLPointAnnotation()
                annotation.coordinate = destination.coordinate
                let shortenedMinutes = Int(routeTime)
                let shortenedMiles = round(Double(routeDistance * 10))/10
                var minutesText = ""
                var milesText = ""
                if shortenedMinutes > 60 {
                    minutesText = "more than an hour"
                } else {
                    minutesText = "\(shortenedMinutes) min"
                }
                if shortenedMiles > 100 {
                    milesText = "> 100 miles away"
                } else {
                    milesText = "\(shortenedMiles) miles away"
                }
                SugaredAndBronzed.locations[locationID]!.distanceLabel = milesText
                SugaredAndBronzed.locations[locationID]!.distance = shortenedMiles
                
                let key = self.getKeyForFeature(feature: destination)
                
                switch type {
                case .automobileAvoidingTraffic:
                    annotation.title = "\(milesText) ∙ \(minutesText) drive"
                    self.featuresWithDrivingRoute[key] = (destination, routeCoordinates, routeTime, routeDistance, annotation)
                case .walking:
                    annotation.title = "\(milesText) ∙ \(minutesText) walk"
                    self.featuresWithWalkingRoute[key] = (destination, routeCoordinates, routeTime, routeDistance, annotation)
                default:
                    break
                }
                
                self.mapView.addAnnotation(annotation)
                
                runFinish()
            }
        }
        
        //MARK: - Run the functions above for each direction type
        runDirections(type: .automobileAvoidingTraffic)
        runDirections(type: .walking)
        
    }
    
    
    
    func populateFeaturesWithRoutes() {
        
        guard CLLocationCoordinate2DIsValid(userLocationFeature.coordinate) else  {
            print("error - attempted to populate routes with no valid userLocation")
            turnOffMap(disableMap: true)
            return
        }
        guard features.count != 0 else {
            print("error - no features")
            turnOffMap(disableMap: true)
            return
        }
        
        self.populatedFeaturesWithRoutes = true
        numberOfLocationsLeftToCalculate = SugaredAndBronzed.locations.count * 2 //walking + driving = 2
        
        for feature in features {
            getRoute(from: userLocationFeature.coordinate, to: feature)
        }
    }
    
    //MARK: - Draw a route line using the stored route for a feature.
    func drawRouteLine(from route: [CLLocationCoordinate2D]) {
        
        guard Int(selectedFeature!.3) <= 200 else {
            return
        }
        
        if route.count > 0 {
            if let routeStyleLayer = self.mapView.style?.layer(withIdentifier: "route-style") {
                routeStyleLayer.isVisible = true
            }
            
            let polyline = MGLPolylineFeature(coordinates: route, count: UInt(route.count))
            
            if let source = self.mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
                source.shape = polyline
            } else {
                let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
                self.mapView.style?.addSource(source)
                
                let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
                
                // Set the line color to the theme's color.
                lineStyle.lineColor = NSExpression(forConstantValue: Design.Colors.blue)
                lineStyle.lineJoin = NSExpression(forConstantValue: "round")
                lineStyle.lineWidth = NSExpression(forConstantValue: 3)
                
                if let userDot = mapView.style?.layer(withIdentifier: "user-location-style") {
                    self.mapView.style?.insertLayer(lineStyle, below: userDot)
                } else {
                    for layer in (mapView.style?.layers.reversed())! where layer.isKind(of: MGLSymbolStyleLayer.self) {
                        self.mapView.style?.insertLayer(lineStyle, below: layer)
                        break
                    }
                }
            }
        }
    }
    
    //MARK: - Find the correct zoom level for a distance between two coordinates
    func getCoordinatesZoomLevel(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Double {
        let mapDimensions = (Double(mapView.bounds.height) - 300, Double(mapView.bounds.width) - 200) //(height, width)
        var WORLD_DIM: (Double, Double) = ( 350, 350 ) //modify this to change view scope [note: log makes the size change opposite]
        
        ///compute values
        func latRad(lat: Double) -> Double {
            let sinValue = sin(lat * .pi / 180)
            let radX2 = log((1 + sinValue) / (1 - sinValue)) / 2
            return max(min(radX2, .pi), -.pi) / 2
        }
        let latFraction = abs( (latRad(lat: coordinate1.latitude) - latRad(lat: coordinate2.latitude)) / .pi )
        let lngFraction = abs( coordinate1.longitude - coordinate2.longitude ) / 360
        
        //zoom equations in the lat and long directions
        let latZoom = floor(log(mapDimensions.0 / WORLD_DIM.0 / latFraction) / 0.6931471805599453)
        let lngZoom = floor(log(mapDimensions.1 / WORLD_DIM.1 / lngFraction) / 0.6931471805599453)
        
        //give back the most zoomed out coordinate
        return min(latZoom, lngZoom) - 0.25
        
    }
    
    
    
    //MARK: Custom Callout Controller.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return (Int(selectedFeature!.3) <= 200) && annotation.responds(to: #selector(getter: MGLAnnotation.title))
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        var image = UIImage(named: "invisible_dot")!
        
        // The anchor point of an annotation is currently always the center. To shift the anchor point to the bottom of the annotation, the image asset includes transparent bottom padding equal to the original image height.
        // To make this padding non-interactive, we create another image object with a custom alignment rect that excludes the padding.
        image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0))
        
        return MGLAnnotationImage(image: image, reuseIdentifier: "pisa")
    }
    
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        // Instantiate and return our custom callout view.
        return CustomCalloutView(representedObject: annotation)
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        mapView.deselectAnnotation(annotation, animated: true) //prevents weird behaviors by just removing the annotation
        if let routeLineLayer = mapView.style?.layer(withIdentifier: "route-style") {  routeLineLayer.isVisible = false  }
        pageViewController.view.isHidden = true
        let tempFeature = currentFeature; currentFeature = nil
        
        // Show an alert offering to go to map
        let alert = UIAlertController(title: "Get directions?", message: "this will take you out of the app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { UIAlertAction in
            //Get the actual location coordinates!
            guard let locID: String = self.selectedFeature!.0.attribute(forKey: "ID") as? String else {
                print("error retrieving location from selectedFeature")
                return
            }
            
            guard let location = SugaredAndBronzed.locations[Int(locID)!] else {
                print("error retrieving location with ID: \(locID)")
                return
            }
            
            let latitude: CLLocationDegrees =  location.latitude
            let longitude: CLLocationDegrees = location.longitude
            
            
            let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
            
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = "\(location.name)"
            mapItem.openInMaps()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { UIAlertAction in
            DispatchQueue.main.async {
                self.changeItemColor(feature: tempFeature!)
                self.generateItemPages(feature: tempFeature as! MGLPointFeature)
                self.pageViewController.view.isHidden = false
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - Custom Callout View (The Distance and Time Display for the Location's Markers)
class CustomCalloutView: UIView, MGLCalloutView, UITextFieldDelegate {
    
    var representedObject: MGLAnnotation
    
    // Allow the callout to remain open during panning.
    let dismissesAutomatically: Bool = false
    let isAnchoredToAnnotation: Bool = true
    
    lazy var leftAccessoryView = UIView() /* unused */
    lazy var rightAccessoryView = UIView() /* unused */
    
    weak var delegate: MGLCalloutViewDelegate?
    
    let tipHeight: CGFloat = 10.0
    let tipWidth: CGFloat = 20.0
    
    let mainBody: UIButton = {
        let mainBody = UIButton(type: .system)
        mainBody.backgroundColor = .white
        mainBody.tintColor = Design.Colors.gray
        mainBody.titleLabel!.textColor = .gray
        mainBody.titleLabel!.font = UIFont(name: "AvenirNext-Regular", size: 13)
        mainBody.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 25.0)
        mainBody.frame = CGRect(x: 0, y: 0, width: 100, height: 15)
        mainBody.translatesAutoresizingMaskIntoConstraints = false
        mainBody.layer.cornerRadius = 15
        return mainBody
    }()
    
    let imageView:UIImageView = {
        let imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageview.translatesAutoresizingMaskIntoConstraints = false
        imageview.contentMode = .scaleAspectFill
        imageview.image = UIImage(named: "directions_icon")!
        return imageview
    }()
    
    override func didMoveToWindow() {
        mainBody.titleLabel?.textColor = .gray
    }
    
    //override below is required, do not delete. see https://github.com/mapbox/mapbox-gl-native/issues/9228
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    
    required init(representedObject: MGLAnnotation) {
        self.representedObject = representedObject
        super.init(frame: .zero)
        
        backgroundColor = .clear
        addSubview(mainBody)
        addSubview(imageView)
        
        //MARK: - Add Constraints to subviews
        mainBody.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        mainBody.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        mainBody.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        
        imageView.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        imageView.centerYAnchor.constraint(equalTo: mainBody.centerYAnchor, constant: 0).isActive = true
        imageView.rightAnchor.constraint(equalTo: mainBody.rightAnchor, constant: -2).isActive = true
    }
    
    required init?(coder decoder: NSCoder) {
        //this is a fatalError, which crashes the app if unexpected behavior occurs
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - MGLCalloutView API
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        
        delegate?.calloutViewWillAppear?(self)
        
        view.addSubview(self)
        
        // Prepare title label.
        mainBody.setTitle(representedObject.title!, for: .normal)
        mainBody.sizeToFit()
        
        if isCalloutTappable() {
            // Handle taps and eventually try to send them to the delegate (usually the map view).
            mainBody.addTarget(self, action: #selector(CustomCalloutView.calloutTapped), for: .touchUpInside)
        } else {
            // Disable tapping and highlighting.
            mainBody.isUserInteractionEnabled = false
        }
        
        // Prepare our frame, adding extra space at the bottom for the tip.
        let width = mainBody.bounds.size.width
        let height = mainBody.bounds.size.height + tipHeight
        let x = rect.origin.x + (rect.size.width/2.0) - (width/2.0)
        let y = rect.origin.y - height
        frame = CGRect(x: x, y: y, width: width, height: height)
        
        //fade in
        if animated {
            alpha = 0
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.alpha = 1
            }
        } else {
            self.alpha = 1
        }
    }
    
    func dismissCallout(animated: Bool) {
        //fade out
        guard superview != nil else {
            return
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.alpha = 0
                }, completion: { [weak self] _ in
                    self?.removeFromSuperview()
            })
        } else {
            removeFromSuperview()
        }
        
    }
    
    // MARK: - Callout interaction handlers
    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight)) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }
    
    @objc func calloutTapped() {
        if isCalloutTappable() && delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped)) {
            delegate!.calloutViewTapped!(self)
        }
    }
    
    // MARK: - Draw the pointed tip at the bottom.
    override func draw(_ rect: CGRect) {
        
        let fillColor: UIColor = .white
        let tipLeft = rect.origin.x + (rect.size.width / 2.0) - (tipWidth / 2.0)
        let tipBottom = CGPoint(x: rect.origin.x + (rect.size.width / 2.0), y: rect.origin.y + rect.size.height)
        let heightWithoutTip = rect.size.height - tipHeight - 1
        let currentContext = UIGraphicsGetCurrentContext()!
        let tipPath = CGMutablePath()
        tipPath.move(to: CGPoint(x: tipLeft, y: heightWithoutTip))
        tipPath.addLine(to: CGPoint(x: tipBottom.x, y: tipBottom.y))
        tipPath.addLine(to: CGPoint(x: tipLeft + tipWidth, y: heightWithoutTip))
        tipPath.closeSubpath()
        fillColor.setFill()
        currentContext.addPath(tipPath)
        currentContext.fillPath()
    }
}

extension Notification.Name {
    static let locationTapped = Notification.Name("locationTapped")
    static let mapPreloadCompleted = Notification.Name("mapPreloadCompleted")
}
