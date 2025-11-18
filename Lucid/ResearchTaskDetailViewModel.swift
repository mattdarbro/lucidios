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
    var checkIns: [TaskCheckIn] = []
    var analysis: TemporalAnalysis?
    
    var isLoading = false
    var isLoadingAnalysis = false
    var errorMessage: String?
    
    private let api = LucidAPIClient.shared
    
    init(task: MultiDayTask) {
        self.task = task
    }
    
    func loadCheckIns() async {
        isLoading = true
        errorMessage = nil
        do {
            let loadedCheckIns = try await api.getTaskCheckIns(taskId: task.id)
            checkIns = loadedCheckIns
            print("✅ Loaded \(loadedCheckIns.count) check-ins for task \(task.id)")
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load check-ins: \(error.localizedDescription)"
            print("❌ Failed to load check-ins: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load check-ins: \(error.localizedDescription)"
            print("❌ Failed to load check-ins: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func addCheckIn(
        response: String,
        energy: Int,
        mood: Int,
        focus: Int,
        insights: [String]?
    ) async {
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a response before submitting."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let timeOfDay = Self.currentTimeOfDay()
            // Backend requires question_asked and question_type
            let questionAsked = "How does this task feel for you right now?"
            let questionType = Self.questionTypeForTimeOfDay(timeOfDay)
            
            let checkIn = try await api.addTaskCheckIn(
                taskId: task.id,
                timeOfDay: timeOfDay,
                questionAsked: questionAsked,
                questionType: questionType,
                response: response,
                energy: energy,
                mood: mood,
                focus: focus,
                insights: insights
            )
            checkIns.append(checkIn)
            print("✅ Added check-in, total count: \(checkIns.count)")
            
            // Reload check-ins from backend to ensure we have the latest data
            await loadCheckIns()
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to submit check-in: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to submit check-in: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private static func questionTypeForTimeOfDay(_ timeOfDay: String) -> String {
        switch timeOfDay {
        case "morning":
            return "aspirational"
        case "afternoon":
            return "reflective"
        case "evening":
            return "reflective"
        case "late_night":
            return "reflective"
        default:
            return "reflective"
        }
    }
    
    func loadAnalysis() async {
        isLoadingAnalysis = true
        errorMessage = nil
        do {
            analysis = try await api.getTaskTemporalAnalysis(taskId: task.id)
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to load analysis: \(error.localizedDescription)"
        } catch {
            errorMessage = "Failed to load analysis: \(error.localizedDescription)"
        }
        isLoadingAnalysis = false
    }
    
    private static func currentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "late_night"
        }
    }
}


