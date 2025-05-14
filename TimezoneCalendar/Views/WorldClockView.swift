//
//  WorldClockView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 13.05.2025.
//

import SwiftUI
import SwiftData

struct WorldClockView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorldClockViewModel
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        // Initialize with empty ViewModel, will be set in onAppear
        _viewModel = State(initialValue: WorldClockViewModel(modelContext: ModelContext(try! ModelContainer(for: Event.self, Timezone.self))))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Upcoming events section
                    if !viewModel.upcomingAllEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Upcoming Events")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: { viewModel.toggleShowingAllEvents() }) {
                                    Text(viewModel.showingAllEvents ? "Show Less" : "Show All")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.showingAllEvents ? viewModel.upcomingAllEvents : Array(viewModel.upcomingAllEvents.prefix(5))) { event in
                                        EventCard(event: event, currentDate: viewModel.currentDate)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // World clocks
                    LazyVStack(spacing: 16) {
                        if viewModel.timezones.isEmpty {
                            ContentUnavailableView(
                                "No Timezones",
                                systemImage: "globe",
                                description: Text("Add timezones in the Timezones tab")
                            )
                            .padding()
                        } else {
                            ForEach(viewModel.timezones) { timezone in
                                WorldClockCard(
                                    timezone: timezone, 
                                    viewModel: viewModel, 
                                    events: viewModel.upcomingEvents(for: timezone)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("World Clock")
            .onReceive(timer) { _ in
                viewModel.updateCurrentTime()
            }
        }
        .onAppear {
            viewModel = WorldClockViewModel(modelContext: modelContext)
        }
    }
}

struct EventCard: View {
    let event: Event
    let currentDate: Date
    
    var timeUntilEvent: String {
        let calendar = Calendar.current
        
        // Convert the current date to the event's timezone if available
        var adjustedCurrentDate = currentDate
        if let eventTimezoneId = event.timezone?.identifier {
            adjustedCurrentDate = currentDate.convertedToTimezone(from: nil, to: eventTimezoneId)
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: adjustedCurrentDate, to: event.dateTime)
        
        if let hours = components.hour, let minutes = components.minute {
            if hours < 0 || minutes < 0 {
                return "In progress"
            } else if hours == 0 {
                return "In \(minutes)m"
            } else {
                return "In \(hours)h \(minutes)m"
            }
        }
        return ""
    }
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            VStack(alignment: .leading, spacing: 8) {
                // Time info
                HStack {
                    Text(event.dateTime, format: .dateTime.hour().minute())
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(timeUntilEvent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Event title
                Text(event.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                // Timezone info if available
                if let timezone = event.timezone {
                    HStack {
                        Circle()
                            .fill(timezone.color)
                            .frame(width: 8, height: 8)
                        
                        Text(timezone.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(event.timezone?.color.opacity(0.1) ?? Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorldClockCard: View {
    let timezone: Timezone
    let viewModel: WorldClockViewModel
    let events: [Event]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Timezone header
            HStack {
                VStack(alignment: .leading) {
                    Text(timezone.name)
                        .font(.headline)
                    Text(timezone.identifier)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(timezone.color)
                    .frame(width: 12, height: 12)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.formattedTime(for: timezone))
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                
                Text(viewModel.timeOffset(for: timezone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            
            Text(viewModel.formattedDate(for: timezone))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !events.isEmpty {
                Divider()
                
                Text("Upcoming")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(events.prefix(3)) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        HStack(spacing: 12) {
                            Text(event.dateTime, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(event.title)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if events.count > 3 {
                    Text("+ \(events.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(timezone.color.opacity(0.1))
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}

#Preview {
    WorldClockView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 
