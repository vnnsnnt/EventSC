//
//  MapViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/30/23.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var place: Place?
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeDistanceLabel: UILabel!
    

    let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
        
    }
    
    
    // get the address passed in from segue and process the address and displays it
    override func viewWillAppear(_ animated: Bool) {
        addressLabel.text = "\(place?.title ?? "No Location Title"), \(place?.address ?? "No Location Address")"
        let address = "\(place?.title ?? ""), \(place?.address ?? "")"
        if !address.isEmpty {
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                if let error = error {
                    print("Geocode failed with error: \(error.localizedDescription)")
                    return
                }
                
                // gets the location and creates a route for it
                if let location = placemarks?.first?.location {
                    let coordinate = location.coordinate
                      let annotation = MKPointAnnotation()
                      annotation.coordinate = coordinate
                      annotation.title = address
                      self.mapView.addAnnotation(annotation)
                      self.mapView.showAnnotations([annotation], animated: true)
                    self.mapThis(destinationCoordinate: location.coordinate)
                    
                }
            }
        }
    }
    
    //cancel segue
    @IBAction func returnPressed(_sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // draws the map kit with the overlay of the route and markers
    func mapThis(destinationCoordinate: CLLocationCoordinate2D) {
        let sourceCoordinate = (locationManager.location?.coordinate)!
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let destinationRequest = MKDirections.Request()
        destinationRequest.source = sourceItem
        destinationRequest.destination = destinationItem
        destinationRequest.transportType = .automobile
        destinationRequest.requestsAlternateRoutes = true
        
        //requests a route from apple map sdk
        let directions = MKDirections(request: destinationRequest)
        directions.calculate { (response, error) in
            guard let response = response else {
                if error != nil {
                    print("Something went wrong")
                }
                return
            }
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            let distanceInMiles = route.distance.magnitude / 1000.0 * 0.621371
            var timeString: String

            
            // show the route timing and distance
            if route.expectedTravelTime.magnitude >= 60 {
              let hours = Int(route.expectedTravelTime.magnitude / 3600)
              let minutes = Int((route.expectedTravelTime.magnitude / 60).truncatingRemainder(dividingBy: 60))
              timeString = String(format: "Time: %d hr %02d mins", hours, minutes)
            } else {
              timeString = String(format: "Time: %d mins",
                                  Int(route.expectedTravelTime.magnitude / 60))
            }

            let distanceString = String(format: "Distance: %.2f miles", distanceInMiles)
            self.timeDistanceLabel.text = "\(distanceString), \(timeString)"
        }
        
    }
    
    // change the theme of the map render likes
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .systemBlue
        return render
    }
    

}
