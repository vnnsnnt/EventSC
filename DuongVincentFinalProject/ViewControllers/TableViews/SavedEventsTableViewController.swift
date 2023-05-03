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
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return eventDataModel.getSavedEvents().count
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLoginView" {
            let loginView = segue.destination as! LoginViewController
            loginView.completionHandler = {(user: User?) in
                if let user {
                    self.eventDataModel.setUser(user: user)
                    self.getSavedEvents()
                } else {
                    if let tabBarController = self.tabBarController {
                        tabBarController.selectedIndex = 0
                        self.debug ? print("Moved to public lists page since not authenticated") : ()
                    }
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        if segue.identifier == "showDetailsView" {
            // Get the destination view controller
            let destinationVC = segue.destination as! EventDetailsViewController
            destinationVC.hidesBottomBarWhenPushed = true

            // Pass the selected event to the destination view controller
            let selectedEvent = sender as! Event
            destinationVC.event = selectedEvent
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = eventDataModel.getSavedEvents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        cell.eventTitle.text = event.getTitle();
//        cell.eventDescription.text = event.getDescription()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a MM/dd/yy"
        let dateTimeString = dateFormatter.string(from: event.getDate() ?? Date())
        cell.eventDateTime.text = dateTimeString
        cell.eventLocation.text = "\(event.getLocationTitle() ?? "No Location Title"), \(event.getLocationAddress() ?? "No Location Address")"
//        cell.bookmarkIndicator.isHidden = (eventDataModel.getSavedEventIds().contains(event.getEventId() ?? "event_id_not_found")) ? false : true
        let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
        cell.thumbnail.kf.setImage(with: url)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEvent = eventDataModel.getSavedEvents()[indexPath.row]
        performSegue(withIdentifier: "showDetailsView", sender: selectedEvent)
    }
    
    override func tableView(_ tableView: UITableView,
               heightForRowAt indexPath: IndexPath) -> CGFloat {
       // Use the default size for all other rows.
        return 140
    }

    
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
                    }
                }
                completionHandler(true)
            }
            removeAction.backgroundColor = .systemRed
            removeAction.image = UIImage(systemName: "xmark")

            let configuration = UISwipeActionsConfiguration(actions: [removeAction])
            return configuration
    }
   
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
                                        let event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: User(email: email, name: name), imageUrl: imageUrl, eventId: eventId, date: date?.dateValue(), savedByCurrentUser: false)
                                        events.append(event)
                                    }
                                    self.eventDataModel.setSavedEvents(events: events)
                                    self.tableView.reloadData()
                                } else {
                                    print("Error getting documents: \(queryError!)")
                                }
                            }
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
