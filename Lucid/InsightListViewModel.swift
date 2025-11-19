//
//  InsightListViewModel.swift
//  Lucid
//
//  Created by Claude on 11/18/25.
//

import Foundation

@Observable
class InsightListViewModel {
    var pendingInsights: [Insight] = []
    var confirmedInsights: [Insight] = []
    var isLoading = false
    var errorMessage: String?

    let userId: String
    private let api = LucidAPIClient.shared

    init(userId: String) {
        self.userId = userId
    }

    func loadPendingInsights() async {
        isLoading = true
        errorMessage = nil

        do {
            pendingInsights = try await api.getPendingInsights(userId: userId)
            print("✅ Loaded \(pendingInsights.count) pending insights for user \(userId)")
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load insights: \(error.localizedDescription)"
            print("❌ Failed to load pending insights: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load insights: \(error.localizedDescription)"
            print("❌ Failed to load pending insights: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func validateInsight(
        _ insight: Insight,
        action: String,
        refinementText: String? = nil,
        energyLevel: Int? = nil,
        mood: Int? = nil
    ) async {
        errorMessage = nil

        do {
            let timeOfDay = api.getCurrentTimeOfDay()
            let updatedInsight = try await api.validateInsight(
                insightId: insight.id,
                action: action,
                refinementText: refinementText,
                timeOfDay: timeOfDay,
                energyLevel: energyLevel,
                mood: mood
            )

            print("✅ Validated insight \(insight.id) with action: \(action)")

            // Remove from pending if accepted/rejected
            if action == "accepted" || action == "rejected" {
                pendingInsights.removeAll { $0.id == insight.id }
            }

            // Add to confirmed if accepted or refined
            if action == "accepted" || action == "refined" {
                if !confirmedInsights.contains(where: { $0.id == updatedInsight.id }) {
                    confirmedInsights.append(updatedInsight)
                }
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to validate insight: \(error.localizedDescription)"
            print("❌ Failed to validate insight: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to validate insight: \(error.localizedDescription)"
            print("❌ Failed to validate insight: \(error.localizedDescription)")
        }
    }

    func startDiscussion(for insight: Insight) async -> (Conversation, Insight)? {
        errorMessage = nil

        do {
            let result = try await api.startInsightDiscussion(insightId: insight.id)
            print("✅ Started discussion for insight \(insight.id)")
            return result
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to start discussion: \(error.localizedDescription)"
            print("❌ Failed to start discussion: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to start discussion: \(error.localizedDescription)"
            print("❌ Failed to start discussion: \(error.localizedDescription)")
        }

        return nil
    }
}
