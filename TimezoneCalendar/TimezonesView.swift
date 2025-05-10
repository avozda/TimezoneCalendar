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
    @Query private var timezones: [Timezone]
    @State private var isAddingTimezone = false
    @State private var showingDefaultAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(timezones) { timezone in
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
                }
                .onDelete(perform: deleteTimezones)
            }
            .navigationTitle("Timezones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { isAddingTimezone = true }) {
                        Label("Add Timezone", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTimezone) {
                AddTimezoneView()
            }
            .alert("Cannot Delete Default Timezone", isPresented: $showingDefaultAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The default timezone cannot be deleted.")
            }
        }
    }
    
    private func deleteTimezones(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let timezone = timezones[index]
                // Show alert if it's the default timezone
                if timezone.isDefault {
                    showingDefaultAlert = true
                } else {
                    modelContext.delete(timezone)
                }
            }
        }
    }
}

struct AddTimezoneView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedIdentifier = TimeZone.current.identifier
    @State private var selectedColor = Color.blue
    
    // Predefined colors for selection
    let colorOptions: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .teal, .indigo, .mint
    ]
    
    // Convert Color to hex string
    func hexString(from color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
    
    var availableTimezones: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timezone Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Timezone") {
                    Picker("Select Timezone", selection: $selectedIdentifier) {
                        ForEach(availableTimezones, id: \.self) { identifier in
                            Text(identifier)
                        }
                    }
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                            .padding(2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addTimezone()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addTimezone() {
        let colorHex = hexString(from: selectedColor)
        let newTimezone = Timezone(name: name, identifier: selectedIdentifier, colorHex: colorHex)
        modelContext.insert(newTimezone)
    }
}

#Preview {
    TimezonesView()
        .modelContainer(for: Timezone.self, inMemory: true)
} 