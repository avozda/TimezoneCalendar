//
//  AppViewModel.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class AppViewModel {
    var modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Event.self,
            Timezone.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    @MainActor
    func setupDefaultTimezone() {
        Task { @MainActor in
            do {
                let context = modelContainer.mainContext
                
                // Check if there is already a default timezone
                let descriptor = FetchDescriptor<Timezone>(predicate: #Predicate { $0.isDefault == true })
                let defaultTimezones = try context.fetch(descriptor)
                
                if defaultTimezones.isEmpty {
                    // Create a default timezone based on users current timezone
                    let currentTZ = TimeZone.current
                    let defaultName = currentTZ.localizedName(for: .generic, locale: .current) ?? "Local Time"
                    let defaultTimezone = Timezone(
                        name: defaultName,
                        identifier: currentTZ.identifier,
                        colorHex: "#007AFF",
                        isDefault: true
                    )
                    context.insert(defaultTimezone)
                }
            } catch {
                print("Error setting up default timezone: \(error)")
            }
        }
    }
} 
