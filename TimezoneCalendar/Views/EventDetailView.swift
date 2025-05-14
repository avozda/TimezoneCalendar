//
//  EventDetailView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData


struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EventDetailViewModel
    
    init(event: Event) {
        // Initialize with default values, will be updated in onAppear
        _viewModel = State(initialValue: EventDetailViewModel(
            modelContext: ModelContext(try! ModelContainer(for: Event.self, Timezone.self)),
            event: event
        ))
    }
    
    var body: some View {
        List {
            // Header with title and time
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.event.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.event.localDateTime, format: .dateTime.day().month().year())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                            .foregroundStyle(.secondary)
                    }
                    
                    if let timezone = viewModel.event.timezone {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .foregroundStyle(.secondary)
                            
                            Text(timezone.name)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(timezone.color)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.top, 2)
                    }
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
            
            // Description section
            if !viewModel.event.eventDescription.isEmpty {
                Section {
                    Text(viewModel.event.eventDescription)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                } header: {
                    Text("Description")
                }
            }
            
            // Timezones section
            if !viewModel.timezones.isEmpty {
                Section {
                    ForEach(viewModel.timezones) { timezone in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(timezone.name)
                                    .font(.headline)
                                Text(viewModel.event.dateTime.convertToTimezone(from: viewModel.event.timezone?.identifier, to: timezone.identifier))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(timezone.color)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Time in Other Timezones")
                }
            }
            
            // Delete button section
            Section {
                Button(role: .destructive) {
                    viewModel.showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Event")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Event", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteEvent()
                // Post notification that an event was deleted
                NotificationCenter.default.post(name: .eventDeleted, object: nil)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .onAppear {
            viewModel = EventDetailViewModel(
                modelContext: modelContext,
                event: viewModel.event
            )
        }
    }
}

#Preview {
    // Creating a sample event for preview
    let event = Event(
        title: "Sample Event",
        dateTime: Date(),
        timezone: nil,
        description: "This is a sample event description."
    )
    
    return NavigationStack {
        EventDetailView(event: event)
    }
    .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 
