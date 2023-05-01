//
//  MapViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/30/23.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place?
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        addressLabel.text = "\(place?.title ?? "No Location Title"), \(place?.address ?? "No Location Address")"
        let address = "\(place?.title ?? ""), \(place?.address ?? "")"
        if !address.isEmpty {
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                if let error = error {
                    print("Geocode failed with error: \(error.localizedDescription)")
                    return
                }

                if let placemark = placemarks?.first {
                    let location = placemark.location!
                    let coordinate = location.coordinate
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = address
                    self.mapView.addAnnotation(annotation)
                    self.mapView.showAnnotations([annotation], animated: true)
                }
            }
        }
    }
    
    @IBAction func returnPressed(_sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
