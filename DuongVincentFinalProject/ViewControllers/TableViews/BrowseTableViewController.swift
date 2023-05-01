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
        
        debug ? print("Loading Browse Page") : ()
        
        eventDataModel = EventDataModel.sharedInstance
        
        let eventsRef = database.collection("events")
        let query = eventsRef
        query.getDocuments() { (querySnapshot, queryError) in
            if queryError == nil {
                let documents = querySnapshot!.documents
                var events = [Event]()
                
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
                    let event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: User(email: email, name: name), imageUrl: imageUrl, eventId: eventId)
                    events.append(event)
                }
                
                !events.isEmpty ? self.eventDataModel.setPublicEvents(events: events) : ()
            }
        }
        
        isLoggedIn = false
        self.tableView.reloadData()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance
        if eventDataModel.getUser() != nil {
            isLoggedIn = true
        }
        self.tableView.reloadData()
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
    
    
    @IBAction func logoutPressed(_sender: UIButton) {
        do {
            try Auth.auth().signOut()
            user = nil;
            isLoggedIn = false
            eventDataModel.setUser(user: nil)
            debug ? print("Logged out") : ()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = eventDataModel.getPublicEvents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        cell.eventTitle.text = event.getTitle();
        cell.eventDescription.text = event.getDescription()
        cell.eventDateTime.text = "10:00 PM, Tuesday, Aug 2023"
        cell.eventLocation.text = "@ " + event.getLocationTitle()!
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
        
        let bookmarkAction = UIContextualAction(style: .normal, title: "Save Event") { (action, view, completionHandler) in
            // Perform edit action here
            completionHandler(true)
        }
        bookmarkAction.backgroundColor = .systemGreen
        let removeAction =  UIContextualAction(style: .normal, title: "Unsave") {
            (action, view, completionHandler) in
            completionHandler(true)
        }
        removeAction.backgroundColor = .systemRed
        
//        let configuration = UISwipeActionsConfiguration(actions: [bookmarkAction])
        let configuration = UISwipeActionsConfiguration(actions: [removeAction])
        return configuration
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
