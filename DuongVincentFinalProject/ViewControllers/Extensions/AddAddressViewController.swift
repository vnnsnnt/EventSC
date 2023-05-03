//
//  AddAddressViewController.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/30/23.
//

import UIKit
import MapKit

class AddAddressViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var searchResultsTableView: UITableView!

    let searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    var completionHandler: ((Place?) -> Void)?

    var selectedPlace: Place?

    override func viewDidLoad() {
        super.viewDidLoad()

        //assigns delegates
        addressTextField.delegate = self
        searchCompleter.delegate = self
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
    }

    // get every key input change and processes a new query for addresses
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldString = textField.text ?? ""
        let newString = (oldString as NSString).replacingCharacters(in: range, with: string)
        searchCompleter.queryFragment = newString
        selectedPlace = Place(title: newString)
        return true
    }

    // returns the number of addresses found as rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // draws the addresses out showing the title and address
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    // checks if the user has selected a specific address
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = searchResults[indexPath.row]
        addressTextField.text = selectedResult.title
        selectedPlace = Place(title: selectedResult.title, address: selectedResult.subtitle)
        
    }
    
    // returns back to the caller view controller with the address
    @IBAction func saveAddressPressed(_sender: UIButton) {
        self.completionHandler?(selectedPlace)
    }
    
    // returns back to the caller view controller without the address
    @IBAction func cancelAddressPressed(_sender: UIButton) {
        self.completionHandler?(nil)
    }
    
    

}

extension AddAddressViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error
    }

}
