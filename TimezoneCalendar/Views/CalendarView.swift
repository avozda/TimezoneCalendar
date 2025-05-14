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
    @State private var viewModel: CalendarViewModel
    @State private var isAddingEvent = false
    
    init() {
        // This will be properly initialized in the onAppear modifier
        let container = try! ModelContainer(for: Event.self, Timezone.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        _viewModel = State(initialValue: CalendarViewModel(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(UIColor.systemBackground))
                
                if viewModel.eventsForSelectedDate.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar.badge.exclamationmark")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.eventsForSelectedDate) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(event: event)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: viewModel.deleteEvents)
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
                EventFormView(selectedDate: viewModel.selectedDate)
            }
        }
        .onAppear {
            viewModel = CalendarViewModel(modelContext: modelContext)
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
        
        // Create a new event
        let newEvent = Event(
            title: title,
            dateTime: dateTime,
            timezone: eventTimezone,
            description: description
        )
        
        modelContext.insert(newEvent)
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                
                Spacer()
                
                if let timezone = event.timezone {
                    Circle()
                        .fill(timezone.color)
                        .frame(width: 12, height: 12)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Text(event.localDateTime, format: .dateTime.hour().minute())
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                if let timezone = event.timezone {
                    Text("(\(timezone.name))")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 

