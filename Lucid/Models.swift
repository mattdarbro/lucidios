//
//  Models.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: String
    let externalId: String
    let name: String?
    let email: String?
    let timezone: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case name
        case email
        case timezone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversation
struct Conversation: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String?
    let timeOfDay: String?
    let userTimezone: String?
    let messageCount: Int?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case timeOfDay = "time_of_day"
        case userTimezone = "user_timezone"
        case messageCount = "message_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Message
struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String
    let role: MessageRole
    let content: String
    let createdAt: Date
    
    enum MessageRole: String, Codable {
        case user
        case assistant
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case createdAt = "created_at"
    }
}

// MARK: - Chat Request/Response
struct ChatRequest: Codable {
    let conversationId: String
    let userId: String
    let message: String
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userId = "user_id"
        case message
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatResponse: Codable {
    let userMessage: Message
    let assistantMessage: Message
    let response: String
    let conversationId: String
    
    enum CodingKeys: String, CodingKey {
        case userMessage = "user_message"
        case assistantMessage = "assistant_message"
        case response
        case conversationId = "conversation_id"
    }
}

// MARK: - Fact
struct Fact: Codable, Identifiable {
    let id: String
    let userId: String
    let content: String
    let category: String?
    let confidence: Double
    let evidenceCount: Int
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case category
        case confidence
        case evidenceCount = "evidence_count"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Autonomous Thought
struct AutonomousThought: Codable, Identifiable {
    let id: String
    let userId: String
    let content: String
    let thoughtType: String
    let circadianPhase: String?
    let importanceScore: Double?
    let isShared: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case thoughtType = "thought_type"
        case circadianPhase = "circadian_phase"
        case importanceScore = "importance_score"
        case isShared = "is_shared"
        case createdAt = "created_at"
    }
    
    var emoji: String {
        switch thoughtType {
        case "reflection": return "🌅"
        case "curiosity": return "🤔"
        case "consolidation": return "🌆"
        case "dream": return "🌙"
        case "insight": return "💡"
        default: return "💭"
        }
    }
}

// MARK: - Summary
struct Summary: Codable, Identifiable {
    let id: String
    let conversationId: String
    let userId: String
    let userPerspective: String?
    let modelPerspective: String?
    let conversationOverview: String?
    let messageCount: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case userPerspective = "user_perspective"
        case modelPerspective = "model_perspective"
        case conversationOverview = "conversation_overview"
        case messageCount = "message_count"
        case createdAt = "created_at"
    }
}

// MARK: - Fact Extraction Response
struct FactExtractionResponse: Codable {
    let extracted: [ExtractedFact]
    let created: [Fact]
    let count: Int
    let message: String
}

struct ExtractedFact: Codable {
    let content: String
    let category: String?
    let confidence: Double
}

// MARK: - Messages Response
struct MessagesResponse: Codable {
    let messages: [Message]
    let count: Int
    let limit: Int
    let offset: Int
}

// MARK: - Conversations Response
struct ConversationsResponse: Codable {
    let conversations: [Conversation]
    let count: Int
    let limit: Int
    let offset: Int
}

// MARK: - Facts Response
struct FactsResponse: Codable {
    let facts: [Fact]
    let count: Int?
    let limit: Int?
    let offset: Int?
}

// MARK: - Summaries Response
struct SummariesResponse: Codable {
    let summaries: [Summary]
    let count: Int
}

// MARK: - Thought Notification
struct ThoughtNotification: Codable, Identifiable {
    let id: String
    let question: String
    let preferredTimeOfDay: String?
    let priority: Double
    let status: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case preferredTimeOfDay = "preferred_time_of_day"
        case priority
        case status
        case createdAt = "created_at"
    }
}

// MARK: - Thought Notifications Response
struct ThoughtNotificationsResponse: Codable {
    let notifications: [ThoughtNotification]
}

// MARK: - Multi-Day Research Tasks
struct MultiDayTask: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let description: String?
    let topicCategory: String?
    let checkInTimes: [String]
    let durationDays: Int
    let status: String
    let createdAt: Date
    let updatedAt: Date?
    let checkInsCount: Int?
    let targetCompletionDate: Date?
    let completedAt: Date?
    let finalSynthesis: String?
    let synthesisCreatedAt: Date?
    
    struct TaskMetadata: Codable {
        let durationDays: Int?
        let checkInTimes: [String]?
        
        enum CodingKeys: String, CodingKey {
            case durationDays = "duration_days"
            case checkInTimes = "check_in_times"
        }
        
        init(durationDays: Int?, checkInTimes: [String]?) {
            self.durationDays = durationDays
            self.checkInTimes = checkInTimes
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            durationDays = try container.decodeIfPresent(Int.self, forKey: .durationDays)
            checkInTimes = try container.decodeIfPresent([String].self, forKey: .checkInTimes)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case topicCategory = "topic_category"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case checkInsCount = "check_ins_count"
        case checkIns = "check_ins"
        case targetCompletionDate = "target_completion_date"
        case completedAt = "completed_at"
        case finalSynthesis = "final_synthesis"
        case synthesisCreatedAt = "synthesis_created_at"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        topicCategory = try container.decodeIfPresent(String.self, forKey: .topicCategory)
        status = try container.decode(String.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        targetCompletionDate = try container.decodeIfPresent(Date.self, forKey: .targetCompletionDate)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        finalSynthesis = try container.decodeIfPresent(String.self, forKey: .finalSynthesis)
        synthesisCreatedAt = try container.decodeIfPresent(Date.self, forKey: .synthesisCreatedAt)
        
        // Try to get check_ins_count from check_ins array length if not directly provided
        if let checkIns = try? container.decodeIfPresent([TaskCheckIn].self, forKey: .checkIns) {
            checkInsCount = checkIns.count
        } else {
            checkInsCount = try container.decodeIfPresent(Int.self, forKey: .checkInsCount)
        }
        
        // Extract check_in_times and duration_days from metadata
        var extractedCheckInTimes: [String] = []
        var extractedDurationDays: Int = 5
        
        if container.contains(.metadata) {
            do {
                let metadata = try container.decode(TaskMetadata.self, forKey: .metadata)
                extractedCheckInTimes = metadata.checkInTimes ?? []
                extractedDurationDays = metadata.durationDays ?? 5
            } catch {
                // If metadata exists but can't be decoded, use defaults
                print("⚠️ Warning: Could not decode metadata: \(error)")
            }
        }
        
        checkInTimes = extractedCheckInTimes
        durationDays = extractedDurationDays
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(topicCategory, forKey: .topicCategory)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(targetCompletionDate, forKey: .targetCompletionDate)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(finalSynthesis, forKey: .finalSynthesis)
        try container.encodeIfPresent(synthesisCreatedAt, forKey: .synthesisCreatedAt)
        try container.encodeIfPresent(checkInsCount, forKey: .checkInsCount)
        
        // Encode metadata structure
        let metadata = TaskMetadata(durationDays: durationDays, checkInTimes: checkInTimes)
        try container.encode(metadata, forKey: .metadata)
    }
}

struct TaskCheckIn: Codable, Identifiable {
    let id: String
    let taskId: String
    let timeOfDay: String
    let questionAsked: String?
    let questionType: String?
    let response: String
    let selfReportedEnergy: Int
    let selfReportedMood: Int
    let selfReportedFocus: Int
    let insights: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case timeOfDay = "time_of_day"
        case questionAsked = "question_asked"
        case questionType = "question_type"
        case response
        case selfReportedEnergy = "self_reported_energy"
        case selfReportedMood = "self_reported_mood"
        case selfReportedFocus = "self_reported_focus"
        case insights
        case createdAt = "created_at"
    }
}

struct MultiDayTasksResponse: Codable {
    let tasks: [MultiDayTask]
}

struct TaskCheckInsResponse: Codable {
    let checkIns: [TaskCheckIn]
    
    enum CodingKeys: String, CodingKey {
        case checkIns = "check_ins"
    }
}

// Response wrapper for adding a check-in
struct AddTaskCheckInResponse: Codable {
    let task: TaskWithCheckIns
    let message: String
    
    struct TaskWithCheckIns: Codable {
        let checkIns: [CheckInResponse]
        
        enum CodingKeys: String, CodingKey {
            case checkIns = "check_ins"
        }
    }
    
    struct CheckInResponse: Codable {
        let response: String
        let timeOfDay: String
        let questionAsked: String?
        let questionType: String?
        let selfReportedEnergy: Int
        let selfReportedMood: Int
        let selfReportedFocus: Int
        let insights: [String]?
        let completedAt: Date
        let checkInNumber: Int?
        
        enum CodingKeys: String, CodingKey {
            case response
            case timeOfDay = "time_of_day"
            case questionAsked = "question_asked"
            case questionType = "question_type"
            case selfReportedEnergy = "self_reported_energy"
            case selfReportedMood = "self_reported_mood"
            case selfReportedFocus = "self_reported_focus"
            case insights
            case completedAt = "completed_at"
            case checkInNumber = "check_in_number"
        }
    }
}

struct TemporalAnalysis: Codable {
    let morningInsights: [String]
    let eveningInsights: [String]
    let optimalDecisionTime: String?
    
    enum CodingKeys: String, CodingKey {
        case morningInsights = "morning_insights"
        case eveningInsights = "evening_insights"
        case optimalDecisionTime = "optimal_decision_time"
    }
}

