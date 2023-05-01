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
    private var locationTitle : String?
    private var locationAddress: String?
    private var place: Place?
    private var user: User?
    private var imageUrl: String?
    private var image: UIImage?
    private var createDate: Date?
    private var likeCount = 0
    private var eventId: String?

    init(title: String? = nil, description: String? = nil, dateTime: String? = nil, locationTitle: String? = nil, locationAddress: String? = nil, place: Place? = nil, user: User? = nil, imageUrl: String? = nil, image: UIImage? = nil, createDate: Date? = nil, likeCount: Int = 0, eventId: String? = nil) {
        self.title = title
        self.description = description
        self.dateTime = dateTime
        self.locationTitle = locationTitle
        self.locationAddress = locationAddress
        self.place = place
        self.user = user
        self.imageUrl = imageUrl
        self.image = image
        self.createDate = createDate
        self.likeCount = likeCount
        self.eventId = eventId
    }
    
    
    func getTitle() -> String? {
        return self.title;
    }
    
    func getDateTime() -> String? {
        return self.dateTime
    }
    
    func getLocationTitle() -> String? {
        return self.locationTitle
    }
    
    func getDescription() -> String? {
        return self.description
    }
    
    func getImage() -> UIImage? {
        return self.image
    }
    
    func getUser() -> User? {
        return self.user
    }
    
    func getImageUrl() -> String? {
        return self.imageUrl
    }
    
    func getLikeCount() -> Int? {
        return self.likeCount
    }
    
    func getEventId() -> String? {
        return self.eventId
    }
    
    func getLocationAddress() -> String? {
        return self.locationAddress
    }
    
    mutating func setTitle(title: String) -> Void {
        self.title = title;
    }
    
    mutating func setDateTime(dateTime: String) -> Void {
        self.dateTime = dateTime
    }
    
    mutating func setLocationTitle(location: String) -> Void {
        self.locationTitle = location;
    }
    
    mutating func setImageUrl(url: String) -> Void {
        self.imageUrl = url
    }
    
    mutating func incrementLikes() {
        self.likeCount += 1
    }
}
