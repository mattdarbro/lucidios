//
//  ConversationListView.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import SwiftUI

struct ConversationListView: View {
    @State private var viewModel: ConversationListViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onSelectConversation: (Conversation) -> Void
    let onCreateNew: () -> Void
    
    init(userId: String, onSelectConversation: @escaping (Conversation) -> Void, onCreateNew: @escaping () -> Void) {
        _viewModel = State(initialValue: ConversationListViewModel(userId: userId))
        self.onSelectConversation = onSelectConversation
        self.onCreateNew = onCreateNew
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Conversations",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations Yet",
                        systemImage: "message",
                        description: Text("Start a new conversation to begin chatting with Lucid")
                    )
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                onSelectConversation(conversation)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title ?? "Untitled")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(conversation.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let conversation = viewModel.conversations[index]
                                Task {
                                    await viewModel.deleteConversation(conversation)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onCreateNew()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        Task {
                            await viewModel.loadConversations()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.loadConversations()
            }
        }
    }
}

