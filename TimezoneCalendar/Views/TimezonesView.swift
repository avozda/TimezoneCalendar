//
//  TimezonesView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData

struct TimezonesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TimezonesViewModel
    @State private var isAddingTimezone = false
    @State private var editingTimezone: Timezone? = nil
    
    init() {
        // Initialize with empty ViewModel, will be set in onAppear
        _viewModel = State(initialValue: TimezonesViewModel(modelContext: ModelContext(try! ModelContainer(for: Event.self, Timezone.self))))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.timezones) { timezone in
                    HStack {
                        Circle()
                            .fill(timezone.color)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(timezone.name)
                                    .font(.headline)
                                
                                if timezone.isDefault {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            
                            Text(timezone.identifier)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTimezone = timezone
                        isAddingTimezone = true
                    }
                }
                .onDelete(perform: viewModel.deleteTimezones)
            }
            .navigationTitle("Timezones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { 
                        editingTimezone = nil
                        isAddingTimezone = true 
                    }) {
                        Label("Add Timezone", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTimezone) {
                TimezoneFormSheet(existingTimezone: editingTimezone)
            }
            .alert("Cannot Delete Default Timezone", isPresented: $viewModel.showingDefaultAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The default timezone cannot be deleted.")
            }
        }
        .onAppear {
            viewModel = TimezonesViewModel(modelContext: modelContext)
        }
        .onChange(of: isAddingTimezone) { _, newValue in
            if newValue == false {
                // Sheet was dismissed, refresh timezones list
                viewModel.fetchTimezones()
            }
        }
    }
    
    // Embedded TimezoneFormView (previously a separate file)
    struct TimezoneFormSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext
        @State private var viewModel: TimezoneFormViewModel
        
        init(existingTimezone: Timezone? = nil) {
            // Initialize with default values, will be updated in onAppear
            _viewModel = State(initialValue: TimezoneFormViewModel(
                modelContext: ModelContext(try! ModelContainer(for: Event.self, Timezone.self)),
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
}

#Preview {
    TimezonesView()
        .modelContainer(for: Timezone.self, inMemory: true)
} 
