//
//  ResearchTaskFormView.swift
//  Lucid
//
//  Created by Catalina on 11/16/25.
//

import SwiftUI

struct ResearchTaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ResearchTasksViewModel
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var topic: String = ""
    @State private var morning = true
    @State private var afternoon = false
    @State private var evening = true
    @State private var night = false
    @State private var durationDays: Double = 5
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Topic category (e.g. career, health)", text: $topic)
                }
                
                Section("Check-In Times") {
                    Toggle("Morning", isOn: $morning)
                    Toggle("Afternoon", isOn: $afternoon)
                    Toggle("Evening", isOn: $evening)
                    Toggle("Night", isOn: $night)
                    if selectedCheckInTimes.isEmpty {
                        Text("Select at least one time of day.")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Duration") {
                    Stepper(value: $durationDays, in: 1...30, step: 1) {
                        Text("\(Int(durationDays)) days")
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            isSubmitting = true
                            await viewModel.createTask(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                topicCategory: topic.isEmpty ? nil : topic,
                                checkInTimes: selectedCheckInTimes,
                                durationDays: Int(durationDays)
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
                                Text("Creating…")
                            }
                        } else {
                            Text("Create Task")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("New Research Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Clear any previous error messages when the form opens
                viewModel.errorMessage = nil
            }
        }
    }
    
    private var selectedCheckInTimes: [String] {
        var times: [String] = []
        if morning { times.append("morning") }
        if afternoon { times.append("afternoon") }
        if evening { times.append("evening") }
        if night { times.append("late_night") }
        return times
    }
}


