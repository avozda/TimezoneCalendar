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

#Preview {
    MainTabView()
        .modelContainer(for: [Event.self, Timezone.self], inMemory: true)
} 