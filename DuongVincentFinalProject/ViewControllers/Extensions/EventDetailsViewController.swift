//
//  EventDetailsViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/29/23.
//

import UIKit
import Kingfisher

class EventDetailsViewController: UIViewController {
    
    var event: Event?
    
    var place: Place?
    
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventHoster: UILabel!
    @IBOutlet weak var eventDescription: UILabel!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var eventThumbnail: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var likeBUtton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let event {
            eventTitle.text = event.getTitle()
            eventHoster.text = "Presented by \(event.getUser()?.getName() ?? "Unknown Name")"
            eventDescription.text = event.getDescription()
            eventLocation.text = "\(event.getLocationTitle() ?? "No Location Title"), \(event.getLocationAddress() ?? "No Location Address Provided")"
            let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
            eventThumbnail.kf.setImage(with: url)
            likesLabel.text = (event.getLikeCount()! > 0 ? "liked by \(event.getLikeCount()!) people" : "Be the first to like this event")
        }
    }
    
    
    @IBAction func likeClicked(_sender: UIButton) {
        event?.incrementLikes()
        if let event {
            likesLabel.text = (event.getLikeCount()! > 0 ? "liked by \(event.getLikeCount()!) people" : "Be the first to like this event")
        }
        
    }
    
    @IBAction func mapPressed(_sender: UIButton) {
        if let event {
            place = Place(title: event.getLocationTitle(), address: event.getLocationAddress())
            performSegue(withIdentifier: "showMapView", sender: self)

        }
    }
    
    
    @IBAction func shareClicked(_sender: UIButton) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMapView" {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.place = place
            
        }
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
