//
//  DateHelpers.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 13.05.2025.
//
import Foundation

extension Date {
    // Convert date to string in a specific timezone
    func convertToTimezoneString(from sourceIdentifier: String?, to destinationIdentifier: String) -> String {
        let converted = convertedToTimezone(from: sourceIdentifier, to: destinationIdentifier)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: converted)
    }
    
    // Convert date to date in a specific timezone
    func convertedToTimezone(from sourceIdentifier: String?, to destinationIdentifier: String) -> Date {
        let sourceTimeZone = sourceIdentifier.flatMap { TimeZone(identifier: $0) } ?? TimeZone.current
        let destinationTimeZone = TimeZone(identifier: destinationIdentifier) ?? TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: self)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: self)
        let timeInterval = TimeInterval(destinationOffset - sourceOffset)
        
        return self.addingTimeInterval(timeInterval)
    }
} 
