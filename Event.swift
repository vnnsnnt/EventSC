//
//  Event.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import Foundation
import UIKit


struct Event {
    private var title : String?
    private var description: String?
    private var dateTime: String?
    private var location : String?
    private var user: User?
    private var imageUrl: String?
    private var image: UIImage?

    init(title: String? = nil, description: String? = nil, dateTime: String? = nil, location: String? = nil, user: User? = nil, imageUrl: String? = nil, image: UIImage? = nil) {
        self.title = title
        self.description = description
        self.dateTime = dateTime
        self.location = location
        self.user = user
        self.imageUrl = imageUrl
        self.image = image
    }
    
    
    func getTitle() -> String? {
        return self.title;
    }
    
    func getDateTime() -> String? {
        return self.dateTime
    }
    
    func getLocation() -> String? {
        return self.location
    }
    
    func getDescription() -> String? {
        return self.description
    }
    
    func getImage() -> UIImage? {
        return self.image
    }
    
    func getImageUrl() -> String? {
        return self.imageUrl
    }
    
    mutating func setTitle(title: String) -> Void {
        self.title = title;
    }
    
    mutating func setDateTime(dateTime: String) -> Void {
        self.dateTime = dateTime
    }
    
    mutating func setLocation(location: String) -> Void {
        self.location = location;
    }
    
    mutating func setImageUrl(url: String) -> Void {
        self.imageUrl = url
    }
}
