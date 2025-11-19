//
//  InsightDiscussionView.swift
//  Lucid
//
//  Created by Claude on 11/18/25.
//

import SwiftUI

struct InsightDiscussionView: View {
    @Environment(\.dismiss) private var dismiss
    let insight: Insight
    let conversation: Conversation
    let onValidate: (String, String?) -> Void

    @State private var chatViewModel: ChatViewModel
    @State private var showingValidation = false
    @State private var refinementText = ""

    init(insight: Insight, conversation: Conversation, onValidate: @escaping (String, String?) -> Void) {
        self.insight = insight
        self.conversation = conversation
        self.onValidate = onValidate

        // Initialize chat view model
        _chatViewModel = State(initialValue: ChatViewModel(
            userId: conversation.userId,
            conversationId: conversation.id
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Insight Context Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Discussing Insight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(insight.insightText)
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // Chat View
                ChatView(viewModel: chatViewModel)
            }
            .navigationTitle("Refine Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Validate") {
                        showingValidation = true
                    }
                }
            }
            .alert("Validate Insight", isPresented: $showingValidation) {
                TextField("Your refined interpretation (optional)", text: $refinementText)

                Button("Accept") {
                    onValidate("accepted", refinementText.isEmpty ? nil : refinementText)
                    dismiss()
                }

                Button("Refine") {
                    onValidate("refined", refinementText.isEmpty ? nil : refinementText)
                    dismiss()
                }

                Button("Reject") {
                    onValidate("rejected", refinementText.isEmpty ? nil : refinementText)
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("After discussing, how would you validate this insight?")
            }
        }
    }
}
