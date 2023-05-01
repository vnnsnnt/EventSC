//
//  HostedEventsTableViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

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
        user = eventDataModel.getUser();
        if user == nil {
            debug ? print("Not logged in") : ()
            performSegue(withIdentifier: "showLoginView", sender: nil)
            
        } else {
            debug ? print("Logged in as \(user?.getName() ?? "name_not_found")") : ()
            debug ? print(eventDataModel.getHostedEvents().count) : ()
        }
        self.tableView.reloadData()
        
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
                                        "email": self.user?.getEmail() ?? "email_not_found",
                                        "name": self.user?.getName() ?? "name_not_found",
                                        "title": event.getTitle() ?? "title_not_found",
                                        "description": event.getDescription() ?? "description_not_found",
                                        "locationTitle": event.getLocationTitle() ?? "location_title_not_found",
                                        "locationAddress": event.getLocationAddress() ?? "location_address_not_found",
                                        "imageUrl": imageUrl,
                                        "event-id": UUID().uuidString
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
        cell.eventDateTime.text = "10:00 PM, Tuesday, Aug 2023"
        cell.eventLocation.text = "@ " + event.getLocationTitle()!
        let url = URL(string: event.getImageUrl() ?? "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=")
        cell.thumbnail.kf.setImage(with: url)
        return cell
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

}
