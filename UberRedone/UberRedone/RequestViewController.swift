//
//  RequestViewController.swift
//  UberRedone
//
//  Created by Ethan Hess on 1/9/16.
//  Copyright © 2016 Ethan Hess. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RequestViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var map: MKMapView!
    
    var requestLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var requestUsername:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //remove eventually
        print(requestUsername)
        print(requestLocation)
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.map.setRegion(region, animated: true)
        
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = requestLocation
        objectAnnotation.title = requestUsername
        
        self.map.addAnnotation(objectAnnotation)
    }
    
    @IBAction func pickUpRider(sender: AnyObject) {
        
        //queries user(rider) request
        
        let query = PFQuery(className: "riderRequest")
        query.whereKey("username", equalTo: requestUsername)
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                
                if let objects = objects as [PFObject]? {
                    
                    for object in objects {
                        
                        let query = PFQuery(className: "riderRequest")
                        query.getObjectInBackgroundWithId(object.objectId!, block: { (object, error) -> Void in
                            
                            if error != nil {
                                print(error)
                            }
                            
                            else if let object = object {
                                
                                object["driverResponded"] = PFUser.currentUser()!.username!
                                
                                object.saveInBackground()
                                
                                //gets request location 
                                
                                let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                
                                CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) -> Void in
                                    
                                    if error != nil {
                                        print(error)
                                    }
                                    
                                    else {
                                        
                                        if placemarks!.count > 0 {
                                            
                                            //converts CLPlacemark to MKPlacemark to use on map
                                            
                                            let placeMark = placemarks![0] as CLPlacemark
                                            
                                            let mkPlaceMark = MKPlacemark(placemark: placeMark)
                                            
                                            let mapItem = MKMapItem(placemark: mkPlaceMark)
                                            mapItem.name = self.requestUsername
                                            
                                            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                            mapItem.openInMapsWithLaunchOptions(launchOptions)
                                        }
                                        
                                        else {
                                            print("Geocoder is having some issues")
                                        }
                                    }
                                })
                            }
                        })
                    }
                }
            }
            
            else {
                print(error)
            }
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
