import SwiftUI
import SwiftData

struct TimezoneFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TimezoneFormViewModel
    
    init(existingTimezone: Timezone? = nil) {
        // This will be properly initialized in the onAppear modifier
        let container = try! ModelContainer(for: Event.self, Timezone.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        _viewModel = State(initialValue: TimezoneFormViewModel(
            modelContext: ModelContext(container),
            existingTimezone: existingTimezone
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timezone Name") {
                    TextField("Name", text: $viewModel.name)
                }
                
                Section("Timezone") {
                    Picker("Select Timezone", selection: $viewModel.selectedIdentifier) {
                        ForEach(viewModel.availableTimezones, id: \.self) { identifier in
                            Text(identifier)
                        }
                    }
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: viewModel.selectedColor == color ? 2 : 0)
                                            .padding(2)
                                    )
                                    .onTapGesture {
                                        viewModel.selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Timezone" : "Add Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveTimezone()
                        dismiss()
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel = TimezoneFormViewModel(
                modelContext: modelContext,
                existingTimezone: viewModel.existingTimezone
            )
        }
    }
}

#Preview {
    TimezoneFormView()
        .modelContainer(for: Timezone.self, inMemory: true)
} 
