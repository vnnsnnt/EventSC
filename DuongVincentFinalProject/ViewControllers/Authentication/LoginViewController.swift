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
                        self?.completionHandler?(user);
                    }
                }
            }
        }
    }
    
    @IBAction func cancelPressed(_sender: UIButton) {
        self.completionHandler?(nil)
    }
}
