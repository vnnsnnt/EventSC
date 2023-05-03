//
//  HostedEventsTableViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class HostedEventsTableViewController: UITableViewController {
    
    var debug = true
    
    private var eventDataModel: EventDataModel!;
    
    let database = Firestore.firestore()
    
    let storage = Storage.storage()


    private var user: User?

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
                    self.getHostedEvents()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return eventDataModel.getHostedEvents().count;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddEventView" {
            let addView = segue.destination as! AddEventViewController
            addView.completionHandler = {(event: Event?) in
                if let event, let imageData = event.getImage()!.jpegData(compressionQuality: 0.5) {
                    
                    let imageRef = self.storage.reference().child("images/\(UUID().uuidString).jpg")
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    imageRef.putData(imageData, metadata: metadata) { (metadata, insertDataError) in
                        if insertDataError == nil {
                            imageRef.downloadURL { (url, downloadUrlError) in
                                if downloadUrlError == nil, let imageUrl = url?.absoluteString {
                                    let eventRef = self.database.collection("events").document()
                                    let eventData : [String: Any] = [
                                        "email": self.eventDataModel.getUser()?.getEmail() ?? "email_not_found",
                                        "name": self.eventDataModel.getUser()?.getName() ?? "name_not_found",
                                        "title": event.getTitle() ?? "title_not_found",
                                        "description": event.getDescription() ?? "description_not_found",
                                        "locationTitle": event.getLocationTitle() ?? "location_title_not_found",
                                        "locationAddress": event.getLocationAddress() ?? "location_address_not_found",
                                        "imageUrl": imageUrl,
                                        "event-id": UUID().uuidString,
                                        "date": Timestamp(date: event.getDate() ?? Date())
                                    ]
                                    eventRef.setData(eventData)
                                    var newEvent = event
                                    newEvent.setImageUrl(url: imageUrl)
                                    self.eventDataModel.addHostedEvent(event: newEvent)
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                    
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        if segue.identifier == "showLoginView" {
            let loginView = segue.destination as! LoginViewController
            loginView.completionHandler = { [self](user: User?) in
                if let user {
                    self.eventDataModel.setUser(user: user)
                    self.getHostedEvents()
                } else {
                    if let tabBarController = self.tabBarController {
                        tabBarController.selectedIndex = 0
                    }
                }
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
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = eventDataModel.getHostedEvents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        cell.eventTitle.text = event.getTitle();
        cell.eventDescription.text = event.getDescription()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a MM/dd/yy"
        let dateTimeString = dateFormatter.string(from: event.getDate() ?? Date())
        cell.eventDateTime.text = dateTimeString
        cell.eventLocation.text = "@ " + event.getLocationTitle()!
        let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
        cell.thumbnail.kf.setImage(with: url)
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
               heightForRowAt indexPath: IndexPath) -> CGFloat {
       // Use the default size for all other rows.
        return 100
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEvent = eventDataModel.getHostedEvents()[indexPath.row]
        performSegue(withIdentifier: "showDetailsView", sender: selectedEvent)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let event = eventDataModel.getHostedEvents()[indexPath.row]
            // Delete the row from the data source
            let eventRef = database.collection("events").whereField("email", isEqualTo: event.getUser()!.getEmail()!).whereField("title", isEqualTo: event.getTitle()!)
            eventRef.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting event: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("Event not found")
                    return
                }
                for document in documents {
                    print("inside here")
                    document.reference.delete { (error) in
                        if let error = error {
                            print("Error deleting event: \(error.localizedDescription)")
                        } else {
                            print("Event deleted successfully")
                        }
                    }
                }
                self.eventDataModel.removeHostedEvent(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    @IBAction func editButtonPressed(_sender: UIBarButtonItem) {
        self.tableView.isEditing = !self.tableView.isEditing;
        tableView.reloadData()
        
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func getHostedEvents() -> Void {
        let user = eventDataModel.getUser()
        let eventsRef = database.collection("events")
        let query = eventsRef.whereField("email", isEqualTo: user?.getEmail() ?? "email_not_found")
        
        let savedEventsRef = self.database.collection("saved_events").document(user?.getEmail() ?? "email_not_found")
        savedEventsRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let savedEventIds = data?["saved_event_ids"] as? [String] {
                    self.eventDataModel.setSavedEventIds(eventIds: savedEventIds)
                }
            }
        }
        
        let likedEventsRef = self.database.collection("liked_events").document(user?.getEmail() ?? "email_not_found")
        likedEventsRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let likedEventIds = data?["liked_event_ids"] as? [String] {
                    self.eventDataModel.likedEventIds = likedEventIds
                }
            }
        }
        
        query.getDocuments() { (querySnapshot, queryError) in
            if queryError == nil {
                let documents = querySnapshot!.documents
                let savedEventsId = self.eventDataModel.getSavedEventIds()
                let likedEventsId = self.eventDataModel.likedEventIds
                var events = [Event]()
                
                for document in documents {
                    let data = document.data()
                    let title = data["title"] as? String ?? "title_not_found"
                    let description = data["description"] as? String ?? "description_not_found"
                    let locationTitle = data["locationTitle"] as? String ?? "location_title_not_found"
                    let locationAddress = data["locationAddress"] as? String ?? "location_address_not_found"
                    let imageUrl = data["imageUrl"] as? String ?? "image_not_found"
                    let eventId = data["event-id"] as? String ?? "event_id_not_found"
                    let date = data["date"] as? Timestamp
                    
                    let isSaved = (savedEventsId.contains(eventId)) ? true : false
                    let isLiked = (likedEventsId.contains(eventId)) ? true : false

                    
                    let event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: User(email: user?.getEmail(), name: user?.getName()), imageUrl: imageUrl, eventId: eventId, date: date?.dateValue(), savedByCurrentUser: isSaved, likedByCurrentUser: isLiked)
                    events.append(event)
                }
                !events.isEmpty ? self.eventDataModel.setHostedEvents(events: events) : ()
                self.tableView.reloadData()
            }
        }
    }
}
