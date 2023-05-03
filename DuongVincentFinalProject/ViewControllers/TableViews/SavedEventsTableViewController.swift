//
//  SavedEventsTableViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class SavedEventsTableViewController: UITableViewController {
    
    var debug = true
    
    let database = Firestore.firestore()
    
    
    private var user: User?
    
    private var eventDataModel: EventDataModel!;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance;
        let user = Auth.auth().currentUser;
        if user == nil {
            debug ? print("Not logged in") : ()
            performSegue(withIdentifier: "showLoginView", sender: nil)
        } else {
            // query firestore to get the users saved event ids
            database.collection("users").document(user?.email ?? "no_email_found").getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    let name = data?["name"] as? String ?? "name_not_found"
                    let loggedInUser : User = User(email: user?.email, name: name)
                    self.eventDataModel.setUser(user: loggedInUser)
                    self.getSavedEvents()
                }
            }
        }
    }

    
    //set the number of rows to display equal to the number of saved events the user has
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventDataModel.getSavedEvents().count
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // handles the login action completion
        if segue.identifier == "showLoginView" {
            let loginView = segue.destination as! LoginViewController
            loginView.completionHandler = {(user: User?) in
                if let user {
                    self.eventDataModel.setUser(user: user)
                    self.getSavedEvents()
                } else {
                    //redirects the user if they do not login
                    if let tabBarController = self.tabBarController {
                        tabBarController.selectedIndex = 0
                        self.debug ? print("Moved to public lists page since not authenticated") : ()
                    }
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        // Pass the selected event to the destination view controller
        if segue.identifier == "showDetailsView" {
            let destinationVC = segue.destination as! EventDetailsViewController
            destinationVC.hidesBottomBarWhenPushed = true

            let selectedEvent = sender as! Event
            destinationVC.event = selectedEvent
            
        }
    }
    
    // set the text data of the cell as well as whether or not the event has a reminder for it
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = eventDataModel.getSavedEvents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        cell.eventTitle.text = event.getTitle();
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a MM/dd/yy"
        let dateTimeString = dateFormatter.string(from: event.getDate() ?? Date())
        cell.eventDateTime.text = dateTimeString
        cell.eventLocation.text = "\(event.getLocationTitle() ?? "No Location Title"), \(event.getLocationAddress() ?? "No Location Address")"
        
        cell.notificationIndicator.isHidden = (eventDataModel.remindedEventIds.contains(event.getEventId() ?? "event_id_not_found")) ? false : true
    
        let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
        cell.thumbnail.kf.setImage(with: url)
        return cell
    }
    
    // this will handle the action to show the segue when the user clicks on event
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEvent = eventDataModel.getSavedEvents()[indexPath.row]
        performSegue(withIdentifier: "showDetailsView", sender: selectedEvent)
    }
    
    // Use the default size of 140 for all rows in saved events page
    override func tableView(_ tableView: UITableView,
               heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }

    
    // swipe actions for the table view to remove saved events
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let event = eventDataModel.getSavedEvents()[indexPath.row]
        let removeAction =  UIContextualAction(style: .normal, title: "") {
                (action, view, completionHandler) in
                self.eventDataModel.removeSavedEventId(id: event.getEventId() ?? "event_id_not_found")
                tableView.reloadRows(at: [indexPath], with: .right) // reload the cell to update the UI
                let savedEventsRef = self.database.collection("saved_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")
            
                savedEventsRef.setData ([
                    "saved_event_ids": self.eventDataModel.getSavedEventIds()
                ]) { err in
                    if let err = err {
                        print("Error adding saved event: \(err)")
                    } else {
                        print("Saved event added successfully")
                        self.getSavedEvents()
                    }
                }
                completionHandler(true)
            }
            removeAction.backgroundColor = .systemRed
            removeAction.image = UIImage(systemName: "xmark")

            let configuration = UISwipeActionsConfiguration(actions: [removeAction])
            return configuration
    }
   
    // query firestore to get the users saved events to populate the data model
    func getSavedEvents() -> Void {
        let user = eventDataModel.getUser()
        let savedEventsRef = self.database.collection("saved_events").document(user?.getEmail() ?? "email_not_found")
        savedEventsRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let savedEventIds = data?["saved_event_ids"] as? [String] {
                    self.eventDataModel.setSavedEventIds(eventIds: savedEventIds)
                    let eventsRef = self.database.collection("events")
                    var events = [Event]()
                    if !savedEventIds.isEmpty {
                        eventsRef.whereField("event-id", in: savedEventIds)
                            .getDocuments() { (querySnapshot, queryError) in
                                if queryError == nil {
                                    let documents = querySnapshot!.documents
                                    for document in documents {
                                        let data = document.data()
                                        let title = data["title"] as? String ?? "title_not_found"
                                        let description = data["description"] as? String ?? "description_not_found"
                                        let locationTitle = data["locationTitle"] as? String ?? "location_title_not_found"
                                        let locationAddress = data["locationAddress"] as? String ?? "location_address_not_found"
                                        let imageUrl = data["imageUrl"] as? String ?? "image_not_found"
                                        let email = data["email"] as? String ?? "email_not_found"
                                        let name = data["name"] as? String ?? "name_not_found"
                                        let eventId = data["event-id"] as? String ?? "event_id_not_found"
                                        let date = data["date"] as? Timestamp
                                        let createDate = data["creation-date"] as? Timestamp
                                        var event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: User(email: email, name: name), imageUrl: imageUrl, eventId: eventId, date: date?.dateValue(), savedByCurrentUser: false)
                                        event.setCreationDate(date: createDate?.dateValue() ?? Date())
                                        events.append(event)
                                    }
                                    
                                    let sortedEvents = events.sorted { (event1, event2) -> Bool in
                                        return event1.getDate()?.compare(event2.getDate() ?? Date()) == .orderedAscending
                                    }
                                    
                                    self.eventDataModel.setSavedEvents(events: sortedEvents)
                                    self.tableView.reloadData()
                                } else {
                                    print("Error getting documents: \(queryError!)")
                                }
                            }
                    } else {
                        self.eventDataModel.setSavedEvents(events: [])
                        self.tableView.reloadData()
                    }
                } else {
                    print("No saved event IDs found")
                }
            } else {
                print("Document does not exist")
            }
        }
        self.tableView.reloadData()
    }

}
