//
//  EventDataModel.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import Foundation

class EventDataModel: NSObject {
    static let sharedInstance = EventDataModel()
    private var publicEvents: [Event] = []
    private var savedEvents: [Event] = []
    private var hostedEvents: [Event] = []
    private var user: User?
    private var savedEventIds: [String] = []
    
    override init() {
        
        // load public events - by location
        
        
        // load saved events - by user
        
        
        // load hosted events - by user
    }
    
    func setUser(user: User?) -> Void {
        self.user = user;
    }
    
    func getUser() -> User? {
        return self.user
    }
    
    func getPublicEvents() -> [Event] {
        return self.publicEvents;
    }
    
    func getSavedEvents() -> [Event] {
        return self.savedEvents;
    }
    
    func getHostedEvents() -> [Event] {
        return self.hostedEvents;
    }
    
    func addHostedEvent(event: Event) {
        self.hostedEvents.append(event)
    }
    
    func setHostedEvents(events: [Event]) {
        self.hostedEvents = events
    }
    
    func setPublicEvents(events: [Event]) {
        self.publicEvents = events
    }
    
    func setSavedEvents(events: [Event]) {
        self.savedEvents = events
    }
    
    func removeHostedEvent(at: Int) -> Void{
        self.hostedEvents.remove(at: at)
    }
    
    func addSavedEventId(id: String) {
        self.savedEventIds.append(id);
    }
    
    func setSavedEventIds(eventIds: [String]) {
        self.savedEventIds = eventIds
    }
    
    func getSavedEventIds() -> [String] {
        return self.savedEventIds
    }
    
    func removeSavedEventId(id: String) {
        self.savedEventIds.removeAll {$0 == id}
    }
    
    func reset() -> Void {
        self.savedEventIds = []
        self.savedEvents = []
        self.hostedEvents = []
        self.user = nil
    }
}
