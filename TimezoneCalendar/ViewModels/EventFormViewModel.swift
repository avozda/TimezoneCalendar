import SwiftUI
import SwiftData
import Observation

@Observable
class EventFormViewModel {
    var modelContext: ModelContext
    var title: String = ""
    var dateTime: Date = Date()
    var selectedTimezoneID: PersistentIdentifier?
    var description: String = ""
    
    var timezones: [Timezone] = []
    var isEditing: Bool = false
    var existingEvent: Event?
    
    init(modelContext: ModelContext, selectedDate: Date = Date(), existingEvent: Event? = nil) {
        self.modelContext = modelContext
        self.dateTime = selectedDate
        self.existingEvent = existingEvent
        fetchTimezones()
        
        if let event = existingEvent {
            self.isEditing = true
            self.title = event.title
            self.dateTime = event.dateTime
            self.description = event.eventDescription
            
            if let timezone = event.timezone {
                self.selectedTimezoneID = timezone.persistentModelID
            }
        }
    }
    
    func fetchTimezones() {
        let descriptor = FetchDescriptor<Timezone>()
        do {
            timezones = try modelContext.fetch(descriptor)
            
            // Set default timezone as initial selection if available and not already set
            if selectedTimezoneID == nil, let defaultTZ = defaultTimezone {
                selectedTimezoneID = defaultTZ.persistentModelID
            }
        } catch {
            print("Error fetching timezones: \(error)")
        }
    }
    
    var defaultTimezone: Timezone? {
        timezones.first(where: { $0.isDefault })
    }
    
    func saveEvent() {
        let selectedTimezone = selectedTimezoneID.flatMap { id in
            timezones.first { $0.persistentModelID == id }
        }
        
        var eventTimezone = selectedTimezone
        
        // If no timezone is selected, use the default timezone
        if eventTimezone == nil {
            eventTimezone = timezones.first(where: { $0.isDefault })
        }
        
        if isEditing, let event = existingEvent {
            event.title = title
            event.dateTime = dateTime
            event.timezone = eventTimezone
            event.eventDescription = description
        } else {
            let newEvent = Event(
                title: title, 
                dateTime: dateTime, 
                timezone: eventTimezone, 
                description: description
            )
            
            modelContext.insert(newEvent)
        }
    }
} 