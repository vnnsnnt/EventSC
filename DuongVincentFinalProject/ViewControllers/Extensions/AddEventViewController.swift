//
//  AddEventViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import UIKit
import MapKit

class AddEventViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MKLocalSearchCompleterDelegate {
    
    @IBOutlet weak var eventTitle: UITextField!
    @IBOutlet weak var eventDescription: UITextField!
    @IBOutlet weak var eventLocation: UITextField!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var previewImage: UIImageView!
    
    var completionHandler: ((Event?) -> Void)?
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var selectedPlace: Place?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the search completer
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        
        // Set up the text field for autocompletion
        eventLocation.delegate = self
        eventLocation.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @IBAction func savePressed(_sender: UIButton) {
        if let title = eventTitle.text, !title.isEmpty,
           let description = eventDescription.text, !description.isEmpty,
           let location = eventLocation.text, !location.isEmpty {
            let event: Event = Event(title: title, description: description, locationTitle: selectedPlace?.title, locationAddress: selectedPlace?.address, image: previewImage.image)
            self.completionHandler?(event);
        }
    }
    
    @IBAction func uploadImageButtonPressed(_sender: UIButton) {
        let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            present(imagePicker, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[.originalImage] as? UIImage {
            previewImage.image = image
        }
    }
    
    @IBAction func cancelPressed(_sender: UIButton) {
        self.completionHandler?(nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addAddressView" {
            let addAddressView = segue.destination as! AddAddressViewController
            addAddressView.completionHandler = {(selectedPlace: Place?) in
                self.selectedPlace = selectedPlace
                self.eventLocation.text = "\(selectedPlace?.title ?? "No Address Title"), \(selectedPlace?.address ?? "No address provided")"
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

extension AddEventViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange() {
        if let searchQuery = eventLocation.text {
            searchCompleter.queryFragment = searchQuery
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow the user to type in the text field
        return true
    }
    
}

extension AddEventViewController {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Store the search results and update the UI
        searchResults = completer.results
        print(searchResults)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle the error
        print(error.localizedDescription)
    }
    
}
