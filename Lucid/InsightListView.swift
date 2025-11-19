//
//  InsightListView.swift
//  Lucid
//
//  Created by Claude on 11/18/25.
//

import SwiftUI

struct InsightListView: View {
    @State private var viewModel: InsightListViewModel
    @State private var selectedInsight: Insight?
    @State private var showingInsightActions = false
    @State private var showingInsightDiscussion = false
    @State private var discussionConversation: Conversation?

    init(userId: String) {
        _viewModel = State(initialValue: InsightListViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pendingInsights.isEmpty {
                    ProgressView("Loading insights...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Insights",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.pendingInsights.isEmpty && viewModel.confirmedInsights.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "lightbulb",
                        description: Text("Complete a few task check-ins to see AI-generated insights.")
                    )
                } else {
                    List {
                        if !viewModel.pendingInsights.isEmpty {
                            Section {
                                ForEach(viewModel.pendingInsights) { insight in
                                    InsightCardView(insight: insight)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedInsight = insight
                                            showingInsightActions = true
                                        }
                                }
                            } header: {
                                HStack {
                                    Text("Pending Review")
                                    Spacer()
                                    Text("\(viewModel.pendingInsights.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if !viewModel.confirmedInsights.isEmpty {
                            Section("Confirmed") {
                                ForEach(viewModel.confirmedInsights) { insight in
                                    InsightCardView(insight: insight)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Insights")
            .task {
                await viewModel.loadPendingInsights()
            }
            .refreshable {
                await viewModel.loadPendingInsights()
            }
            .confirmationDialog(
                "What would you like to do with this insight?",
                isPresented: $showingInsightActions,
                presenting: selectedInsight
            ) { insight in
                Button("I Agree") {
                    Task {
                        await viewModel.validateInsight(insight, action: "accepted")
                    }
                }

                Button("I Disagree") {
                    Task {
                        await viewModel.validateInsight(insight, action: "rejected")
                    }
                }

                Button("Discuss with Lucid") {
                    Task {
                        if let result = await viewModel.startDiscussion(for: insight) {
                            discussionConversation = result.0
                            showingInsightDiscussion = true
                        }
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingInsightDiscussion) {
                if let conversation = discussionConversation {
                    InsightDiscussionView(
                        insight: selectedInsight!,
                        conversation: conversation,
                        onValidate: { action, refinement in
                            Task {
                                await viewModel.validateInsight(
                                    selectedInsight!,
                                    action: action,
                                    refinementText: refinement
                                )
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - InsightCardView
struct InsightCardView: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and confidence
            HStack {
                Image(systemName: patternIcon)
                    .font(.title3)
                    .foregroundStyle(patternColor)

                Spacer()

                // Confidence badge
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundStyle(confidenceColor)
                    .clipShape(Capsule())
            }

            // Insight text
            Text(insight.insightText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // User refinement (if any)
            if let refinement = insight.userRefinement {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Text(refinement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(8)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Footer with status and time
            HStack {
                // Status badge
                Text(insight.status.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                Spacer()

                // Time ago
                Text(insight.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var patternIcon: String {
        switch insight.patternType {
        case "temporal_mood":
            return "clock.fill"
        case "language_change":
            return "text.bubble.fill"
        case "energy_correlation":
            return "bolt.fill"
        default:
            return "lightbulb.fill"
        }
    }

    private var patternColor: Color {
        switch insight.patternType {
        case "temporal_mood":
            return .blue
        case "language_change":
            return .purple
        case "energy_correlation":
            return .orange
        default:
            return .yellow
        }
    }

    private var confidenceColor: Color {
        if insight.confidence >= 0.8 {
            return .green
        } else if insight.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private var statusColor: Color {
        switch insight.status {
        case "proposed":
            return .orange
        case "confirmed":
            return .green
        case "refined":
            return .blue
        case "rejected":
            return .red
        default:
            return .gray
        }
    }
}
