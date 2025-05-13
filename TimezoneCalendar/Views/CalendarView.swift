//
//  CalendarView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]
    
    @State private var selectedDate = Date()
    @State private var isAddingEvent = false
    
    var eventsForSelectedDate: [Event] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!.addingTimeInterval(-1)
        
        
        let baseEvents = events.filter { event in
            calendar.isDate(event.dateTime, inSameDayAs: selectedDate)
        }
        
        let recurringEvents = events.filter { event -> Bool in
            event.isRecurring && 
            !calendar.isDate(event.dateTime, inSameDayAs: selectedDate) &&
            event.occurrenceDates(from: dayStart, to: dayEnd).count > 0
        }
        
        return baseEvents + recurringEvents
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(UIColor.systemBackground))
                
                if eventsForSelectedDate.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar.badge.exclamationmark")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(eventsForSelectedDate) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(event: event)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteEvents)
                    }
                    .listStyle(.plain)
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { isAddingEvent = true }) {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingEvent) {
                AddEventView(selectedDate: selectedDate)
            }
        }
    }
    
    private func deleteEvents(offsets: IndexSet) {
        withAnimation {
            let eventsToDelete = offsets.map { eventsForSelectedDate[$0] }
            for event in eventsToDelete {
                modelContext.delete(event)
            }
        }
    }
}

// EventDetailView has been moved to its own file

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var timezones: [Timezone]
    
    @State private var title = ""
    @State private var dateTime: Date
    @State private var selectedTimezoneID: PersistentIdentifier?
    @State private var description = ""
    
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .none
    @State private var recurrenceEndType: RecurrenceEndType = .never
    @State private var recurrenceEndDate: Date = Date().addingTimeInterval(60*60*24*30) // Default to 30 days
    @State private var recurrenceCount: Int = 5
    
    enum RecurrenceEndType {
        case never
        case onDate
        case afterOccurrences
    }
    
    init(selectedDate: Date) {
        _dateTime = State(initialValue: selectedDate)
    }
    
    var defaultTimezone: Timezone? {
        timezones.first(where: { $0.isDefault })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date & Time", selection: $dateTime)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section("Recurrence") {
                    Toggle("Repeat Event", isOn: $isRecurring)
                        .onChange(of: isRecurring) { oldValue, newValue in
                            if newValue {
                                recurrenceFrequency = .weekly
                            } else {
                                recurrenceFrequency = .none
                            }
                        }
                    
                    if isRecurring {
                        Picker("Frequency", selection: $recurrenceFrequency) {
                            Text("Daily").tag(RecurrenceFrequency.daily)
                            Text("Weekly").tag(RecurrenceFrequency.weekly)
                            Text("Monthly").tag(RecurrenceFrequency.monthly)
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Ends", selection: $recurrenceEndType) {
                            Text("Never").tag(RecurrenceEndType.never)
                            Text("On Date").tag(RecurrenceEndType.onDate)
                            Text("After").tag(RecurrenceEndType.afterOccurrences)
                        }
                        .pickerStyle(.menu)
                        
                        if recurrenceEndType == .onDate {
                            DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: .date)
                        } else if recurrenceEndType == .afterOccurrences {
                            Stepper("\(recurrenceCount) occurrences", value: $recurrenceCount, in: 1...100)
                        }
                    }
                }
                
                Section("Timezone") {
                    if timezones.isEmpty {
                        Text("No timezones available. Default timezone will be used.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Timezone", selection: $selectedTimezoneID) {
                            if let defaultTZ = defaultTimezone {
                                HStack {
                                    Circle()
                                        .fill(defaultTZ.color)
                                        .frame(width: 12, height: 12)
                                    Text("\(defaultTZ.name) (Default)")
                                }
                                .tag(defaultTZ.persistentModelID as PersistentIdentifier?)
                            } else {
                                Text("None")
                                    .tag(nil as PersistentIdentifier?)
                            }
                            
                            ForEach(timezones.filter { !$0.isDefault }) { timezone in
                                HStack {
                                    Circle()
                                        .fill(timezone.color)
                                        .frame(width: 12, height: 12)
                                    Text(timezone.name)
                                }
                                .tag(timezone.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .onAppear {
                            // Set default timezone as initial selection if available
                            if selectedTimezoneID == nil, let defaultTZ = defaultTimezone {
                                selectedTimezoneID = defaultTZ.persistentModelID
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addEvent()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addEvent() {
        let selectedTimezone = selectedTimezoneID.flatMap { id in
            timezones.first { $0.persistentModelID == id }
        }
        
        var eventTimezone = selectedTimezone
        
        // If no timezone is selected, use the default timezone
        if eventTimezone == nil {
            // Try to find the default timezone
            eventTimezone = timezones.first(where: { $0.isDefault })
            
            // If no default timezone exists, create one based on current timezone
            if eventTimezone == nil {
                let currentTZ = TimeZone.current
                let newTimezone = Timezone(
                    name: currentTZ.localizedName(for: .generic, locale: .current) ?? currentTZ.identifier,
                    identifier: currentTZ.identifier,
                    isDefault: true
                )
                modelContext.insert(newTimezone)
                eventTimezone = newTimezone
            }
        }
        
        // Set up recurrence properties
        let frequency = isRecurring ? recurrenceFrequency : .none
        var endDate: Date? = nil
        var count = 0
        
        if isRecurring {
            switch recurrenceEndType {
            case .onDate:
                endDate = recurrenceEndDate
            case .afterOccurrences:
                count = recurrenceCount
            case .never:
                break
            }
        }
        
        let newEvent = Event(
            title: title, 
            dateTime: dateTime, 
            timezone: eventTimezone, 
            description: description,
            recurrenceFrequency: frequency,
            recurrenceEndDate: endDate,
            recurrenceCount: count
        )
        
        modelContext.insert(newEvent)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 
