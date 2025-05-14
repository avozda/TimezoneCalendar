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
    @State private var viewModel: EventRowViewModel
    
    init(event: Event) {
        self.event = event
        _viewModel = State(initialValue: EventRowViewModel(event: event))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if viewModel.hasTimezone {
                Rectangle()
                    .fill(viewModel.timeColor)
                    .frame(width: 4)
                    .cornerRadius(2)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(viewModel.event.title)
                        .font(.headline)
                }
                
                HStack {
                    Text(viewModel.event.localDateTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                        .font(.subheadline)
                    
                    if let timezone = viewModel.event.timezone {
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
                .fill(viewModel.backgroundColor)
        )
        .cornerRadius(8)
    }
} 