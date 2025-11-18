//
//  ProfileView.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    // Convenience initializer for backward compatibility
    init(userId: String) {
        self.viewModel = ProfileViewModel(userId: userId)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Profile",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(error)
                    )
                } else if viewModel.facts.isEmpty {
                    ContentUnavailableView(
                        "No Facts Yet",
                        systemImage: "person.crop.circle",
                        description: Text("Lucid will learn about you through conversations")
                    )
                } else {
                    List {
                        ForEach(Array(viewModel.groupedFacts.keys.sorted()), id: \.self) { category in
                            Section(category) {
                                ForEach(viewModel.groupedFacts[category] ?? []) { fact in
                                    FactRow(fact: fact)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("What Lucid Knows")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.loadFacts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.loadFacts()
            }
            .task {
                await viewModel.loadFacts()
            }
        }
    }
}

struct FactRow: View {
    let fact: Fact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fact.content)
                .font(.body)
            
            if let category = fact.category {
                Text(category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            HStack {
                ConfidenceBadge(confidence: fact.confidence)
                
                Text("\(fact.evidenceCount) evidence")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(fact.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    
    var color: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

