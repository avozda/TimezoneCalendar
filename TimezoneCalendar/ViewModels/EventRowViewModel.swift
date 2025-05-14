import SwiftUI
import Observation

@Observable
class EventRowViewModel {
    let event: Event
    
    init(event: Event) {
        self.event = event
    }
    
    var hasTimezone: Bool {
        return event.timezone != nil
    }
    
    var timeColor: Color {
        return event.timezone?.color ?? .clear
    }
    
    var backgroundOpacity: Double {
        return 0.1
    }
    
    var backgroundColor: Color {
        return event.timezone?.color.opacity(backgroundOpacity) ?? .clear
    }
} 