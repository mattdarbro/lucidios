//
//  ChatViewModel.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

@Observable
class ChatViewModel {
    var messages: [Message] = []
    var inputText = ""
    var isLoading = false
    var errorMessage: String?
    
    let userId: String
    let conversationId: String
    private let api = LucidAPIClient.shared
    private var messageCounter = 0
    
    init(userId: String, conversationId: String) {
        self.userId = userId
        self.conversationId = conversationId
    }
    
    func loadMessages() async {
        errorMessage = nil
        do {
            messages = try await api.getMessages(conversationId: conversationId)
            messageCounter = messages.count
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load messages: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
        }
    }
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // Ensure we have a plausible conversationId before sending/extracting
        guard UUID(uuidString: conversationId) != nil else {
            errorMessage = "Invalid conversation ID. Please restart the chat."
            return
        }
        
        let messageText = inputText
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.sendMessage(
                conversationId: conversationId,
                userId: userId,
                message: messageText
            )
            
            // Add messages to local array
            messages.append(response.userMessage)
            messages.append(response.assistantMessage)
            
            // Increment counter and check if we should extract facts
            messageCounter += 2
            if messageCounter % 10 == 0 {
                Task {
                    await extractFacts()
                }
            }
            
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to send message: \(error.localizedDescription)"
            inputText = messageText // Restore message on error
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            inputText = messageText // Restore message on error
        }
        
        isLoading = false
    }
    
    func extractFacts() async {
        // Guard against invalid or missing conversation IDs
        guard UUID(uuidString: conversationId) != nil else {
            print("❌ Skipping fact extraction: invalid conversationId \(conversationId)")
            return
        }
        
        do {
            let result = try await api.extractFacts(
                userId: userId,
                conversationId: conversationId,
                limit: 20
            )
            print("✅ Extracted \(result.count) facts from conversation")
        } catch {
            print("❌ Failed to extract facts: \(error.localizedDescription)")
        }
    }
    
    func generateSummary() async {
        do {
            let summary = try await api.generateSummary(
                conversationId: conversationId,
                userId: userId,
                messageCount: messages.count
            )
            print("✅ Generated summary: \(summary.conversationOverview ?? "No overview")")
        } catch {
            print("❌ Failed to generate summary: \(error.localizedDescription)")
        }
    }
}

