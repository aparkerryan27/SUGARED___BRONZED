//
//  LocationViewMap.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Mapbox

//MARK: Page View Controller setup
extension LocationView: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        guard let view = pendingViewControllers.first?.view as? LocationItemView else {
            print("error initializing properly on pageViewController")
            turnOffMap(disableMap: true)
            return
        }
        
        if routeTypeSelector.selectedSegmentIndex == 0  { //Walk
            if let currentFeature = featuresWithWalkingRoute[getKeyForFeature(feature: view.selectedFeature)] {
                selectedFeature = currentFeature
            }
        } else { //Drive
            if let currentFeature = featuresWithDrivingRoute[getKeyForFeature(feature: view.selectedFeature)] {
                selectedFeature = currentFeature
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let view = pageViewController.viewControllers?.first?.view as? LocationItemView {
            
            var currentFeature: (MGLPointFeature, [CLLocationCoordinate2D], TimeInterval, CLLocationDistance, MGLPointAnnotation)? = nil
            if routeTypeSelector.selectedSegmentIndex == 0  { //Walk
                currentFeature = featuresWithWalkingRoute[getKeyForFeature(feature: view.selectedFeature)]
            } else { //Drive
                currentFeature = featuresWithDrivingRoute[getKeyForFeature(feature: view.selectedFeature)]
            }
            
            if currentFeature == nil {
                //No Directions access, doing workaround
                
                changeItemColor(feature:  view.selectedFeature )
                mapView.setCenter( view.selectedFeature.coordinate, zoomLevel: 10, animated: true)
                
            } else {
                changeItemColor(feature: selectedFeature!.0 )
                
                //Setting Directions and Center is parallel to the generateItemPages function! make these a seperate function at some point for order
                drawRouteLine(from: selectedFeature!.1)
                mapView.selectAnnotation(selectedFeature!.4, animated: false, completionHandler: nil)
                
                guard locationManager.location != nil else {
                    print("failed to create zoom bounds because user location is nil")
                    return
                }
                
                let midpoint = selectedFeature?.0.coordinate.middleLocationWith(location: locationManager.location!.coordinate)
                let midpointZoom: Double = getCoordinatesZoomLevel(coordinate1: selectedFeature!.0.coordinate, coordinate2: locationManager.location!.coordinate)
                mapView.setCenter(midpoint!, zoomLevel: midpointZoom, animated: true)
            }
            
            
            
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if let currentFeature = selectedFeature?.0 {
            let index = getIndexForFeature(feature: currentFeature)
            let prevVC = UIViewController()
            var prevFeature = MGLPointFeature()
            
            if index - 1 < 0 {
                prevFeature = features.last!
            } else {
                prevFeature = features[index-1]
            }
            prevVC.view = LocationItemView(feature: prevFeature)
            itemView = prevVC.view as! LocationItemView?
            
            return prevVC
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if let currentFeature = selectedFeature?.0 {
            
            let index = getIndexForFeature(feature: currentFeature)
            let nextVC = UIViewController()
            var nextFeature = MGLPointFeature()
            
            //wraps around the array for the next feature
            if index != (features.count - 1) {
                nextFeature = features[index+1]
            } else {
                nextFeature = features[0]
            }
            
            if routeTypeSelector.selectedSegmentIndex == 0 {
                selectedFeature = featuresWithWalkingRoute[getKeyForFeature(feature: nextFeature)]
            } else {
                selectedFeature = featuresWithDrivingRoute[getKeyForFeature(feature: nextFeature)]
            }
            
            nextVC.view = LocationItemView(feature: nextFeature)
            itemView = nextVC.view as! LocationItemView?
            
            return nextVC
            
        }
        
        return nil
    }
    
    
    // Determine the feature that was tapped on.
    func generateItemPages(feature: MGLPointFeature) {
        
        let vc = UIViewController()
        itemView = LocationItemView(feature: feature)
        itemView.frame = locationItemViewSize
        
        vc.view = itemView
        vc.view.autoresizingMask =  [ .flexibleHeight, .flexibleWidth ]
        
        pageViewController.setViewControllers([vc], direction: .forward, animated: true, completion: nil)
        
        if routeTypeSelector.selectedSegmentIndex == 0 {
            selectedFeature = featuresWithWalkingRoute[getKeyForFeature(feature: feature)]
        } else {
            selectedFeature = featuresWithDrivingRoute[getKeyForFeature(feature: feature)]
        }
        
        if selectedFeature != nil  {
            // setting directions
            drawRouteLine(from: selectedFeature!.1)
            mapView.selectAnnotation(selectedFeature!.4, animated: false, completionHandler: nil)
            guard locationManager.location != nil else {
                print("failed to create zoom bounds because user location is nil")
                return
            }
            
            let midpoint = selectedFeature?.0.coordinate.middleLocationWith(location: locationManager.location!.coordinate)
            let midpointZoom: Double = getCoordinatesZoomLevel(coordinate1: selectedFeature!.0.coordinate, coordinate2: locationManager.location!.coordinate)
            mapView.setCenter(midpoint!, zoomLevel: midpointZoom, animated: true)
            
        } else {
            // no directions because location is not available
            mapView.setCenter(feature.coordinate, zoomLevel: 11, animated: true)
            routeTypeSelector.isHidden = true
            return
        }
        
    }
    
    @objc func segueToServices(){
        self.performSegue(withIdentifier: "toServicesSegue", sender: nil)
    }
}

class LocationItemView : UIView { //The card popup description for the location.
    
    var selectedFeature = MGLPointFeature()
    
    @IBOutlet var containerView: LocationItemView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    
    @IBOutlet weak var hiddenIDLabel: UILabel!
    
    @IBOutlet weak var selectButton: UIButton!
    @IBAction func selectButton(_ sender: Any) {
        
        AppointmentSearch.location = SugaredAndBronzed.locations[Int(hiddenIDLabel.text!)!]
        MembershipPurchase.location = SugaredAndBronzed.locations[Int(hiddenIDLabel.text!)!]
        
        guard AppointmentSearch.location != nil else {
            print("failed assigning location ID")
            return
        }
        
        NotificationCenter.default.post(name: .locationTapped, object: nil)
        
        AppointmentSearch.selectedServices = []
        
    }
    
    var routeDistance = 0
    
    override init(frame: CGRect) {
        super.init(frame: CGRect())
        
        Bundle.main.loadNibNamed("LocationItemView", owner: self, options: nil)
        backgroundColor = .clear
        
        self.frame = bounds
        addSubview(containerView)
        
        containerView.backgroundColor = .clear
        containerView.frame = bounds
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        containerView.layer.shadowColor = UIColor.black.cgColor
        
        containerView.layer.shadowOffset = CGSize(width: 0.1, height: 0.5)
        containerView.layer.shadowOpacity = 0.3
        
    }
    
    required convenience init(feature: MGLPointFeature) {
        self.init(frame: CGRect())
        self.selectedFeature = feature
        updateLabels()
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.masksToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Update the attribute keys based on your data's format.
    public func updateLabels() {
        if let name : String = selectedFeature.attribute(forKey: "name") as? String {
            containerView.nameLabel.text = name
        }
        if let hours : String = selectedFeature.attribute(forKey: "hours") as? String {
            containerView.hoursLabel.text = hours
        }
        if let number : String = selectedFeature.attribute(forKey: "phone") as? String  {
            containerView.phoneLabel.text = number
        }
        if let address: String = selectedFeature.attribute(forKey: "address") as? String {
            containerView.addressLabel.text = address
        }
        if let ID: String = selectedFeature.attribute(forKey: "ID") as? String {
            containerView.hiddenIDLabel.text = ID
        }
        
    }
}
