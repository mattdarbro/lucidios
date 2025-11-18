//
//  ContentView.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var appState = AppState()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView("Initializing Lucid...")
            } else if let error = appState.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await appState.initialize()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let user = appState.currentUser,
                      let chatViewModel = appState.chatViewModel,
                      let insightsViewModel = appState.insightsViewModel,
                      let profileViewModel = appState.profileViewModel {
                TabView(selection: $selectedTab) {
                    ResearchTasksView(userId: user.id)
                        .tabItem {
                            Label("Research", systemImage: "chart.bar.doc.horizontal")
                        }
                        .tag(0)
                    
                    CheckInsView(userId: user.id, appState: appState)
                        .tabItem {
                            ZStack(alignment: .topTrailing) {
                                Label("Check-Ins", systemImage: "bell")
                                
                                if appState.pendingNotificationsCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 8, y: -6)
                                }
                            }
                        }
                        .tag(1)
                    
                    ConversationListView(
                        userId: user.id,
                        onSelectConversation: { conversation in
                            appState.switchToConversation(conversation)
                            selectedTab = 2 // Switch to Chat tab
                        },
                        onCreateNew: {
                            Task {
                                await appState.createNewConversation()
                                selectedTab = 2 // Switch to Chat tab
                            }
                        }
                    )
                    .tabItem {
                        Label("Conversations", systemImage: "list.bullet")
                    }
                    .tag(2)
                    
                    ChatView(viewModel: chatViewModel)
                        .id("chat-\(chatViewModel.conversationId)")
                        .tabItem {
                            Label("Chat", systemImage: "message")
                        }
                        .tag(3)
                    
                    InsightsView(viewModel: insightsViewModel)
                        .id("insights-\(insightsViewModel.userId)")
                        .tabItem {
                            Label("Insights", systemImage: "lightbulb")
                        }
                        .tag(4)
                    
                    ProfileView(viewModel: profileViewModel)
                        .id("profile-\(profileViewModel.userId)")
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(5)
                }
                .onChange(of: selectedTab) { _, _ in
                    // Dismiss keyboard when switching tabs
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .task {
            await appState.initialize()
        }
    }
}
