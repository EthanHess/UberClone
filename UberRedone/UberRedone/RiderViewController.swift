//
//  RiderViewController.swift
//  UberRedone
//
//  Created by Ethan Hess on 1/9/16.
//  Copyright © 2016 Ethan Hess. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //IBOutlet properties
    @IBOutlet var callUberButton : UIButton!
    @IBOutlet var map : MKMapView!
    
    //Other properties
    var riderRequestActive = false
    var driverOnTheWay = false
    var locationManager:CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sets up location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func callUber(sender: AnyObject) {
        
        //sets button title and action according to weather rider has requested or not
        
        if riderRequestActive == false {
            
            let riderRequest = PFObject(className: "riderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude:latitude, longitude:longitude)
            
            //saves parse request object from rider
            riderRequest.saveInBackgroundWithBlock({ (success, error) -> Void in
                
                if success {
                    self.callUberButton.setTitle("Cancel Uber", forState: UIControlState.Normal)
                }
                
                else {
                    
                    let alert = UIAlertController(title: "Could not call Uber", message: "Please try again!", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
            })
            
            riderRequestActive = true
        }
            
        //deletes request if rider cancels
        
        else {
            
            self.callUberButton.setTitle("Call an Uber", forState: UIControlState.Normal)
            
            riderRequestActive = false
            
            let query = PFQuery(className: "riderRequest")
            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if error == nil {
                    
                    if let objects = objects as [PFObject]? {
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }
                }
                else {
                    print(error)
                }
            })
            
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //grabs lat and long from current location
        
        let location : CLLocationCoordinate2D = manager.location!.coordinate
        
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        //query 
        
        let query = PFQuery(className: "riderRequest")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                
                if let objects = objects as [PFObject]? {
                    
                    for object in objects {
                        
                        //queries driver which responded and grabs their location
                        
                        if let driverUsername = object["driverResponded"] {
                            
                            let query = PFQuery(className: "driverLocation")
                            query.whereKey("username", equalTo: driverUsername)
                            
                            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                                
                                if error == nil {
                                    
                                    if let objects = objects as [PFObject]? {
                                        for object in objects {
                                            
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                //gets distance of driver from user
                                                
                                                let distanceMeters = userCLLocation.distanceFromLocation(driverCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                let roundedDistanceKM = Double(round(distanceKM * 10) / 10)
                                                
                                                //change button and boolean state
                                                
                                                self.callUberButton.setTitle("Driver is \(roundedDistanceKM)km away!", forState: UIControlState.Normal)
                                                
                                                self.driverOnTheWay = true
                                                
                                                //establish map region
                                                
                                                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.005
                                                let lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.005
                                                
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                self.map.setRegion(region, animated: true)
                                                
                                                //remove annotations to keep updating and not create line of pins
                                                self.map.removeAnnotations(self.map.annotations)
                                                
                                                //adds pins at driver and users location
                                                
                                                var pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                var objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Your Location"
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver Location"
                                                self.map.addAnnotation(objectAnnotation)
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
        
        if driverOnTheWay == false {
            
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.map.setRegion(region, animated: true)
            self.map.removeAnnotations(self.map.annotations)
            
            let pinLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Your location"
            self.map.addAnnotation(objectAnnotation)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "logoutRider" {
            PFUser.logOut()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
