//
//  LoginViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

class LoginViewController: UIViewController {
    
    var debug = true;
    
    let database = Firestore.firestore()
    
    private var eventDataModel: EventDataModel!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    
    var completionHandler: ((User?) -> Void)?


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRegisterView" {
            debug ? print("Showing register view") : ()
            let registerView = segue.destination as! RegisterViewController
            registerView.completionHandler = {(user: User?) in
                self.debug ? print("Registration View Closed") : ()
                if user != nil {
                    self.completionHandler?(user)
                }
                self.dismiss(animated: true, completion: nil)
            }

        }
    }
    
    @IBAction func loginPressed(_sender: UIButton) {
        if let email = email.text, !email.isEmpty,
           let password = password.text, !password.isEmpty {
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard self != nil else { return }
                let returnedUser = authResult?.user;
                self!.database.collection("users").document(returnedUser?.email ?? "no_email_found").getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        let name = data?["name"] as? String ?? "name_not_found"
                        let user : User = User(email: returnedUser?.email, name: name)
                        
                        
                        let eventsRef = self!.database.collection("events")
                        let query = eventsRef.whereField("email", isEqualTo: returnedUser?.email ?? "email_not_found")
                        
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
                                    let eventId = data["event-id"] as? String ?? "event_id_not_found"
                                    let event = Event(title: title, description: description, locationTitle: locationTitle, locationAddress: locationAddress, user: user, imageUrl: imageUrl, eventId: eventId)
                                    
                                    events.append(event)
                                }
                                
                                !events.isEmpty ? self?.eventDataModel.setHostedEvents(events: events) : ()
                                self?.completionHandler?(user);
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }
    
    @IBAction func cancelPressed(_sender: UIButton) {
        self.completionHandler?(nil)
    }
}
