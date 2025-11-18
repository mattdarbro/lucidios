//
//  InsightsView.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import SwiftUI

struct InsightsView: View {
    @Bindable var viewModel: InsightsViewModel
    
    init(viewModel: InsightsViewModel) {
        self.viewModel = viewModel
    }
    
    // Convenience initializer for backward compatibility
    init(userId: String, conversationId: String) {
        self.viewModel = InsightsViewModel(userId: userId, conversationId: conversationId)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading insights...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Insights",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.summaries.isEmpty && viewModel.thoughts.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "lightbulb",
                        description: Text("Lucid will share summaries and autonomous thoughts as they develop")
                    )
                } else {
                    List {
                        if !viewModel.summaries.isEmpty {
                            Section("Summaries") {
                                ForEach(viewModel.summaries) { summary in
                                    SummaryRow(summary: summary)
                                }
                            }
                        }
                        
                        if !viewModel.thoughts.isEmpty {
                            ForEach(Array(viewModel.groupedThoughts.keys.sorted()), id: \.self) { phase in
                                Section(phase) {
                                    ForEach(viewModel.groupedThoughts[phase] ?? []) { thought in
                                        ThoughtRow(thought: thought)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.generateSummary()
                        }
                    } label: {
                        if viewModel.isGeneratingSummary {
                            ProgressView()
                        } else {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                    }
                    .disabled(viewModel.isGeneratingSummary)
                    
                    Button {
                        Task {
                            await viewModel.loadSummaries()
                            await viewModel.loadThoughts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.loadSummaries()
                await viewModel.loadThoughts()
            }
            .task {
                await viewModel.loadSummaries()
                await viewModel.loadThoughts()
            }
        }
    }
}

struct SummaryRow: View {
    let summary: Summary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let overview = summary.conversationOverview {
                Text(overview)
                    .font(.headline)
            }
            
            if let userPerspective = summary.userPerspective {
                Text("You: \(userPerspective)")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            if let modelPerspective = summary.modelPerspective {
                Text("Lucid: \(modelPerspective)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(summary.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("\(summary.messageCount) messages")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThoughtRow: View {
    let thought: AutonomousThought
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(thought.emoji)
                Text(thought.thoughtType.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let importance = thought.importanceScore {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(importance * 5), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            
            Text(thought.content)
                .font(.body)
            
            HStack {
                Text(thought.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                if thought.isShared {
                    Label("Shared", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

