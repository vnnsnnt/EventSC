//
//  User.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/28/23.
//

import Foundation

struct User {
    private var email: String?
    private var name: String?
    
    init(email: String? = nil, name: String? = nil) {
        self.email = email
        self.name = name
    }
    
    func getEmail() -> String? {
        return self.email
    }
    
    func getName() -> String? {
        return self.name
    }
    
}
