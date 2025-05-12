//
//  TimezoneCalendarApp.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.05.2025.
//

import SwiftUI
import SwiftData

@main
struct TimezoneCalendarApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            Timezone.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    setupDefaultTimezone()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupDefaultTimezone() {
        Task {
            do {
                let context = sharedModelContainer.mainContext
                
                // Check if we already have a default timezone
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
