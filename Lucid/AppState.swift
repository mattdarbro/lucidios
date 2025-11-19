//
//  AppState.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation
import UIKit

@Observable
class AppState {
    var currentUser: User?
    var currentConversation: Conversation?
    var isLoading = false
    var errorMessage: String?
    var pendingNotificationsCount: Int = 0
    
    // Persisted view models
    var chatViewModel: ChatViewModel?
    var profileViewModel: ProfileViewModel?
    
    private let api = LucidAPIClient.shared
    private let defaults = UserDefaultsManager.shared
    private var notificationsTimer: Timer?
    
    func initialize() async {
        Task {
            await initializeInternal()
        }
    }
    
    private func initializeInternal() async {
        isLoading = true
        
        do {
            // Try to load existing user first
            if let savedUserId = defaults.userId {
                do {
                    currentUser = try await api.getUser(id: savedUserId)
                } catch {
                    // User might not exist anymore, create new one
                    currentUser = nil
                }
            }
            
            // If no user exists, create one
            if currentUser == nil {
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                currentUser = try await api.createUser(
                    externalId: deviceId,
                    name: UIDevice.current.name,
                    timezone: TimeZone.current.identifier
                )
                
                // Save user ID
                if let userId = currentUser?.id {
                    defaults.userId = userId
                }
            }
            
            guard let userId = currentUser?.id else {
                errorMessage = "Failed to get user ID"
                isLoading = false
                return
            }
            
            // Try to load existing conversation
            if let savedConversationId = defaults.currentConversationId {
                do {
                    currentConversation = try await api.getConversation(id: savedConversationId)
                } catch {
                    // Conversation might not exist anymore, create new one
                    currentConversation = nil
                }
            }
            
            // If no conversation exists, create a new one
            if currentConversation == nil {
                currentConversation = try await api.createConversation(
                    userId: userId,
                    title: "New Chat",
                    timeOfDay: currentTimeOfDay()
                )
                
                // Save conversation ID
                if let conversationId = currentConversation?.id {
                    defaults.currentConversationId = conversationId
                }
            }
            
            // Initialize view models once user and conversation are ready
            if let conversation = currentConversation {
                chatViewModel = ChatViewModel(userId: userId, conversationId: conversation.id)
                profileViewModel = ProfileViewModel(userId: userId)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Initialization failed: \(error.localizedDescription)"
        } catch {
            errorMessage = "Initialization failed: \(error.localizedDescription)"
        }
        
        isLoading = false
        
        // Refresh thought notifications after initialization
        await refreshPendingNotifications()
        startNotificationsTimer()
    }
    
    func switchToConversation(_ conversation: Conversation) {
        currentConversation = conversation
        defaults.currentConversationId = conversation.id

        if let userId = currentUser?.id {
            chatViewModel = ChatViewModel(userId: userId, conversationId: conversation.id)
        }
    }
    
    func createNewConversation() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let newConversation = try await api.createConversation(
                userId: userId,
                title: "New Chat",
                timeOfDay: currentTimeOfDay()
            )
            
            switchToConversation(newConversation)
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
        }
    }
    
    func refreshPendingNotifications() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let notifications = try await api.getPendingThoughtNotifications(userId: userId)
            pendingNotificationsCount = notifications.count
        } catch let error as APIError {
            print("❌ Failed to refresh thought notifications: \(error.localizedDescription)")
        } catch {
            print("❌ Failed to refresh thought notifications: \(error.localizedDescription)")
        }
    }
    
    private func startNotificationsTimer() {
        notificationsTimer?.invalidate()
        notificationsTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshPendingNotifications()
            }
        }
    }
    
    deinit {
        notificationsTimer?.invalidate()
    }
    
    private func currentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}

