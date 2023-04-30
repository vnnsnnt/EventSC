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
                        
                        query.getDocuments() { (querySnapshot, error) in
                            if let error = error {
                                print("Error getting events: \(error.localizedDescription)")
                                return
                            }
                            
                            print("We are here")

                            let documents = querySnapshot!.documents
                            
                            var events = [Event]()
                            
                            for document in documents {
                                
                                print("Found a document")
                                
                                let data = document.data()
                                let title = data["title"] as? String ?? "title_not_found"
                                let description = data["description"] as? String ?? "description_not_found"
                                let location = data["location"] as? String ?? "location_not_found"
                                let imageUrl = data["imageUrl"] as? String ?? "image_not_found"
                                
                                print("image found as \(imageUrl)")
                                
                                let event = Event(title: title, description: description, location: location, imageUrl: imageUrl)
                                
                                events.append(event)
                            }
                            
                            if !events.isEmpty {
                                print("found some events")
                                self?.eventDataModel.setHostedEvents(events: events)
                                print("there are \(self?.eventDataModel.getHostedEvents().count ?? 0) events")
                            }
                            self?.completionHandler?(user);
                        }
                    }
                }
 
            }
        } else {
            debug ? print("Email or passowrd field is empty") : ()
        }
    }
    
    @IBAction func cancelPressed(_sender: UIButton) {
        self.completionHandler?(nil)
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
