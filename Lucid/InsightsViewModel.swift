//
//  InsightsViewModel.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

@Observable
class InsightsViewModel {
    var thoughts: [AutonomousThought] = []
    var summaries: [Summary] = []
    var isLoading = false
    var isGeneratingSummary = false
    var errorMessage: String?
    
    let userId: String
    let conversationId: String
    private let api = LucidAPIClient.shared
    
    init(userId: String, conversationId: String) {
        self.userId = userId
        self.conversationId = conversationId
    }
    
    func loadThoughts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            thoughts = try await api.getAllThoughts(userId: userId, limit: 50)
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load insights: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load insights: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadSummaries() async {
        // Summaries are per-conversation; require a valid UUID-style ID
        guard UUID(uuidString: conversationId) != nil else {
            print("❌ Skipping loadSummaries: invalid conversationId \(conversationId)")
            return
        }
        
        do {
            summaries = try await api.getSummaries(conversationId: conversationId)
        } catch let error as APIError {
            // 404 is already handled in the client as empty array, but keep a friendly message otherwise
            errorMessage = error.errorDescription ?? "Failed to load summaries: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load summaries: \(error.localizedDescription)"
        }
    }
    
    func generateSummary() async {
        // Require valid conversation ID for summary generation
        guard UUID(uuidString: conversationId) != nil else {
            errorMessage = "Invalid conversation ID. Please start a new chat."
            return
        }
        
        isGeneratingSummary = true
        errorMessage = nil
        
        do {
            _ = try await api.generateSummary(
                conversationId: conversationId,
                userId: userId,
                messageCount: max(thoughts.count, 20) // use at least 20 messages if available
            )
            // Reload summaries after generation
            await loadSummaries()
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to generate summary: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to generate summary: \(error.localizedDescription)"
        }
        
        isGeneratingSummary = false
    }
    
    var groupedThoughts: [String: [AutonomousThought]] {
        Dictionary(grouping: thoughts) { thought in
            thought.circadianPhase?.capitalized ?? "Other"
        }
    }
}

