//
//  TimezoneCalendarApp.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda (xvozdaa00) on 10.05.2025.
//

import SwiftUI
import SwiftData

@main
struct TimezoneCalendarApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    appViewModel.setupDefaultTimezone()
                }
        }
        .modelContainer(appViewModel.modelContainer)
    }
}

