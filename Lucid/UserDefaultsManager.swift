//
//  UserDefaultsManager.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userIdKey = "lucid_user_id"
    private let currentConversationKey = "lucid_current_conversation_id"
    
    private init() {}
    
    var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }
    
    var currentConversationId: String? {
        get { UserDefaults.standard.string(forKey: currentConversationKey) }
        set { UserDefaults.standard.set(newValue, forKey: currentConversationKey) }
    }
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: currentConversationKey)
    }
}

