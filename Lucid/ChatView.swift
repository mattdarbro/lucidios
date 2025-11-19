//
//  ChatView.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    // Convenience initializer for backward compatibility
    init(userId: String, conversationId: String) {
        self.viewModel = ChatViewModel(userId: userId, conversationId: conversationId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Thinking...")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding()
                            .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onTapGesture {
                    isInputFocused = false
                }
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            // Input Bar
            HStack(alignment: .bottom) {
                TextField("Message Lucid...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        Task {
                            isInputFocused = false
                            await viewModel.sendMessage()
                        }
                    }

                Button {
                    Task {
                        isInputFocused = false
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.inputText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(.background.secondary)
        }
        .navigationTitle("Lucid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            await viewModel.extractFacts()
                        }
                    } label: {
                        Label("Extract Facts", systemImage: "brain")
                    }

                    Button {
                        Task {
                            await viewModel.generateSummary()
                        }
                    } label: {
                        Label("Generate Summary", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            // Only load messages if we don't have any yet
            if viewModel.messages.isEmpty {
                await viewModel.loadMessages()
            }
        }
        .onAppear {
            // Reload messages when view appears (in case new messages were added)
            // But only if we already have messages (to avoid double-loading)
            if !viewModel.messages.isEmpty {
                Task {
                    await viewModel.loadMessages()
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isLoading {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

