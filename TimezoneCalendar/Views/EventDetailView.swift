//
//  EventDetailView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    let event: Event
    @Query private var timezones: [Timezone]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            // Header with title and time
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.secondary)
                        
                        Text(event.localDateTime, format: .dateTime.day().month().year())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        
                        Text(event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                            .foregroundStyle(.secondary)
                    }
                    
                    if let timezone = event.timezone {
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
                    
                    if event.isRecurring {
                        HStack(spacing: 6) {
                            Image(systemName: "repeat")
                                .foregroundStyle(.secondary)
                            
                            Text(recurrenceDescription)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
            
            // Description section
            if !event.eventDescription.isEmpty {
                Section {
                    Text(event.eventDescription)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                } header: {
                    Text("Description")
                }
            }
            
            // Timezones section
            if !timezones.isEmpty {
                Section {
                    ForEach(timezones) { timezone in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(timezone.name)
                                    .font(.headline)
                                Text(event.dateTime.convertToTimezone(from: event.timezone?.identifier, to: timezone.identifier))
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
                    showingDeleteConfirmation = true
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
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
    
    private func deleteEvent() {
        modelContext.delete(event)
        dismiss()
    }
    
    private var recurrenceDescription: String {
        var description = "Repeats "
        
        switch event.recurrenceFrequency {
        case .daily:
            description += "daily"
        case .weekly:
            description += "weekly"
        case .monthly:
            description += "monthly"
        case nil:
            return ""
        case .some(.none):
            return ""
        }
        
        if let endDate = event.recurrenceEndDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            description += " until \(formatter.string(from: endDate))"
        } else if event.recurrenceCount > 0 {
            description += " for \(event.recurrenceCount) occurrences"
        }
        
        return description
    }
}

#Preview {
    // Creating a sample event for preview
    let event = Event(
        title: "Sample Event",
        dateTime: Date(),
        timezone: nil,
        description: "This is a sample event description.",
        recurrenceFrequency: .weekly,
        recurrenceEndDate: nil,
        recurrenceCount: 5
    )
    
    return NavigationStack {
        EventDetailView(event: event)
    }
    .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 