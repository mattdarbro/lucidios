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
    
    init(task: MultiDayTask) {
        _viewModel = State(initialValue: ResearchTaskDetailViewModel(task: task))
    }
    
    @State private var showingCheckInForm = false
    
    var body: some View {
        List {
            Section("Overview") {
                Text(viewModel.task.title)
                    .font(.headline)
                if let description = viewModel.task.description {
                    Text(description)
                        .font(.body)
                }
                if let topic = viewModel.task.topicCategory {
                    Text("Topic: \(topic.capitalized)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Status: \(viewModel.task.status.capitalized)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Check-Ins") {
                if viewModel.isLoading && viewModel.checkIns.isEmpty {
                    ProgressView()
                } else if viewModel.checkIns.isEmpty {
                    Text("No check-ins yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.checkIns) { checkIn in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(checkIn.response)
                                .font(.body)
                                .lineLimit(3)
                            HStack {
                                Text("Energy \(checkIn.selfReportedEnergy) • Mood \(checkIn.selfReportedMood) • Focus \(checkIn.selfReportedFocus)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(checkIn.createdAt, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            
            Section("Analysis") {
                if viewModel.isLoadingAnalysis {
                    ProgressView("Loading analysis...")
                } else if let analysis = viewModel.analysis {
                    if !analysis.morningInsights.isEmpty {
                        Text("Morning insights:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(analysis.morningInsights, id: \.self) { insight in
                            Text("• \(insight)")
                                .font(.caption2)
                        }
                    }
                    if !analysis.eveningInsights.isEmpty {
                        Text("Evening insights:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(analysis.eveningInsights, id: \.self) { insight in
                            Text("• \(insight)")
                                .font(.caption2)
                        }
                    }
                    if let optimal = analysis.optimalDecisionTime {
                        Text(optimal)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding(.top, 4)
                    }
                } else {
                    Text("No analysis yet. Generate one after a few check-ins.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Check-In") {
                    showingCheckInForm = true
                }
                Button("View Analysis") {
                    Task { await viewModel.loadAnalysis() }
                }
            }
        }
        .task {
            await viewModel.loadCheckIns()
        }
        .refreshable {
            await viewModel.loadCheckIns()
        }
        .onAppear {
            // Reload check-ins when view appears to ensure we have latest data
            Task {
                await viewModel.loadCheckIns()
            }
        }
        .sheet(isPresented: $showingCheckInForm) {
            TaskCheckInFormView(viewModel: viewModel)
        }
    }
}

struct TaskCheckInFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ResearchTaskDetailViewModel
    
    @State private var response: String = ""
    @State private var insightsText: String = ""
    @State private var energy: Double = 3
    @State private var mood: Double = 3
    @State private var focus: Double = 3
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    Text("How does this task feel for you right now?")
                        .font(.body)
                }
                
                Section("Your Response") {
                    TextEditor(text: $response)
                        .frame(minHeight: 120)
                }
                
                Section("Insights (optional)") {
                    TextField("Comma-separated insights", text: $insightsText)
                }
                
                Section("How are you feeling?") {
                    SliderRow(title: "Energy", value: $energy)
                    SliderRow(title: "Mood", value: $mood)
                    SliderRow(title: "Focus", value: $focus)
                }
                
                Section {
                    Button {
                        Task {
                            isSubmitting = true
                            let insights = insightsText
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            await viewModel.addCheckIn(
                                response: response,
                                energy: Int(energy),
                                mood: Int(mood),
                                focus: Int(focus),
                                insights: insights.isEmpty ? nil : insights
                            )
                            isSubmitting = false
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                Text("Submitting...")
                            }
                        } else {
                            Text("Submit Check-In")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("New Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


