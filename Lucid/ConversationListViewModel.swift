//
//  ConversationListViewModel.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

@Observable
class ConversationListViewModel {
    var conversations: [Conversation] = []
    var isLoading = false
    var errorMessage: String?
    
    let userId: String
    private let api = LucidAPIClient.shared
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await api.getConversations(userId: userId)
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load conversations: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await api.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to delete conversation: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    func updateConversationTitle(_ conversation: Conversation, title: String) async {
        do {
            let updated = try await api.updateConversationTitle(id: conversation.id, title: title)
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = updated
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to update conversation: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to update conversation: \(error.localizedDescription)"
        }
    }
}

