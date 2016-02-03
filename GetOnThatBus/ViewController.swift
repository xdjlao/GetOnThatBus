//
//  ViewController.swift
//  GetOnThatBus
//
//  Created by Jerry on 2/2/16.
//  Copyright © 2016 Jerry Lao. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var routeDict: NSDictionary = NSDictionary()
    var currentRoute: NSDictionary = NSDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let urlString = "https://s3.amazonaws.com/mmios8week/bus.json"
        let url = NSURL(string: urlString)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url!) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            do {
                self.routeDict = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let stopArray = self.routeDict.objectForKey("row") as! [NSDictionary]
                    var maxLong:Double?
                    var minLong:Double?
                    var maxLat:Double?
                    var minLat:Double?
                    
                    for stop:NSDictionary in stopArray {
                        let checkLong = (stop.objectForKey("location")!.objectForKey("longitude") as! NSString).doubleValue
                        let checkLat = (stop.objectForKey("location")!.objectForKey("latitude") as! NSString).doubleValue
                        if maxLong == nil || checkLong > maxLong {
                            if checkLong < 0 {
                                maxLong = checkLong
                            }
                        }
                        if minLong == nil || checkLong < minLong {
                            if checkLong < 0 {
                                minLong = checkLong
                            }
                        }
                        if maxLat == nil || checkLat > maxLat {
                            if checkLat > 0 {
                                maxLat = checkLat
                            }
                        }
                        if minLat == nil || checkLat < minLat {
                            if checkLat > 0 {
                                minLat = checkLat
                            }
                        }
                        
                        self.dropPinForLocation(stop)
                    }
                    
                    let midLong = (maxLong! + minLong!)/2.0
                    let midLat = (maxLat! + minLat!)/2.0
                    let latA = CLLocation(latitude: maxLat!, longitude: minLong!)
                    let latB = CLLocation(latitude: minLat!, longitude: minLong!)
                    let latDistance = latA.distanceFromLocation(latB) * 1.2
                    let longA = CLLocation(latitude: minLat!, longitude: maxLong!)
                    let longB = CLLocation(latitude: minLat!, longitude: minLong!)
                    let longDistance = longA.distanceFromLocation(longB) * 1.2
                    
                    self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: midLat, longitude: midLong), latDistance, longDistance), animated: true)
                })
                
            } catch let error as NSError {
                print("error"+error.localizedDescription)
            }
        }
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dropPinForLocation(stopDictionary:NSDictionary) {
        let routeAnnotation:RouteAnnotation = RouteAnnotation()
        let latitude = (stopDictionary.objectForKey("location")?.objectForKey("latitude") as! NSString).doubleValue
        let longitude = (stopDictionary.objectForKey("location")?.objectForKey("longitude") as! NSString).doubleValue
        routeAnnotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        routeAnnotation.title = stopDictionary.objectForKey("routes") as? String
        routeAnnotation.routes = stopDictionary
        
        self.mapView.addAnnotation(routeAnnotation)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let interModalDict = (annotation as! RouteAnnotation).routes
        if let interModalObj = interModalDict!.objectForKey("inter_modal") {
            let interModal = interModalObj as! String
            if interModal == "Metra" {
                let pin = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin.image = UIImage(named: "metra")
                pin.canShowCallout = true
                pin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                
                return pin
            } else if interModal == "Pace" {
                let pin = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin.image = UIImage(named: "pace")
                pin.canShowCallout = true
                pin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                
                return pin
            } else {
                let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin.canShowCallout = true
                pin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                
                return pin
            }
        } else {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            pin.canShowCallout = true
            pin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            
            return pin
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.currentRoute = (view.annotation as! RouteAnnotation).routes!
        self.performSegueWithIdentifier("RouteDetail", sender: control)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! RouteDetailViewController
        destination.route = self.currentRoute
        destination.navigationItem.title = self.currentRoute.objectForKey("routes") as? String
    }
}

