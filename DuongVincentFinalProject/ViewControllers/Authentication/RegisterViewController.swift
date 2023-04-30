//
//  RegisterViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {
    
    var debug = true;
    
    //Firebase initializers
    let database = Firestore.firestore()

    
    // Text field inputs for register page
    @IBOutlet weak var fullName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var initialPassword: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    
    //processing variables
    private var eventDataModel: EventDataModel!
    
    var completionHandler: ((User?) -> Void)?



    override func viewDidLoad() {
        super.viewDidLoad()
            
        // Do any additional setup after loading the view.

        debug ? print("Loading Register Page") : ()
        
        //allows for keyboard dismissal upon tapping anywhere else on the screen
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    // load in the singleton data model
    override func viewWillAppear(_ animated: Bool) {
        eventDataModel = EventDataModel.sharedInstance;
    }
    
    // Handles registration to the firestore database
    @IBAction func processRegistration(_sender: UIButton) {
        debug ? print("Registration Requested") : ()
        debug ? print("fullName: \(fullName.text ?? "empty_name"), email: \(email.text ?? "empty_email"), password: \(confirmPassword.text ?? "empty_password")") : ()
        
        if let name = fullName.text, !name.isEmpty,
           let email = email.text, !email.isEmpty, email.range(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .regularExpression) != nil,
           let password = initialPassword.text, !password.isEmpty, password.count >= 6, // Add password length check
           let confirmPassword = confirmPassword.text, !confirmPassword.isEmpty {
               if password == confirmPassword {
                   debug ? print("Input fields are valid, proceeding with registration.") : ()
                   Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                       guard let returnedUser = authResult?.user, error == nil else {
                           self.debug ? print(error!.localizedDescription) : ()
                           return
                       }
                       let user : User = User(email: returnedUser.email, name: name)
                       self.debug ? print("Successfully registered with email: \(user.getEmail()!)") : ()
                       let nameEmailData : [String: Any] = [
                            "email": email,
                            "name": name
                       ]
                                              
                       self.database.collection("users").document(email).setData(nameEmailData) { error in
                           if error != nil {
                               self.debug ? print(error!.localizedDescription) : ()
                           } else {
                               self.debug ? print("User email -> name pair saved successfully") : ()
                           }
                       }
                       self.eventDataModel.setUser(user: user)
                       
                       self.completionHandler?(user)

                   }
               } else {
                   debug ? print("Passwords do not match") : ()
               }
        } else {
            // One or more fields are empty or email format is invalid
            if let email = email.text, email.range(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .regularExpression) == nil {
                debug ? print("Invalid email format") : ()
            } else {
                debug ? print("One or more fields are empty or password length is less than 6") : ()
            }
        }

        
    }
    
    @IBAction func cancelPressed(_sender: UIButton) {
        completionHandler?(nil)
    }
    
    // Causes the view (or one of its embedded text fields) to resign the first responder status.
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
