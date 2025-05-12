//
//  Event.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.05.2025.
//
import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable {
    case none
    case daily
    case weekly
    case monthly
}

@Model
final class Event {
    var title: String
    var dateTime: Date
    var timezone: Timezone?
    var eventDescription: String = ""
    
    // Recurrence properties
    var recurrenceFrequency: RecurrenceFrequency? = RecurrenceFrequency.none
    var recurrenceEndDate: Date?
    var recurrenceCount: Int = 0 // 0 means no limit based on count
    
    init(title: String, dateTime: Date, timezone: Timezone? = nil, description: String = "", 
         recurrenceFrequency: RecurrenceFrequency? = nil, recurrenceEndDate: Date? = nil, recurrenceCount: Int = 0) {
        self.title = title
        self.dateTime = dateTime
        self.timezone = timezone
        self.eventDescription = description
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceEndDate = recurrenceEndDate
        self.recurrenceCount = recurrenceCount
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
    
    var isRecurring: Bool {
        return recurrenceFrequency != nil
    }
    
    func occurrenceDates(from startDate: Date, to endDate: Date) -> [Date] {
        guard isRecurring else { return [dateTime] }
        
        let calendar = Calendar.current
        var dates: [Date] = []
        var currentDate = dateTime
        var count = 0
        
        // Check if first event is within date range
        if currentDate >= startDate && currentDate <= endDate {
            dates.append(currentDate)
            count += 1
        }
        
        // If there's a recurrence count limit and we've hit it, return
        if recurrenceCount > 0 && count >= recurrenceCount {
            return dates
        }
        
        while currentDate <= endDate {
            var nextDate: Date?
            guard let recurrenceFrequency = recurrenceFrequency else {
                return dates
            }
            
            switch recurrenceFrequency {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate)
            case .none:
                return dates
            }
            
            guard let next = nextDate else { break }
            currentDate = next
            
            // Check if we've reached the recurrence end date
            if let recurrenceEndDate = recurrenceEndDate, currentDate > recurrenceEndDate {
                break
            }
            
            // Add date if it's in our search range
            if currentDate >= startDate && currentDate <= endDate {
                dates.append(currentDate)
                count += 1
            }
            
            // Check recurrence count limit
            if recurrenceCount > 0 && count >= recurrenceCount {
                break
            }
        }
        
        return dates
    }
} 
