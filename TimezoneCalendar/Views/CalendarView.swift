//
//  CalendarView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData

extension Notification.Name {
    static let eventDeleted = Notification.Name("eventDeleted")
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CalendarViewModel = CalendarViewModel()
    @State private var isAddingEvent = false
    @State private var editingEvent: Event? = nil
    @State private var selectedEvent: Event? = nil
    @State private var isEditMode = false

    
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
                            Button(action: {
                                if isEditMode {
                                    // In edit mode, open event for editing
                                    editingEvent = event
                                    isAddingEvent = true
                                } else {
                                    // In normal mode, select for navigation
                                    selectedEvent = event
                                }
                            }) {
                                EventRowView(event: event)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.primary)
                        }
                        .onDelete(perform: viewModel.deleteEvents)
                    }
                    .listStyle(.plain)
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                    }
                }
                ToolbarItem {
                    Button(action: { 
                        editingEvent = nil
                        isAddingEvent = true 
                    }) {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingEvent) {
                EventFormSheet(selectedDate: viewModel.selectedDate, existingEvent: editingEvent)
            }
        }
        .onAppear {
            viewModel.setContext(modelContext: modelContext)
            
            
            NotificationCenter.default.addObserver(
                forName: .eventDeleted,
                object: nil,
                queue: .main
            ) { _ in
                viewModel.fetchEvents()
            }
        }
        .onChange(of: isAddingEvent) { _, newValue in
            if newValue == false {
                // Sheet was dismissed, refresh events list
                viewModel.fetchEvents()
            }
        }
        .onDisappear {
            // Remove notification observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .eventDeleted, object: nil)
        }
    }
    
    struct EventRowView: View {
        let event: Event
        @State private var viewModel: EventRowViewModel
        
        init(event: Event) {
            self.event = event
            _viewModel = State(initialValue: EventRowViewModel(event: event))
        }
        
        var body: some View {
            HStack(spacing: 12) {
                if viewModel.hasTimezone {
                    Rectangle()
                        .fill(viewModel.timeColor)
                        .frame(width: 4)
                        .cornerRadius(2)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(viewModel.event.title)
                            .font(.headline)
                    }
                    
                    HStack {
                        Text(viewModel.event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                            .font(.subheadline)
                        
                        if let timezone = viewModel.event.timezone {
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
                    .fill(viewModel.backgroundColor)
            )
            .cornerRadius(8)
        }
    }
    
    struct EventFormSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext
        @State private var viewModel: EventFormViewModel
        
        init(selectedDate: Date, existingEvent: Event? = nil) {
            _viewModel = State(initialValue: EventFormViewModel(
                selectedDate: selectedDate,
                existingEvent: existingEvent
            ))
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Event Details") {
                        TextField("Title", text: $viewModel.title)
                        DatePicker("Date & Time", selection: $viewModel.dateTime)
                    }
                    
                    Section("Description") {
                        TextEditor(text: $viewModel.description)
                            .frame(minHeight: 100)
                    }
                    
                    Section("Timezone") {
                        if viewModel.timezones.isEmpty {
                            Text("No timezones available. Default timezone will be used.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Timezone", selection: $viewModel.selectedTimezoneID) {
                                if let defaultTZ = viewModel.defaultTimezone {
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
                                
                                ForEach(viewModel.timezones.filter { !$0.isDefault }) { timezone in
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
                        }
                    }
                }
                .navigationTitle(viewModel.isEditing ? "Edit Event" : "Add Event")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.saveEvent()
                            dismiss()
                        }
                        .disabled(viewModel.title.isEmpty)
                    }
                }
            }
            .onAppear {
                viewModel.setContext(modelContext: modelContext)
            }
        }
    }
}
