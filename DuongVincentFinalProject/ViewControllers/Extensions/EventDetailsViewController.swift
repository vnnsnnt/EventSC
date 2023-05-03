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
    
    let apiKey = "4c7cc6efbc224207980221154233004"
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
    @IBOutlet weak var weatherConditionsLabel: UILabel!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    //images used
    let emptyBellImage = UIImage(systemName: "bell")?.withRenderingMode(.alwaysTemplate)
    let filledBellImage = UIImage(systemName: "bell.fill")?.withRenderingMode(.alwaysTemplate)
    let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
    let filledHeart = UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)
    let emptyBook = UIImage(systemName: "book")?.withRenderingMode(.alwaysTemplate)
    let filledBook = UIImage(systemName: "book.fill")?.withRenderingMode(.alwaysTemplate)
    
    private var eventDataModel: EventDataModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let emptyBellImage = UIImage(systemName: "bell")?.withRenderingMode(.alwaysTemplate)
        addReminderButton.image = emptyBellImage
        let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        likeBUtton.setImage(emptyHeart, for: .normal)


    }
    
    // will take the data passed in from the segue to display extra details of the event
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance
        if let event {
            let eventDataModel = EventDataModel.sharedInstance
            
            //check if the user already has set reminder for event
            if eventDataModel.remindedEventIds.contains(event.getEventId() ?? "event_id_not_found") {
                addReminderButton.image = filledBellImage
            } else {
                addReminderButton.image = emptyBellImage
            }
            
            // get the like count of the event
            self.getLikeCount()
            
            
            // check if the user has already liked the event
            if eventDataModel.likedEventIds.contains(event.getEventId() ?? "event_id_not_found") {
                likeBUtton.setImage(filledHeart, for: .normal)
            } else {
                likeBUtton.setImage(emptyHeart, for: .normal)
            }
            
            
            // check if the user has already saved the event
            if eventDataModel.getSavedEventIds().contains(event.getEventId() ?? "event_id_not_found") {
                bookmarkButton.setImage(filledBook, for: .normal)
            } else {
                bookmarkButton.setImage(emptyBook, for: .normal)
            }
            
            
            // set the labels and text for each of the outlets
            eventTitle.text = event.getTitle()
            eventHoster.text = "by \(event.getUser()?.getName() ?? "Unknown Name")"
            eventDescription.text = event.getDescription()
            eventLocation.text = "\(event.getLocationTitle() ?? "No Location Title"), \(event.getLocationAddress() ?? "No Location Address Provided")"
            let image_url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
            eventThumbnail.kf.setImage(with: image_url)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a MM/dd/yy"
            let dateTimeString = dateFormatter.string(from: event.getDate() ?? Date())
            dateTimeLabel.text = dateTimeString
            
            
            let location = "\(event.getLocationAddress() ?? "No Address Found")"
            let locationEncoded = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            //this date formatter is used format the date for the api call to weatherapi
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            let dateString = dateFormatter2.string(from: event.getDate() ?? Date())
           
            // Create the API request URL with the necessary parameters
            let urlString = "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(locationEncoded)&dt=\(dateString)"
            let url = URL(string: urlString)!
           
            // Send the API request and process the response
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error: \(error!)")
                    return
                }
               
               // Parse the response JSON to extract the forecasted temperature and condition
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    let forecast = json["forecast"] as? [String: Any]
                    guard let forecastday = forecast?["forecastday"] as? [[String: Any]], !forecastday.isEmpty else {
                        // Handle the case where forecastday is empty or not an array
                        DispatchQueue.main.async {
                            self.weatherConditionsLabel.text = "Unable to fetch weather data."
                        }
                        return
                    }
                    
                    // the data that we will display for the temperature and weather
                    let hour = forecastday[0]["hour"] as! [[String: Any]]
                    let tempF = hour[0]["temp_f"] as! Double
                    let condition = hour[0]["condition"] as! [String: Any]
                    let text = condition["text"] as! String
                    
                    // Update the UI on the main thread with the forecasted weather information
                    DispatchQueue.main.async {
                        self.weatherConditionsLabel.text = "Temperature: \(tempF)°F, Condition: \(text)"
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.weatherConditionsLabel.text = "Unable to fetch weather data."
                    }
                }
            }
            
            task.resume()

        }
    }
    
    
    // handle the processing for when the user clicks the like button
    @IBAction func likeClicked(_sender: UIButton) {
        let emptyHeart = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        let filledHeart = UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate)

        //checks if the user already has liked the event or not
        if(eventDataModel.likedEventIds.contains(event?.getEventId() ?? "event_id_not_found")) {
            eventDataModel.likedEventIds.removeAll {$0 == event?.getEventId()}
            _sender.setImage(emptyHeart, for: .normal)
        } else {
            eventDataModel.likedEventIds.append(event?.getEventId() ?? "event_id_not_found")
            _sender.setImage(filledHeart, for: .normal)
        }
        
        
        // saves the new status of the users liked events to firestore
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
        
        //refreshes the like count
        self.getLikeCount()
    }
    
    //handles the process to display the map segue
    @IBAction func mapPressed(_sender: UIButton) {
        if let event {
            place = Place(title: event.getLocationTitle(), address: event.getLocationAddress())
            performSegue(withIdentifier: "showMapView", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // segue that passes the location of the event to the map view controller to display
        if segue.identifier == "showMapView" {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.place = place
        }
    }
    
    // handles the event where the user clicks on the notification bell
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

    // this will create a reminder for the event on the users reminder app
    func createReminder(in eventStore: EKEventStore) {
        if self.eventDataModel.remindedEventIds.contains(self.event?.getEventId() ?? "event_id_not_found") {
            self.removeReminder(eventStore: eventStore, calendarItemIdentifier: self.eventDataModel.remindedEventsDictionary[self.event?.getEventId() ?? "event_id_not_found"] ?? "item_identifier_not_found")
                
        } else {
            let alertController = UIAlertController(title: "Create Reminder", message: "Are you sure you want to create a reminder for this event?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = self.event?.getTitle() ?? "New Event"
                reminder.calendar = eventStore.defaultCalendarForNewReminders()
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.event?.getDate() ?? Date())
                
                do {
                    try eventStore.save(reminder, commit: true)
                    print("Reminder added successfully.")
                    
                    let filledBellImage = UIImage(systemName: "bell.fill")?.withRenderingMode(.alwaysTemplate)
                    let eventDataModel = EventDataModel.sharedInstance;
                    eventDataModel.remindedEventIds.append(self.event?.getEventId() ?? "event_id_not_found")
                    eventDataModel.remindedEventsDictionary[self.event?.getEventId() ?? "event_id_not_found"] = reminder.calendarItemIdentifier
                    
                    let reminderEventRefs = self.database.collection("reminded_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
                    
                    reminderEventRefs.setData(self.eventDataModel.remindedEventsDictionary) { err in
                        if let err = err {
                            print("Error adding reminder: \(err)")
                        } else {
                            print("Reminder added successfuly")
                        }
                    }
                    self.addReminderButton.image = filledBellImage
                    
                } catch {
                    print("Reminder could not be added: \(error.localizedDescription)")
                }
            }))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    // this will remove the event from the user's reminders app
    func removeReminder(eventStore: EKEventStore, calendarItemIdentifier: String) {
        // Fetch the reminder with the given calendar item identifier
        let reminder = eventStore.calendarItem(withIdentifier: calendarItemIdentifier) as? EKReminder

        if let reminder = reminder {
            // Create an alert to confirm the user wants to remove the reminder
            let alertController = UIAlertController(title: "Remove Reminder", message: "Are you sure you want to remove this reminder?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                do {
                    // Remove the reminder from the event store
                    try eventStore.remove(reminder, commit: true)
                    self.eventDataModel.remindedEventIds.removeAll {$0 == self.event?.getEventId() ?? "event_id_not_found"}
                    print("Reminder removed successfully.")
                    self.addReminderButton.image = self.emptyBellImage
                    
                    self.eventDataModel.remindedEventsDictionary.removeValue(forKey: self.event?.getEventId() ?? "event_id_not_found")
                    
                    let reminderEventRefs = self.database.collection("reminded_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
                    
                    reminderEventRefs.setData(self.eventDataModel.remindedEventsDictionary) { err in
                        if let err = err {
                            print("Error adding reminder: \(err)")
                        } else {
                            print("Reminder added successfuly")
                        }
                    }
                    
                } catch {
                    print("Error removing reminder: \(error.localizedDescription)")
                }
            }))
            // Present the alert to the user
            present(alertController, animated: true, completion: nil)
        } else {
            
            self.eventDataModel.remindedEventsDictionary.removeValue(forKey: self.event?.getEventId() ?? "event_id_not_found")
            let reminderEventRefs = self.database.collection("reminded_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
            
            reminderEventRefs.setData(self.eventDataModel.remindedEventsDictionary) { err in
                if let err = err {
                    print("Error adding reminder: \(err)")
                } else {
                    print("Reminder added successfuly")
                }
            }
            self.addReminderButton.image = self.emptyBellImage

            print("Reminder with identifier \(calendarItemIdentifier) not found.")
        }
    }


    // this will save or unsave the event from the users saved events
    @IBAction func bookmarkButtonPressed(_sender: UIButton) {
        if eventDataModel.getSavedEventIds().contains(event?.getEventId() ?? "event_id_not_found") {
            eventDataModel.removeSavedEventId(id: event?.getEventId() ?? "event_id_not_found")
            print(eventDataModel.getSavedEventIds().contains(event?.getEventId() ?? "event_id_not_found"))
            bookmarkButton.setImage(emptyBook, for: .normal)
        } else {
            eventDataModel.addSavedEventId(id: event?.getEventId() ?? "event_id_not_found")
            bookmarkButton.setImage(filledBook, for: .normal)
        }
        
        let savedEventsRef = self.database.collection("saved_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
        
        savedEventsRef.setData ([
            "saved_event_ids": self.eventDataModel.getSavedEventIds()
        ]) { err in
            if let err = err {
                print("Error adding saved event: \(err)")
            } else {
                print("Saved event added successfully")
            }
        }
    }
    
    
    //this will increment all users who have liked the event and return the total count
    func getLikeCount() -> Void {
        let eventIdToCount = event?.getEventId() ?? "event_id_not_found"

        let likedEventRefs = database.collection("liked_events")
        likedEventRefs.whereField("liked_event_ids", arrayContains: eventIdToCount)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error retrieving liked events: \(error.localizedDescription)")
                } else {
                    var userCount = 0
                    for document in querySnapshot!.documents {
                        let likedEventIds = document.data()["liked_event_ids"] as! [String]
                        if likedEventIds.contains(eventIdToCount) {
                            userCount += 1
                        }
                    }
                    self.likesLabel.text = "liked by \(userCount) users"
                }
            }
    }
    
}
