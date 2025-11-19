//
//  ResearchTasksView.swift
//  Lucid
//
//  Created by Cursor on 11/16/25.
//

import SwiftUI

struct ResearchTasksView: View {
    @State private var viewModel: ResearchTasksViewModel
    @State private var showingNewTaskForm = false
    
    init(userId: String) {
        _viewModel = State(initialValue: ResearchTasksViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView("Loading research tasks...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Tasks",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Active Research Tasks",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Create multi-day research tasks in Lucid to see them here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.tasks) { task in
                            NavigationLink {
                                ResearchTaskDetailView(task: task)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.headline)
                                    
                                    if let topic = task.topicCategory {
                                        Text(topic.capitalized)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                    
                                    HStack {
                                        Text("\(daysRemaining(for: task)) days remaining")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        if let count = task.checkInsCount {
                                            Text("\(count) check-ins")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let task = viewModel.tasks[index]
                                Task {
                                    await viewModel.deleteTask(task)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Research Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewTaskForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.loadTasks()
            }
            .onAppear {
                // Reload tasks when view appears to ensure we have latest data
                Task {
                    await viewModel.loadTasks()
                }
            }
            .sheet(isPresented: $showingNewTaskForm) {
                ResearchTaskFormView(viewModel: viewModel)
            }
        }
    }
    
    private func daysRemaining(for task: MultiDayTask) -> Int {
        let endDate = Calendar.current.date(byAdding: .day, value: task.durationDays, to: task.createdAt) ?? task.createdAt
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(remaining, 0)
    }
}

struct ResearchTaskDetailView: View {
    @State private var viewModel: ResearchTaskDetailViewModel
    @State private var showingInsights = false

    init(task: MultiDayTask) {
        _viewModel = State(initialValue: ResearchTaskDetailViewModel(task: task))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Task Header
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.task.title)
                    .font(.headline)

                HStack {
                    if let topic = viewModel.task.topicCategory {
                        Text(topic.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    Text(viewModel.task.status.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !viewModel.insights.isEmpty {
                        Button(action: { showingInsights = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                Text("\(viewModel.insights.count)")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                        }
                    }
                }

                if let description = viewModel.task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Chat View for Check-Ins
            if let chatViewModel = viewModel.chatViewModel {
                ChatView(viewModel: chatViewModel)
            } else {
                ContentUnavailableView(
                    "No Conversation Available",
                    systemImage: "exclamationmark.bubble",
                    description: Text("This task doesn't have a conversation yet.")
                )
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            await viewModel.generateInsights()
                        }
                    } label: {
                        if viewModel.isGeneratingInsights {
                            Label("Generating...", systemImage: "sparkles")
                        } else {
                            Label("Generate Insights", systemImage: "sparkles")
                        }
                    }
                    .disabled(viewModel.isGeneratingInsights)

                    Button {
                        showingInsights = true
                    } label: {
                        Label("View Insights (\(viewModel.insights.count))", systemImage: "lightbulb")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadInsights()
        }
        .sheet(isPresented: $showingInsights) {
            TaskInsightsView(viewModel: viewModel)
        }
    }
}

// TaskInsightsView - Shows insights for a specific task
struct TaskInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ResearchTaskDetailViewModel

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.pendingInsights.isEmpty {
                    Section("Pending Review") {
                        ForEach(viewModel.pendingInsights) { insight in
                            InsightRow(insight: insight, taskId: viewModel.task.id)
                        }
                    }
                }

                if !viewModel.confirmedInsights.isEmpty {
                    Section("Confirmed") {
                        ForEach(viewModel.confirmedInsights) { insight in
                            InsightRow(insight: insight, taskId: viewModel.task.id)
                        }
                    }
                }

                if viewModel.insights.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "lightbulb",
                        description: Text("Check in a few times, then generate insights to see patterns.")
                    )
                }
            }
            .navigationTitle("Task Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadInsights()
            }
        }
    }
}

// Simple insight row for task-specific insights
struct InsightRow: View {
    let insight: Insight
    let taskId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patternIcon)
                    .foregroundStyle(patternColor)
                Spacer()
                confidenceBadge
            }

            Text(insight.insightText)
                .font(.body)

            HStack {
                statusBadge
                Spacer()
                Text(insight.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var patternIcon: String {
        switch insight.patternType {
        case "temporal_mood": return "clock.fill"
        case "language_change": return "text.bubble.fill"
        case "energy_correlation": return "bolt.fill"
        default: return "lightbulb.fill"
        }
    }

    private var patternColor: Color {
        switch insight.patternType {
        case "temporal_mood": return .blue
        case "language_change": return .purple
        case "energy_correlation": return .orange
        default: return .yellow
        }
    }

    private var confidenceBadge: some View {
        Text("\(Int(insight.confidence * 100))%")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.2))
            .foregroundStyle(.green)
            .clipShape(Capsule())
    }

    private var statusBadge: some View {
        Text(insight.status.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch insight.status {
        case "proposed": return .orange
        case "confirmed": return .green
        case "refined": return .blue
        case "rejected": return .red
        default: return .gray
        }
    }
}


