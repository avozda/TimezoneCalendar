import Foundation

extension Date {
    /// Converts a date from one timezone to another and formats it as a string
    /// - Parameters:
    ///   - sourceIdentifier: The identifier of the source timezone. If nil, current timezone is used
    ///   - destinationIdentifier: The identifier of the destination timezone
    /// - Returns: A formatted string representing the date in the destination timezone
    func convertToTimezone(from sourceIdentifier: String?, to destinationIdentifier: String) -> String {
        let sourceTimeZone = sourceIdentifier.flatMap { TimeZone(identifier: $0) } ?? TimeZone.current
        let destinationTimeZone = TimeZone(identifier: destinationIdentifier) ?? TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: self)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: self)
        let timeInterval = TimeInterval(destinationOffset - sourceOffset)
        
        let convertedDate = self.addingTimeInterval(timeInterval)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: convertedDate)
    }
    
    /// Converts a date from one timezone to another and returns the converted Date
    /// - Parameters:
    ///   - sourceIdentifier: The identifier of the source timezone. If nil, current timezone is used
    ///   - destinationIdentifier: The identifier of the destination timezone
    /// - Returns: A Date adjusted for the destination timezone
    func convertedToTimezone(from sourceIdentifier: String?, to destinationIdentifier: String) -> Date {
        let sourceTimeZone = sourceIdentifier.flatMap { TimeZone(identifier: $0) } ?? TimeZone.current
        let destinationTimeZone = TimeZone(identifier: destinationIdentifier) ?? TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: self)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: self)
        let timeInterval = TimeInterval(destinationOffset - sourceOffset)
        
        return self.addingTimeInterval(timeInterval)
    }
} 