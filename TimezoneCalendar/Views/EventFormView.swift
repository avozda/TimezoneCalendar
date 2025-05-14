import SwiftUI
import SwiftData

struct EventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EventFormViewModel
    
    init(selectedDate: Date, existingEvent: Event? = nil) {
        // This will be properly initialized in the onAppear modifier
        let container = try! ModelContainer(for: Event.self, Timezone.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        _viewModel = State(initialValue: EventFormViewModel(
            modelContext: ModelContext(container), 
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
            viewModel = EventFormViewModel(
                modelContext: modelContext, 
                selectedDate: viewModel.dateTime,
                existingEvent: viewModel.existingEvent
            )
        }
    }
}

#Preview {
    EventFormView(selectedDate: Date())
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 
