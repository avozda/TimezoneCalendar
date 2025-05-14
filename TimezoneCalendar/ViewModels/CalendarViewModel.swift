//
//  CalendarViewModel.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class CalendarViewModel {
    var modelContext: ModelContext?
    var events: [Event] = []
    var selectedDate: Date = Date()
    
    init() {
    }
    
    func setContext(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchEvents()
    }
    
    func fetchEvents() {
        let descriptor = FetchDescriptor<Event>(sortBy: [SortDescriptor(\.dateTime)])
        do {
            events = try modelContext!.fetch(descriptor)
        } catch {
            print("Error fetching events: \(error)")
        }
    }
    
    var eventsForSelectedDate: [Event] {
        let calendar = Calendar.current
        
        return events.filter { event in
            calendar.isDate(event.dateTime, inSameDayAs: selectedDate)
        }
    }
    
    func deleteEvent(_ event: Event) {
        modelContext!.delete(event)
        fetchEvents()
    }
    
    func deleteEvents(at offsets: IndexSet) {
        let eventsToDelete = offsets.map { eventsForSelectedDate[$0] }
        for event in eventsToDelete {
            modelContext!.delete(event)
        }
        fetchEvents()
    }
} 
