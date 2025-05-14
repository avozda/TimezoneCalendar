import SwiftUI
import SwiftData
import Observation

@Observable
class EventDetailViewModel {
    var modelContext: ModelContext
    var event: Event
    var timezones: [Timezone] = []
    var showingDeleteConfirmation: Bool = false
    
    init(modelContext: ModelContext, event: Event) {
        self.modelContext = modelContext
        self.event = event
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
    
    func deleteEvent() {
        modelContext.delete(event)
    }
} 