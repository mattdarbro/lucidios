//
//  ResearchTaskDetailViewModel.swift
//  Lucid
//
//  Created by Cursor on 11/16/25.
//

import Foundation

@Observable
class ResearchTaskDetailViewModel {
    let task: MultiDayTask
    var insights: [Insight] = []
    var chatViewModel: ChatViewModel?

    var isLoadingInsights = false
    var isGeneratingInsights = false
    var errorMessage: String?

    private let api = LucidAPIClient.shared

    init(task: MultiDayTask) {
        self.task = task

        // Create chat view model if task has a conversation
        if let conversationId = task.conversationId ?? task.primaryConversationId {
            self.chatViewModel = ChatViewModel(userId: task.userId, conversationId: conversationId)
        }
    }

    func loadInsights() async {
        isLoadingInsights = true
        errorMessage = nil
        do {
            insights = try await api.getTaskInsights(taskId: task.id)
            print("✅ Loaded \(insights.count) insights for task \(task.id)")
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load insights: \(error.localizedDescription)"
            print("❌ Failed to load insights: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load insights: \(error.localizedDescription)"
            print("❌ Failed to load insights: \(error.localizedDescription)")
        }
        isLoadingInsights = false
    }

    func generateInsights() async {
        isGeneratingInsights = true
        errorMessage = nil

        do {
            let newInsights = try await api.generateInsights(taskId: task.id)
            insights = newInsights
            print("✅ Generated \(newInsights.count) insights for task \(task.id)")
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to generate insights: \(error.localizedDescription)"
            print("❌ Failed to generate insights: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to generate insights: \(error.localizedDescription)"
            print("❌ Failed to generate insights: \(error.localizedDescription)")
        }

        isGeneratingInsights = false
    }

    var pendingInsights: [Insight] {
        insights.filter { $0.status == "proposed" }
    }

    var confirmedInsights: [Insight] {
        insights.filter { $0.status == "confirmed" || $0.status == "refined" }
    }

    var hasConversation: Bool {
        task.conversationId != nil || task.primaryConversationId != nil
    }
}
