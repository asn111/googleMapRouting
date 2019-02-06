//
//  ViewController.swift
//  Google Maps tut
//
//  Created by Ahsan Iqbal on 24/01/2019.
//  Copyright © 2019 SelfIT. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Alamofire


class ViewController: UIViewController,CLLocationManagerDelegate {
    //MARK:- Outlets
    @IBOutlet fileprivate weak var mapView: GMSMapView!
    
    //MARK:- Properties
    let destLatitude="33.5207"
    let destLongitude="73.1580"
    let geoCoder = CLGeocoder()
    var locManager = CLLocationManager()
    let marker1 = GMSMarker()
    let marker2 = GMSMarker()
    var currentLocation: CLLocation!
    let zoomLevel = 12.0
    var long = ""
    var lat = ""
    var locality = ""
    var administrativeArea = ""
    var country = ""
    var name = ""
    var isoCon = ""
    var region: CLRegion!
    var timezone: TimeZone!
    let api_key = "AIzaSyDH_d2KWQWR77bmgBNcVor7Hztz8AuTExg"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //getLocPermission()
        
        
        //LOCATOIN
        locManager.requestAlwaysAuthorization()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.distanceFilter = 10
        locManager.startUpdatingLocation()
        
        
        if currentLocation != nil {
            accessLoc()
        } else {
            getLocPermission()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
    }
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        if currentLocation == nil {
            getLocPermission()
        }
    }
    func showOnMap(currentLoc: CLLocation, marker: String) {
        geoCoder.reverseGeocodeLocation(currentLoc, completionHandler: {(placemarks, error) in
            
            if (error != nil) {
                print("Error in reverseGeocode")
            }
            
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count > 0 {
                let placemark = placemarks![0]
                self.locality = placemark.locality!
                self.administrativeArea = placemark.administrativeArea!
                self.country = placemark.country!
                self.name = placemark.name!
                self.isoCon = placemark.isoCountryCode!
                self.timezone = placemark.timeZone!
                if marker.contains("marker1"){
                self.marker1.title = "\(placemark.name!)"
                self.marker1.snippet = "\(placemark.country!)"
                }
            }
        })
        
        //MAP
        let camera = GMSCameraPosition.camera(withLatitude: Double(currentLoc.coordinate.latitude), longitude: Double(currentLoc.coordinate.longitude), zoom: Float(zoomLevel))
        
        mapView.camera = camera
        if marker.contains("marker1") {
        showMarker(position: camera.target, marker: marker1,iconName: "car_icon" )
        } else if marker.contains("marker2") {
            showMarker(position: camera.target, marker: marker2, iconName: "pin_icon")
        }
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.indoorPicker = true
        //mapView.isMyLocationEnabled = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 143, right: 10)
       // mapView.selectedMarker = marker

    }
    
    func showMarker(position: CLLocationCoordinate2D, marker: GMSMarker, iconName: String){
        
        marker.tracksViewChanges = true
        marker.position = position
        marker.isDraggable=false
        //marker.groundAnchor = CGPoint(x: 0.1, y: 0.1)
        marker.icon = UIImage(named: iconName)
        marker.tracksInfoWindowChanges = true
        marker.map = mapView
    }
    
    func getLocPermission() {
        
        switch(CLLocationManager.authorizationStatus()) {
        case .notDetermined:
            locManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            accessLoc()
            break
        case  .denied:
            showLocationDisabledPopUp()
            break
        default:
            print("Something wrong with Location services")
            break
            
        }
    }
    func accessLoc() {
        currentLocation = locManager.location
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            
            currentLocation = locManager.location
            long = "\(currentLocation.coordinate.longitude)"
            lat = "\(currentLocation.coordinate.latitude)"
            let message = "LAT \(lat) && LONG \(long)"
            print(message)
            showOnMap(currentLoc: currentLocation, marker: "marker2")
            fetchMapData()
        }
    }
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Location Access Disabled",
                                                message: "Admin needs to know about your location!",
                                                preferredStyle: .alert)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        self.present(alertController, animated: true, completion: nil)
    }
    // MARK: location manger Delegate method
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            if lat == "" {
            accessLoc()
            }
        }
        if status == CLAuthorizationStatus.denied {
            showLocationDisabledPopUp()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        DispatchQueue.main.async {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: Float(self.zoomLevel))
            
            self.mapView.camera = camera
            self.mapView.animate(to: camera)
            self.showOnMap(currentLoc: location, marker: "marker1")

        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 180.0) { // Change `2.0` to the desired number of seconds.
            self.fetchMapData()
        }


    }
    
    
    func fetchMapData() {
        
       
        let directionURL = "https://maps.googleapis.com/maps/api/directions/json?" +
            "origin=\(lat),\(long)&destination=\(destLatitude),\(destLongitude)&" +
        "key=\(api_key)"
        
        
        
        Alamofire.request(directionURL).responseJSON
            { response in
                print("RESPONCE: \(response)")
                if let JSON = response.result.value {
                    
                    let mapResponse: [String: AnyObject] = JSON as! [String : AnyObject]
                    
                    let routesArray = (mapResponse["routes"] as? Array) ?? []
                    
                    let routes = (routesArray.first as? Dictionary<String, AnyObject>) ?? [:]
                    
                    let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String,AnyObject>) ?? [:]
                    let polypoints = (overviewPolyline["points"] as? String) ?? ""
                    let line  = polypoints
                    
                    self.addPolyLine(encodedString: line)
                    let coordinate:CLLocation = CLLocation(latitude: Double(self.destLatitude)!, longitude: Double(self.destLongitude)!)

                    
                    
                    let legsArray = (routes["legs"] as? Array) ?? []
                    let legs = (legsArray.first as? Dictionary<String, AnyObject>) ?? [:]
                    print(legs["end_address"]!)
                    let distance = (legs["distance"] as? Dictionary<String,AnyObject>) ?? [:]
                    let duration = (legs["duration"] as? Dictionary<String,AnyObject>) ?? [:]
                    
                    DispatchQueue.main.async {
                        self.showOnMap(currentLoc: coordinate, marker: "marker2")
                        self.marker2.title = "Distance: \(distance["text"]!), ETA: \(duration["text"]!)"
                        self.marker2.snippet = "Destination \(legs["end_address"]!)"
                    }
                   

                    
                }
        }
        
    }
    
    func addPolyLine(encodedString: String) {
        DispatchQueue.main.async {
            let path = GMSMutablePath(fromEncodedPath: encodedString)
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 4
            polyline.strokeColor = .black
            polyline.map = self.mapView
        }
       
        
    }
    
}
extension ViewController: GMSMapViewDelegate{
    
}

