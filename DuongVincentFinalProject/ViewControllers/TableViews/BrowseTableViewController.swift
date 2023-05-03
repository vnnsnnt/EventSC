//
//  BrowseTableViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit

import FirebaseFirestore
import FirebaseAuth

class BrowseTableViewController: UITableViewController {

    var debug = true
    
    let database = Firestore.firestore()

    @IBOutlet weak var signUpButton: UIBarButtonItem!;
    @IBOutlet weak var logoutButton: UIBarButtonItem!;
    
    
    private var user: User?
    private var eventDataModel: EventDataModel!
    
    var isLoggedIn = false {
        didSet {
            if isLoggedIn {
                signUpButton.isEnabled = false
                signUpButton.tintColor = UIColor.clear
                logoutButton.isEnabled = true
                logoutButton.tintColor = nil
            } else {
                signUpButton.isEnabled = true
                signUpButton.tintColor = nil
                logoutButton.isEnabled = false
                logoutButton.tintColor = UIColor.clear
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        
        refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)

    
    }
    
    @objc func refreshTable(_ sender: UIRefreshControl) {
        // Fetch the new data here...
        // For example, you could make a network request to get the latest data.

        // Once you have the new data, reload the table view and end the refreshing animation.
        self.getPublicEvents()
        tableView.reloadData()
        sender.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance;
        let user = Auth.auth().currentUser;
        if user == nil {
            isLoggedIn = false
            self.getPublicEvents()
        } else {
            database.collection("users").document(user?.email ?? "no_email_found").getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    let name = data?["name"] as? String ?? "name_not_found"
                    let loggedInUser : User = User(email: user?.email, name: name)
                    self.eventDataModel.setUser(user: loggedInUser)
                    self.getPublicEvents()
                }
            }
            self.isLoggedIn = true
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return eventDataModel.getPublicEvents().count;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLoginView" {
            debug ? print("Showing login view as modal") : ()
            let loginView = segue.destination as! LoginViewController
            loginView.completionHandler = {(user: User?) in
                self.debug ? print("Processed Authentication") : ()
                self.debug ? print("User is authenticated: \(user != nil)") : ()
                
                if let user {
                    self.user = user
                    self.eventDataModel.setUser(user: user)
                    self.isLoggedIn = true
                }
                self.getPublicEvents()
                self.tableView.reloadData()
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
    
    
    @IBAction func logoutPressed(_sender: UIButton) {
        do {
            try Auth.auth().signOut()
            user = nil;
            isLoggedIn = false
            eventDataModel.reset()
            self.tableView.reloadData()
            debug ? print("Logged out") : ()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    override func tableView(_ tableView: UITableView,
               heightForRowAt indexPath: IndexPath) -> CGFloat {
       // Use the default size for all other rows.
        return 300
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = eventDataModel.getPublicEvents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        
        cell.eventTitle.text = event.getTitle();
        cell.eventDescription.text = event.getDescription()
        cell.eventLocation.text = "@ " + event.getLocationTitle()!
        cell.bookmarkIndicator.isHidden = (eventDataModel.getSavedEventIds().contains(event.getEventId() ?? "event_id_not_found")) ? false : true
        let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
        cell.thumbnail.kf.setImage(with: url)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEvent = eventDataModel.getPublicEvents()[indexPath.row]
        performSegue(withIdentifier: "showDetailsView", sender: selectedEvent)
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let event = eventDataModel.getPublicEvents()[indexPath.row]
        
        let bookmarkAction = UIContextualAction(style: .normal, title: "") { (action, view, completionHandler) in
            self.eventDataModel.addSavedEventId(id: event.getEventId() ?? "event_id_not_found")
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
        bookmarkAction.backgroundColor = .systemGreen
        bookmarkAction.image = UIImage(systemName: "bookmark.fill")

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
        removeAction.image = UIImage(systemName: "bookmark")

            
        if eventDataModel.getSavedEventIds().contains(event.getEventId() ?? "event_id_not_found") {
            let configuration = UISwipeActionsConfiguration(actions: [removeAction])
            return configuration

        } else {
            let configuration = UISwipeActionsConfiguration(actions: [bookmarkAction])
            return configuration
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if eventDataModel.getUser() != nil {
            return true
        }
        return false
    }

    func getPublicEvents() -> Void {
        
        let user = eventDataModel.getUser()
        if user != nil {
            let savedEventsRef = self.database.collection("saved_events").document(user?.getEmail() ?? "email_not_found")
            savedEventsRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    if let savedEventIds = data?["saved_event_ids"] as? [String] {
                        self.eventDataModel.setSavedEventIds(eventIds: savedEventIds)
                    }
                    
                    let likedEventsRef = self.database.collection("liked_events").document(user?.getEmail() ?? "email_not_found")
                    likedEventsRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let data = document.data()
                            if let likedEventIds = data?["liked_event_ids"] as? [String] {
                                self.eventDataModel.likedEventIds = likedEventIds
                            }
                            
                            let reminderEventRefs = self.database.collection("reminded_events").document(self.eventDataModel.getUser()?.getEmail() ?? "email_not_found")

                            reminderEventRefs.getDocument { (document, error) in
                                if let error = error {
                                    print("Error retrieving document: \(error)")
                                } else if let document = document, document.exists {
                                    // Document exists and contains data
                                    let remindedEventsDict = document.data() as? [String: String] ?? [:]
                                    // Do something with the dictionary of reminded events (e.g. store it in your model)
                                    self.eventDataModel.remindedEventsDictionary = remindedEventsDict
                                    
                                    self.eventDataModel.remindedEventIds = Array(self.eventDataModel.remindedEventsDictionary.keys)
                                } else {
                                    print("Document does not exist")
                                }
                                self.queryPublicEvents()
                            }

                        }
                    }
                }
            }
        } else {
            self.queryPublicEvents()
        }

    }
    
    func queryPublicEvents() -> Void {
        let eventsRef = database.collection("events")
        let query = eventsRef
        query.getDocuments() { (querySnapshot, queryError) in
            if queryError == nil {
                let documents = querySnapshot!.documents
                var events = [Event]()
                
                let savedEventsId = self.eventDataModel.getSavedEventIds()
                let likedEventsId = self.eventDataModel.likedEventIds
                
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
                    
                    let isSaved = (savedEventsId.contains(eventId)) ? true : false
                    let isLiked = (likedEventsId.contains(eventId)) ? true : false
                    
                    let date = data["date"] as? Timestamp
                    let createDate = data["creation-date"] as? Timestamp
                    
                    var event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: User(email: email, name: name), imageUrl: imageUrl, eventId: eventId, date: date?.dateValue(), savedByCurrentUser: isSaved, likedByCurrentUser: isLiked)
                    
                    event.setCreationDate(date: createDate?.dateValue() ?? Date())
                    events.append(event)
                }
                
                let sortedEvents = events.sorted { (event1, event2) -> Bool in
                    return event1.getDate()?.compare(event2.getDate() ?? Date()) == .orderedDescending
                }
                
                !sortedEvents.isEmpty ? self.eventDataModel.setPublicEvents(events: sortedEvents) : ()
                self.tableView.reloadData()
            }
        }
    }

}

    
