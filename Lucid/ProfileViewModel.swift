//
//  ProfileViewModel.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

@Observable
class ProfileViewModel {
    var facts: [Fact] = []
    var isLoading = false
    var errorMessage: String?
    
    let userId: String
    private let api = LucidAPIClient.shared
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadFacts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            facts = try await api.getFacts(userId: userId)
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load facts: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load facts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleFactActive(_ fact: Fact) async {
        do {
            let updated = try await api.updateFact(id: fact.id, isActive: !fact.isActive)
            if let index = facts.firstIndex(where: { $0.id == fact.id }) {
                facts[index] = updated
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to update fact: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to update fact: \(error.localizedDescription)"
        }
    }
    
    var groupedFacts: [String: [Fact]] {
        Dictionary(grouping: facts) { fact in
            fact.category?.capitalized ?? "Other"
        }
    }
}

