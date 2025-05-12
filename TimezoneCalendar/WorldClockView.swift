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
    @Query private var timezones: [Timezone]
    @Query private var events: [Event]
    
    @State private var currentDate = Date()
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var showingAllEvents = false
    
    var upcomingAllEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        
        return events.filter { event in
            event.dateTime >= now &&
            event.dateTime <= nextWeek
        }.sorted { $0.dateTime < $1.dateTime }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Upcoming events section
                    if !upcomingAllEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Upcoming Events")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: { showingAllEvents.toggle() }) {
                                    Text(showingAllEvents ? "Show Less" : "Show All")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(showingAllEvents ? upcomingAllEvents : Array(upcomingAllEvents.prefix(5))) { event in
                                        EventCard(event: event, currentDate: currentDate)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // World clocks
                    LazyVStack(spacing: 16) {
                        if timezones.isEmpty {
                            ContentUnavailableView(
                                "No Timezones",
                                systemImage: "globe",
                                description: Text("Add timezones in the Timezones tab")
                            )
                            .padding()
                        } else {
                            ForEach(timezones) { timezone in
                                WorldClockCard(timezone: timezone, currentDate: currentDate, events: upcomingEvents(for: timezone))
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("World Clock")
            .onReceive(timer) { _ in
                currentDate = Date()
            }
        }
    }
    
    // Get upcoming events for a specific timezone (next 24 hours)
    private func upcomingEvents(for timezone: Timezone) -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        
        return events.filter { event in
            event.timezone?.id == timezone.id &&
            event.dateTime >= now &&
            event.dateTime <= tomorrow
        }.sorted { $0.dateTime < $1.dateTime }
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
    let currentDate: Date
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
                Text(formattedTime(for: timezone))
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                
                Text(timeOffset(for: timezone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            
            Text(formattedDate(for: timezone))
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
    
    // Format the current time for the timezone
    private func formattedTime(for timezone: Timezone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        return formatter.string(from: currentDate)
    }
    
    // Format the current date for the timezone
    private func formattedDate(for timezone: Timezone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        return formatter.string(from: currentDate)
    }
    
    // Calculate time offset from current timezone
    private func timeOffset(for timezone: Timezone) -> String {
        let currentTZ = TimeZone.current
        let targetTZ = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        
        let currentOffset = currentTZ.secondsFromGMT(for: currentDate)
        let targetOffset = targetTZ.secondsFromGMT(for: currentDate)
        let difference = (targetOffset - currentOffset) / 3600
        
        if difference == 0 {
            return "Same time"
        } else if difference > 0 {
            return "+\(difference)h"
        } else {
            return "\(difference)h"
        }
    }
}

#Preview {
    WorldClockView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 
