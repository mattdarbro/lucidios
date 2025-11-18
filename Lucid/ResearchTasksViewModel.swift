//
//  ResearchTasksViewModel.swift
//  Lucid
//
//  Created by Cursor on 11/16/25.
//

import Foundation

@Observable
class ResearchTasksViewModel {
    var tasks: [MultiDayTask] = []
    var isLoading = false
    var errorMessage: String?
    
    let userId: String
    private let api = LucidAPIClient.shared
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        do {
            let loadedTasks = try await api.getActiveMultiDayTasks(userId: userId)
            tasks = loadedTasks
            print("✅ Loaded \(loadedTasks.count) research tasks for user \(userId)")
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load research tasks: \(error.localizedDescription)"
            print("❌ Failed to load research tasks: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load research tasks: \(error.localizedDescription)"
            print("❌ Failed to load research tasks: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func createTask(
        title: String,
        description: String?,
        topicCategory: String?,
        checkInTimes: [String],
        durationDays: Int
    ) async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a title for your research task."
            return
        }
        guard !checkInTimes.isEmpty else {
            errorMessage = "Please choose at least one check-in time."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let task = try await api.createMultiDayTask(
                userId: userId,
                title: title,
                description: description,
                topicCategory: topicCategory,
                checkInTimes: checkInTimes,
                durationDays: durationDays
            )
            print("✅ Created task: \(task.id) - \(task.title)")
            
            // Add to local state immediately for instant UI update
            tasks.append(task)
            print("✅ Added task to local state, total count: \(tasks.count)")
            
            // Also refresh from backend to ensure we have the latest data
            // This handles any race conditions or ensures we get the full task data
            await loadTasks()
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to create research task: \(error.localizedDescription)"
            print("❌ Failed to create research task: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to create research task: \(error.localizedDescription)"
            print("❌ Failed to create research task: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func deleteTask(_ task: MultiDayTask) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await api.deleteMultiDayTask(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to delete research task: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to delete research task: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}


