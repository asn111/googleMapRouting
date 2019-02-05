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
    let destLatitude="33.7294"
    let destLongitude="73.0749"
    let geoCoder = CLGeocoder()
    var locManager = CLLocationManager()
    let marker = GMSMarker()
    var currentLocation: CLLocation!
    let zoomLevel = 15.0
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
    func showOnMap() {
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {(placemarks, error) in
            
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
                self.marker.title = "\(self.locality), \(self.administrativeArea)"
                self.marker.snippet = "\(self.country) \(self.isoCon)"
                
            }
        })
        
        //MAP
        let camera = GMSCameraPosition.camera(withLatitude: Double(lat)!, longitude: Double(long)!, zoom: Float(zoomLevel))
        
        mapView.camera = camera
        showMarker(position: camera.target)
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.indoorPicker = true
        mapView.isMyLocationEnabled = true
    }
    
    func showMarker(position: CLLocationCoordinate2D){
        
        //this line will move you back to your current location if you go throu the map
        //marker.tracksViewChanges = true
        marker.position = position
        marker.isDraggable=true
        marker.icon = UIImage(named: "pin_icon")
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
            print("LAT \(lat) && LONG \(long)")
            showOnMap()
            fetchMapData()
            //getRoute()
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
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: Float(zoomLevel))
        
        mapView.camera = camera
        mapView.animate(to: camera)
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
                }
        }
        
    }
    
    func addPolyLine(encodedString: String) {
        
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 2.5
        polyline.strokeColor = .cyan
        polyline.map = mapView
        
       
        
    }
    
}
extension ViewController: GMSMapViewDelegate{
    
}
