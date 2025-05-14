import SwiftUI
import SwiftData
import Observation

@Observable
class WorldClockViewModel {
    var modelContext: ModelContext
    var timezones: [Timezone] = []
    var events: [Event] = []
    var currentDate: Date = Date()
    var showingAllEvents: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }
    
    func fetchData() {
        fetchTimezones()
        fetchEvents()
    }
    
    func fetchTimezones() {
        let descriptor = FetchDescriptor<Timezone>()
        do {
            timezones = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching timezones: \(error)")
        }
    }
    
    func fetchEvents() {
        let descriptor = FetchDescriptor<Event>(sortBy: [SortDescriptor(\.dateTime)])
        do {
            events = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching events: \(error)")
        }
    }
    
    var upcomingAllEvents: [Event] {
        let calendar = Calendar.current
        let now = currentDate
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        
        return events.filter { event in
            event.dateTime >= now &&
            event.dateTime <= nextWeek
        }.sorted { $0.dateTime < $1.dateTime }
    }
    
    // Get upcoming events for a specific timezone (next 24 hours)
    func upcomingEvents(for timezone: Timezone) -> [Event] {
        let calendar = Calendar.current
        let now = currentDate
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        
        return events.filter { event in
            event.timezone?.id == timezone.id &&
            event.dateTime >= now &&
            event.dateTime <= tomorrow
        }.sorted { $0.dateTime < $1.dateTime }
    }
    
    // format time to string
    func formattedTime(for timezone: Timezone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        return formatter.string(from: currentDate)
    }
    
    func formattedDate(for timezone: Timezone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        return formatter.string(from: currentDate)
    }
    
    func timeOffset(for timezone: Timezone) -> String {
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
    
    func toggleShowingAllEvents() {
        showingAllEvents.toggle()
    }
    
    func updateCurrentTime() {
        currentDate = Date()
    }
} 