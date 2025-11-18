//
//  CheckInsViewModel.swift
//  Lucid
//
//  Created by Cursor on 11/16/25.
//

import Foundation

@Observable
class CheckInsViewModel {
    var notifications: [ThoughtNotification] = []
    var isLoading = false
    var errorMessage: String?
    
    let userId: String
    private let api = LucidAPIClient.shared
    private unowned let appState: AppState
    
    init(userId: String, appState: AppState) {
        self.userId = userId
        self.appState = appState
    }
    
    func loadPending() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notifications = try await api.getPendingThoughtNotifications(userId: userId)
            appState.pendingNotificationsCount = notifications.count
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load check-ins: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load check-ins: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func respond(
        to notification: ThoughtNotification,
        responseText: String,
        energy: Int,
        mood: Int,
        focus: Int
    ) async {
        guard !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a response before submitting."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await api.respondToThoughtNotification(
                notificationId: notification.id,
                responseText: responseText,
                energy: energy,
                mood: mood,
                focus: focus
            )
            
            // Remove from local list and update badge count
            notifications.removeAll { $0.id == notification.id }
            appState.pendingNotificationsCount = notifications.count
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to submit response: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to submit response: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}


