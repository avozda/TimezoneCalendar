//
//  MainTabView.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 11.05.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            WorldClockView()
                .tabItem {
                    Label("World Clock", systemImage: "clock")
                }
            
            TimezonesView()
                .tabItem {
                    Label("Timezones", systemImage: "globe")
                }
        }
    }
}