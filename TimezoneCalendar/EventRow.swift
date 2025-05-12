//
//  EventRow.swift
//  TimezoneCalendar
//
//  Created by Adam Vožda on 10.07.2024.
//

import SwiftUI
import SwiftData

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            if let timezone = event.timezone {
                Rectangle()
                    .fill(timezone.color)
                    .frame(width: 4)
                    .cornerRadius(2)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text(event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                        .font(.subheadline)
                    
                    if let timezone = event.timezone {
                        Text("(\(timezone.name))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(event.timezone?.color.opacity(0.1) ?? Color.clear)
        )
        .cornerRadius(8)
    }
} 