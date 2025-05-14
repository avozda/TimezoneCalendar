import SwiftUI
import SwiftData
import Observation

@Observable
class TimezonesViewModel {
    var modelContext: ModelContext
    var timezones: [Timezone] = []
    var showingDefaultAlert: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTimezones()
    }
    
    func fetchTimezones() {
        let descriptor = FetchDescriptor<Timezone>()
        do {
            timezones = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching timezones: \(error)")
        }
    }
    
    func deleteTimezones(at offsets: IndexSet) {
        for index in offsets {
            let timezone = timezones[index]
            // Check if it's the default timezone
            if timezone.isDefault {
                showingDefaultAlert = true
                return
            }
            
            modelContext.delete(timezone)
        }
        fetchTimezones()
    }
} 