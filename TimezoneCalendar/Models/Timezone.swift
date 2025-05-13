//
//  Timezone.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.05.2025.
//
import Foundation
import SwiftUI
import SwiftData

@Model
final class Timezone {
    var name: String
    var identifier: String
    var colorHex: String?
    var isDefault: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Event.timezone)
    var events: [Event] = []
    
    init(name: String, identifier: String, colorHex: String = "#007AFF", isDefault: Bool = false) {
        self.name = name
        self.identifier = identifier
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
    
    var color: Color {
        guard let hexColor = colorHex, !hexColor.isEmpty else {
            return .blue
        }
        return Color(hex: hexColor) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
} 