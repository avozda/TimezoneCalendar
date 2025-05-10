//
//  Item.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.05.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
