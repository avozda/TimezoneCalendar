import SwiftUI
import SwiftData
import Observation

@Observable
class TimezoneFormViewModel {
    var modelContext: ModelContext
    var name: String = ""
    var selectedIdentifier: String = TimeZone.current.identifier
    var selectedColor: Color = .blue
    var isEditing: Bool = false
    var existingTimezone: Timezone?
    
    let colorOptions: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .teal, .indigo, .mint
    ]
    
    init(modelContext: ModelContext, existingTimezone: Timezone? = nil) {
        self.modelContext = modelContext
        self.existingTimezone = existingTimezone
        
        if let timezone = existingTimezone {
            self.isEditing = true
            self.name = timezone.name
            self.selectedIdentifier = timezone.identifier
            
            if let colorHex = timezone.colorHex {
                self.selectedColor = Color(hex: colorHex) ?? .blue
            }
        }
    }
    
    var availableTimezones: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }
    
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
    
    func saveTimezone() {
        let colorHex = hexString(from: selectedColor)
        
        if isEditing, let timezone = existingTimezone {
            // Update existing timezone
            timezone.name = name
            timezone.identifier = selectedIdentifier
            timezone.colorHex = colorHex
        } else {
            // Create new timezone
            let newTimezone = Timezone(name: name, identifier: selectedIdentifier, colorHex: colorHex)
            modelContext.insert(newTimezone)
        }
    }
} 
