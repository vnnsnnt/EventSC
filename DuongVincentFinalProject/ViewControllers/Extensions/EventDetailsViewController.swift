//
//  EventDetailsViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/29/23.
//

import UIKit
import Kingfisher
import EventKit
import FirebaseFirestore

class EventDetailsViewController: UIViewController {
    
    var event: Event?
    var place: Place?
    
    let database = Firestore.firestore()
    
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
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var addReminderButton: UIBarButtonItem!
    
    private var eventDataModel: EventDataModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let emptyBellImage = UIImage(systemName: "bell")?.withRenderingMode(.alwaysTemplate)
        addReminderButton.image = emptyBellImage
        let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        likeBUtton.setImage(emptyHeart, for: .normal)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance
        if let event {
            let emptyBellImage = UIImage(systemName: "bell")?.withRenderingMode(.alwaysTemplate)
            let filledBellImage = UIImage(systemName: "bell.fill")?.withRenderingMode(.alwaysTemplate)
            let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
            let filledHeart = UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)
            
            let eventDataModel = EventDataModel.sharedInstance
            if eventDataModel.remindedEventIds.contains(event.getEventId() ?? "event_id_not_found") {
                addReminderButton.image = filledBellImage
            } else {
                addReminderButton.image = emptyBellImage
            }

            if eventDataModel.likedEventIds.contains(event.getEventId() ?? "event_id_not_found") {
                self.likeBUtton.setImage(filledHeart, for: .normal)
            } else {
                self.likeBUtton.setImage(emptyHeart, for: .normal)
            }
            
            eventTitle.text = event.getTitle()
            eventHoster.text = "by \(event.getUser()?.getName() ?? "Unknown Name")"
            eventDescription.text = event.getDescription()
            eventLocation.text = "\(event.getLocationTitle() ?? "No Location Title"), \(event.getLocationAddress() ?? "No Location Address Provided")"
            let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
            eventThumbnail.kf.setImage(with: url)
            likesLabel.text = (event.getLikeCount()! > 0 ? "liked by \(event.getLikeCount()!) people" : "Be the first to like this event")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a MM/dd/yy"
            let dateTimeString = dateFormatter.string(from: event.getDate() ?? Date())
            dateTimeLabel.text = dateTimeString
        }
    }
    
    
    
    @IBAction func likeClicked(_sender: UIButton) {
        let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        let filledHeart = UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)

        if(eventDataModel.likedEventIds.contains(event?.getEventId() ?? "event_id_not_found")) {
            eventDataModel.likedEventIds.removeAll {$0 == event?.getEventId()}
            _sender.setImage(emptyHeart, for: .normal)
        } else {
            eventDataModel.likedEventIds.append(event?.getEventId() ?? "event_id_not_found")
            _sender.setImage(filledHeart, for: .normal)
        }
        
        let likedEventRefs = database.collection("liked_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
        
        likedEventRefs.setData([
            "liked_event_ids": eventDataModel.likedEventIds
        ]) { err in
            if let err = err {
                print("Error adding liked event: \(err)")
            } else {
                print("Liked event added successfully")
            }
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
    
    @IBAction func addReminderButtonPressed(_ sender: UIButton) {
        let eventStore = EKEventStore()
        
        // Check if the user has granted permission to access the EventKit
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .authorized:
            // Permission granted, continue with adding the reminder
            createReminder(in: eventStore)
        case .denied:
            // Permission denied, show an error message to the user
            print("Access to Reminders is denied.")
        case .notDetermined:
            // Request permission to access the EventKit
            eventStore.requestAccess(to: .reminder) { granted, error in
                if granted {
                    // Permission granted, continue with adding the reminder
                    self.createReminder(in: eventStore)
                } else {
                    // Permission denied, show an error message to the user
                    print("Access to Reminders is denied.")
                }
            }
        case .restricted:
            // The app is not authorized to access the EventKit
            print("Access to Reminders is restricted.")
        @unknown default:
            fatalError()
        }
    }

    func createReminder(in eventStore: EKEventStore) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = event?.getTitle() ?? "New Event"
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event?.getDate() ?? Date())
        
        do {
            try eventStore.save(reminder, commit: true)
            print("Reminder added successfully.")
            let filledBellImage = UIImage(systemName: "bell.fill")?.withRenderingMode(.alwaysTemplate)
            let eventDataModel = EventDataModel.sharedInstance;
            eventDataModel.remindedEventIds.append(event?.getEventId() ?? "event_id_not_found")
            addReminderButton.image = filledBellImage
        } catch {
            print("Reminder could not be added: \(error.localizedDescription)")
        }
    }
    

}
