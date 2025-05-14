//
//  Event.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.05.2025.
//
import Foundation
import SwiftData

@Model
final class Event {
    var title: String
    var dateTime: Date
    var timezone: Timezone?
    var eventDescription: String = ""
    
    init(title: String, dateTime: Date, timezone: Timezone? = nil, description: String = "") {
        self.title = title
        self.dateTime = dateTime
        self.timezone = timezone
        self.eventDescription = description
    }
    
    var localDateTime: Date {
        guard let timezone = timezone else { return dateTime }
        
        let sourceTimeZone = TimeZone(identifier: timezone.identifier) ?? TimeZone.current
        let targetTimeZone = TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: dateTime)
        let targetOffset = targetTimeZone.secondsFromGMT(for: dateTime)
        let timeInterval = TimeInterval(targetOffset - sourceOffset)
        
        return dateTime.addingTimeInterval(timeInterval)
    }
} 
