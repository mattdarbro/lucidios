//
//  CheckInsView.swift
//  Lucid
//
//  Created by Cursor on 11/16/25.
//

import SwiftUI

struct CheckInsView: View {
    @State private var viewModel: CheckInsViewModel
    
    init(userId: String, appState: AppState) {
        _viewModel = State(initialValue: CheckInsViewModel(userId: userId, appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Loading check-ins...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Check-Ins",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Check-Ins",
                        systemImage: "bell",
                        description: Text("Lucid will surface reflective questions here when they’re ready.")
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NavigationLink {
                                CheckInDetailView(notification: notification, viewModel: viewModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(notification.question)
                                        .font(.body)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        if let time = notification.preferredTimeOfDay {
                                            Text(time.capitalized)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundStyle(.blue)
                                                .clipShape(Capsule())
                                        }
                                        
                                        Text("Priority \(Int(notification.priority * 100))%")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(notification.status.capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Check-Ins")
            .task {
                await viewModel.loadPending()
            }
            .refreshable {
                await viewModel.loadPending()
            }
        }
    }
}

struct CheckInDetailView: View {
    let notification: ThoughtNotification
    @State private var responseText: String = ""
    @State private var energy: Double = 3
    @State private var mood: Double = 3
    @State private var focus: Double = 3
    @State private var isSubmitting = false
    
    @Bindable var viewModel: CheckInsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Question") {
                Text(notification.question)
                    .font(.body)
            }
            
            Section("Your Response") {
                TextEditor(text: $responseText)
                    .frame(minHeight: 120)
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
                        await viewModel.respond(
                            to: notification,
                            responseText: responseText,
                            energy: Int(energy),
                            mood: Int(mood),
                            focus: Int(focus)
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
                        Text("Submit Response")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSubmitting)
            }
        }
        .navigationTitle("Check-In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value)) / 5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 1...5, step: 1)
        }
    }
}


