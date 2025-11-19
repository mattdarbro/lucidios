//
//  LucidAPIClient.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL. Please check your API configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .unauthorized:
            return "Unauthorized. Please check your authentication."
        }
    }
}

@Observable
class LucidAPIClient {
    static let shared = LucidAPIClient()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Generic Request
    private func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        let fullURL = "\(APIConfig.baseURL)\(endpoint)"
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.invalidURL
        }
        
        print("🌐 \(method) \(fullURL)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        for (key, value) in APIConfig.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Request body: \(bodyString)")
            }
        }
        
        var responseData: Data?
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            print("📥 Response: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Server error \(httpResponse.statusCode): \(errorMessage)")
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ Response data: \(responseString.prefix(200))")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            if let data = responseData, let responseString = String(data: data, encoding: .utf8) {
                print("❌ Full response data: \(responseString)")
            }
            print("❌ Decoding error details: \(error)")
            if case .keyNotFound(let key, let context) = error {
                print("   Missing key: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            } else if case .typeMismatch(let type, let context) = error {
                print("   Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            } else if case .valueNotFound(let type, let context) = error {
                print("   Value not found: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            }
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URLError code: \(urlError.code.rawValue)")
                print("   URLError description: \(urlError.localizedDescription)")
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - User Operations
    func createUser(externalId: String, name: String? = nil, timezone: String = "UTC") async throws -> User {
        struct CreateUserRequest: Codable {
            let externalId: String
            let name: String?
            let timezone: String
            
            enum CodingKeys: String, CodingKey {
                case externalId = "external_id"
                case name
                case timezone
            }
        }
        
        return try await request(
            "/users",
            method: "POST",
            body: CreateUserRequest(externalId: externalId, name: name, timezone: timezone)
        )
    }
    
    func getUser(id: String) async throws -> User {
        return try await request("/users/\(id)")
    }
    
    // MARK: - Conversation Operations
    func createConversation(userId: String, title: String? = nil, timeOfDay: String? = nil) async throws -> Conversation {
        struct CreateConversationRequest: Codable {
            let userId: String
            let title: String?
            let userTimezone: String?
            let timeOfDay: String?
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
                case userTimezone = "user_timezone"
                case timeOfDay = "time_of_day"
            }
        }
        
        return try await request(
            "/conversations",
            method: "POST",
            body: CreateConversationRequest(
                userId: userId,
                title: title,
                userTimezone: TimeZone.current.identifier,
                timeOfDay: timeOfDay
            )
        )
    }
    
    func getConversations(userId: String, limit: Int = 50, offset: Int = 0) async throws -> [Conversation] {
        do {
            let response: ConversationsResponse = try await request("/conversations/user/\(userId)?limit=\(limit)&offset=\(offset)")
            return response.conversations
        } catch let error as APIError {
            // If user has no conversations yet, backend may return 404
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no conversations yet, returning empty array")
                return []
            }
            throw error
        }
    }
    
    func getConversation(id: String) async throws -> Conversation {
        return try await request("/conversations/\(id)")
    }
    
    func updateConversationTitle(id: String, title: String) async throws -> Conversation {
        struct UpdateConversationRequest: Codable {
            let title: String
        }
        
        return try await request(
            "/conversations/\(id)",
            method: "PATCH",
            body: UpdateConversationRequest(title: title)
        )
    }
    
    func deleteConversation(id: String) async throws {
        let _: EmptyResponse = try await request("/conversations/\(id)", method: "DELETE")
    }
    
    func getMessages(conversationId: String, limit: Int = 100, offset: Int = 0) async throws -> [Message] {
        do {
            let response: MessagesResponse = try await request("/conversations/\(conversationId)/messages?limit=\(limit)&offset=\(offset)")
            return response.messages
        } catch let error as APIError {
            // If conversation has no messages yet, backend may return 404
            // Treat this as an empty message list
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ Conversation has no messages yet, returning empty array")
                return []
            }
            throw error
        }
    }
    
    // Helper for empty responses
    private struct EmptyResponse: Codable {}
    
    // MARK: - Chat Operations
    func sendMessage(
        conversationId: String,
        userId: String,
        message: String,
        temperature: Double? = nil
    ) async throws -> ChatResponse {
        let request = ChatRequest(
            conversationId: conversationId,
            userId: userId,
            message: message,
            temperature: temperature,
            maxTokens: nil
        )
        
        return try await self.request("/chat", method: "POST", body: request)
    }
    
    // MARK: - Facts Operations
    func extractFacts(userId: String, conversationId: String, limit: Int = 20) async throws -> FactExtractionResponse {
        struct ExtractFactsRequest: Codable {
            let userId: String
            let conversationId: String
            let limit: Int
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case conversationId = "conversation_id"
                case limit
            }
        }
        
        return try await request(
            "/facts/extract",
            method: "POST",
            body: ExtractFactsRequest(userId: userId, conversationId: conversationId, limit: limit)
        )
    }
    
    func getFacts(userId: String, limit: Int = 50, offset: Int = 0, isActive: Bool = true) async throws -> [Fact] {
        do {
            let response: FactsResponse = try await request("/users/\(userId)/facts?limit=\(limit)&offset=\(offset)&is_active=\(isActive)")
            return response.facts
        } catch let error as APIError {
            // If user has no facts yet, backend may return 404
            // Treat this as an empty facts list
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no facts yet, returning empty array")
                return []
            }
            throw error
        }
    }
    
    func updateFact(id: String, isActive: Bool) async throws -> Fact {
        struct UpdateFactRequest: Codable {
            let isActive: Bool
            
            enum CodingKeys: String, CodingKey {
                case isActive = "is_active"
            }
        }
        
        return try await request(
            "/facts/\(id)",
            method: "PATCH",
            body: UpdateFactRequest(isActive: isActive)
        )
    }
    
    // MARK: - Autonomous Thoughts
    func getAllThoughts(userId: String, limit: Int = 50) async throws -> [AutonomousThought] {
        do {
            return try await request("/autonomous-thoughts?user_id=\(userId)&limit=\(limit)")
        } catch let error as APIError {
            // If user has no thoughts yet, backend may return 404
            // Treat this as an empty thoughts list
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no autonomous thoughts yet, returning empty array")
                return []
            }
            throw error
        }
    }
    
    // MARK: - Summaries
    func generateSummary(conversationId: String, userId: String, messageCount: Int = 20) async throws -> Summary {
        struct GenerateSummaryRequest: Codable {
            let conversationId: String
            let userId: String
            let messageCount: Int
            
            enum CodingKeys: String, CodingKey {
                case conversationId = "conversation_id"
                case userId = "user_id"
                case messageCount = "message_count"
            }
        }
        
        return try await request(
            "/summaries/generate",
            method: "POST",
            body: GenerateSummaryRequest(conversationId: conversationId, userId: userId, messageCount: messageCount)
        )
    }
    
    func getSummaries(conversationId: String) async throws -> [Summary] {
        do {
            let response: SummariesResponse = try await request("/conversations/\(conversationId)/summaries")
            return response.summaries
        } catch let error as APIError {
            // If conversation has no summaries yet, backend may return 404
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ Conversation has no summaries yet, returning empty array")
                return []
            }
            throw error
        }
    }
    
    // MARK: - Thought Notifications
    func getPendingThoughtNotifications(userId: String) async throws -> [ThoughtNotification] {
        do {
            let response: ThoughtNotificationsResponse = try await request("/users/\(userId)/thought-notifications/pending")
            return response.notifications
        } catch let error as APIError {
            // If user has no pending notifications yet, backend may return 404
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no pending thought notifications, returning empty array")
                return []
            }
            throw error
        }
    }
    
    func respondToThoughtNotification(
        notificationId: String,
        responseText: String,
        energy: Int,
        mood: Int,
        focus: Int
    ) async throws {
        struct RespondBody: Codable {
            let responseText: String
            let selfReportedEnergy: Int
            let selfReportedMood: Int
            let selfReportedFocus: Int
            
            enum CodingKeys: String, CodingKey {
                case responseText = "response_text"
                case selfReportedEnergy = "self_reported_energy"
                case selfReportedMood = "self_reported_mood"
                case selfReportedFocus = "self_reported_focus"
            }
        }
        
        let _: EmptyResponse = try await request(
            "/thought-notifications/\(notificationId)/respond",
            method: "POST",
            body: RespondBody(
                responseText: responseText,
                selfReportedEnergy: energy,
                selfReportedMood: mood,
                selfReportedFocus: focus
            )
        )
    }
    
    // MARK: - Multi-Day Tasks
    func createMultiDayTask(
        userId: String,
        title: String,
        description: String?,
        topicCategory: String?,
        checkInTimes: [String],
        durationDays: Int
    ) async throws -> MultiDayTask {
        struct Body: Codable {
            let userId: String
            let title: String
            let description: String?
            let topicCategory: String?
            let checkInTimes: [String]
            let durationDays: Int
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
                case description
                case topicCategory = "topic_category"
                case checkInTimes = "check_in_times"
                case durationDays = "duration_days"
            }
        }
        
        return try await request(
            "/multi-day-tasks",
            method: "POST",
            body: Body(
                userId: userId,
                title: title,
                description: description,
                topicCategory: topicCategory,
                checkInTimes: checkInTimes,
                durationDays: durationDays
            )
        )
    }
    
    func getActiveMultiDayTasks(userId: String) async throws -> [MultiDayTask] {
        do {
            let response: MultiDayTasksResponse = try await request("/users/\(userId)/multi-day-tasks?status=active")
            return response.tasks
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no active multi-day tasks, returning empty array")
                return []
            }
            throw error
        }
    }
    
    func addTaskCheckIn(
        taskId: String,
        timeOfDay: String,
        questionAsked: String?,
        questionType: String?,
        response: String,
        energy: Int,
        mood: Int,
        focus: Int,
        insights: [String]?
    ) async throws -> TaskCheckIn {
        struct Body: Codable {
            let timeOfDay: String
            let questionAsked: String?
            let questionType: String?
            let response: String
            let selfReportedEnergy: Int
            let selfReportedMood: Int
            let selfReportedFocus: Int
            let insights: [String]?
            
            enum CodingKeys: String, CodingKey {
                case timeOfDay = "time_of_day"
                case questionAsked = "question_asked"
                case questionType = "question_type"
                case response
                case selfReportedEnergy = "self_reported_energy"
                case selfReportedMood = "self_reported_mood"
                case selfReportedFocus = "self_reported_focus"
                case insights
            }
        }
        
        // Backend returns nested response with task and check_ins array
        let apiResponse: AddTaskCheckInResponse = try await request(
            "/multi-day-tasks/\(taskId)/check-ins",
            method: "POST",
            body: Body(
                timeOfDay: timeOfDay,
                questionAsked: questionAsked,
                questionType: questionType,
                response: response,
                selfReportedEnergy: energy,
                selfReportedMood: mood,
                selfReportedFocus: focus,
                insights: insights
            )
        )
        
        // Extract the first check-in from the response and convert to TaskCheckIn
        guard let checkInResponse = apiResponse.task.checkIns.first else {
            throw APIError.decodingError(NSError(domain: "No check-in in response", code: -1))
        }
        
        // Convert the response check-in to TaskCheckIn format
        // Use check_in_number as id if available, otherwise generate one
        let id = checkInResponse.checkInNumber.map { "\(taskId)-\($0)" } ?? UUID().uuidString
        
        return TaskCheckIn(
            id: id,
            taskId: taskId,
            timeOfDay: checkInResponse.timeOfDay,
            questionAsked: checkInResponse.questionAsked,
            questionType: checkInResponse.questionType,
            response: checkInResponse.response,
            selfReportedEnergy: checkInResponse.selfReportedEnergy,
            selfReportedMood: checkInResponse.selfReportedMood,
            selfReportedFocus: checkInResponse.selfReportedFocus,
            insights: checkInResponse.insights,
            createdAt: checkInResponse.completedAt
        )
    }
    
    func getTaskCheckIns(taskId: String) async throws -> [TaskCheckIn] {
        // Try the dedicated check-ins endpoint first
        do {
            let response: TaskCheckInsResponse = try await request("/multi-day-tasks/\(taskId)/check-ins")
            print("✅ Got check-ins from dedicated endpoint: \(response.checkIns.count)")
            return response.checkIns
        } catch let error as APIError {
            // If 404, the endpoint might not exist - try getting check-ins from the task response
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ Check-ins endpoint returned 404, trying to extract from task response...")
                // Get the raw task response and extract check-ins manually
                return try await getTaskCheckInsFromTask(taskId: taskId)
            }
            throw error
        }
    }
    
    private func getTaskCheckInsFromTask(taskId: String) async throws -> [TaskCheckIn] {
        // Get the raw JSON response to extract check-ins
        let fullURL = "\(APIConfig.baseURL)/multi-day-tasks/\(taskId)"
        guard let url = URL(string: fullURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in APIConfig.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("ℹ️ Could not get task, returning empty check-ins")
            return []
        }
        
        // Parse the JSON to extract check_ins array
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let checkInsArray = json["check_ins"] as? [[String: Any]] {
            // Convert the check-ins array to TaskCheckIn objects
            var checkIns: [TaskCheckIn] = []
            for (index, checkInDict) in checkInsArray.enumerated() {
                // Create an ID from check_in_number or index
                let id = (checkInDict["check_in_number"] as? Int).map { "\(taskId)-\($0)" } ?? "\(taskId)-\(index)"
                
                // Extract fields with proper type conversion
                guard let responseText = checkInDict["response"] as? String,
                      let timeOfDay = checkInDict["time_of_day"] as? String,
                      let energy = checkInDict["self_reported_energy"] as? Int,
                      let mood = checkInDict["self_reported_mood"] as? Int,
                      let focus = checkInDict["self_reported_focus"] as? Int else {
                    continue
                }
                
                // Parse date
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = (checkInDict["completed_at"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
                
                let checkIn = TaskCheckIn(
                    id: id,
                    taskId: taskId,
                    timeOfDay: timeOfDay,
                    questionAsked: checkInDict["question_asked"] as? String,
                    questionType: checkInDict["question_type"] as? String,
                    response: responseText,
                    selfReportedEnergy: energy,
                    selfReportedMood: mood,
                    selfReportedFocus: focus,
                    insights: checkInDict["insights"] as? [String],
                    createdAt: createdAt
                )
                checkIns.append(checkIn)
            }
            print("✅ Extracted \(checkIns.count) check-ins from task response")
            return checkIns
        }
        
        print("ℹ️ No check-ins found in task response")
        return []
    }
    
    func getMultiDayTask(id: String) async throws -> MultiDayTask {
        return try await request("/multi-day-tasks/\(id)")
    }
    
    func getTaskTemporalAnalysis(taskId: String) async throws -> TemporalAnalysis {
        return try await request("/multi-day-tasks/\(taskId)/temporal-analysis")
    }
    
    func deleteMultiDayTask(id: String) async throws {
        let _: EmptyResponse = try await request("/multi-day-tasks/\(id)", method: "DELETE")
    }

    // MARK: - Task Insights
    func generateInsights(taskId: String) async throws -> [Insight] {
        let response: InsightsResponse = try await request(
            "/tasks/\(taskId)/insights/generate",
            method: "POST"
        )
        return response.insights
    }

    func getTaskInsights(taskId: String) async throws -> [Insight] {
        do {
            let response: InsightsResponse = try await request("/tasks/\(taskId)/insights")
            return response.insights
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ Task has no insights yet, returning empty array")
                return []
            }
            throw error
        }
    }

    func getPendingInsights(userId: String) async throws -> [Insight] {
        do {
            let response: InsightsResponse = try await request("/users/\(userId)/insights/pending")
            return response.insights
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User has no pending insights, returning empty array")
                return []
            }
            throw error
        }
    }

    func validateInsight(
        insightId: String,
        action: String,
        refinementText: String? = nil,
        timeOfDay: String? = nil,
        energyLevel: Int? = nil,
        mood: Int? = nil
    ) async throws -> Insight {
        struct Body: Codable {
            let action: String
            let refinementText: String?
            let timeOfDay: String?
            let energyLevel: Int?
            let mood: Int?

            enum CodingKeys: String, CodingKey {
                case action
                case refinementText = "refinement_text"
                case timeOfDay = "time_of_day"
                case energyLevel = "energy_level"
                case mood
            }
        }

        let response: ValidateInsightResponse = try await request(
            "/insights/\(insightId)/validate",
            method: "POST",
            body: Body(
                action: action,
                refinementText: refinementText,
                timeOfDay: timeOfDay,
                energyLevel: energyLevel,
                mood: mood
            )
        )
        return response.insight
    }

    func startInsightDiscussion(insightId: String) async throws -> (conversation: Conversation, insight: Insight) {
        let response: StartInsightDiscussionResponse = try await request(
            "/insights/\(insightId)/start-discussion",
            method: "POST"
        )
        return (response.conversation, response.insight)
    }

    // MARK: - Helper Methods
    /// Get current time of day based on local hour
    func getCurrentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<21:
            return "evening"
        default:
            return "late_night"
        }
    }
}

