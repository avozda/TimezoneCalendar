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
        return events.filter { event in
            calendar.isDate(event.dateTime, inSameDayAs: selectedDate)
        }
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

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            if let timezone = event.timezone {
                Rectangle()
                    .fill(timezone.color)
                    .frame(width: 4)
                    .cornerRadius(2)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                HStack {
                    Text(event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                        .font(.subheadline)
                    
                    if let timezone = event.timezone {
                        Text("(\(timezone.name))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(event.timezone?.color.opacity(0.1) ?? Color.clear)
        )
        .cornerRadius(8)
    }
}

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
                                Text(convertToTimezone(date: event.dateTime, from: event.timezone?.identifier, to: timezone.identifier))
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
    
    private func convertToTimezone(date: Date, from sourceIdentifier: String?, to destinationIdentifier: String) -> String {
        let sourceTimeZone = sourceIdentifier.flatMap { TimeZone(identifier: $0) } ?? TimeZone.current
        let destinationTimeZone = TimeZone(identifier: destinationIdentifier) ?? TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: date)
        let timeInterval = TimeInterval(destinationOffset - sourceOffset)
        
        let convertedDate = date.addingTimeInterval(timeInterval)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: convertedDate)
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var timezones: [Timezone]
    
    @State private var title = ""
    @State private var dateTime: Date
    @State private var selectedTimezoneID: PersistentIdentifier?
    @State private var description = ""
    
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
        
        let newEvent = Event(title: title, dateTime: dateTime, timezone: eventTimezone, description: description)
        modelContext.insert(newEvent)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 