//
//  TimeSpeedField.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import SwiftUI

struct TimeSpeedField: View {
    @Binding var cardio: TimeOrSpeed
    let distance: Distance
    
    var body: some View {
        HStack {
            // Text field based on current input key
            Group {
                switch cardio.showing {
                case .time:
                    TimeEntryField(
                        text: Binding(
                            get: { cardio.time.displayStringCompact },
                            set: { newValue in
                                let secs = TimeSpan.seconds(from: newValue)
                                cardio.updateTime(TimeSpan(seconds: secs), distance: distance)
                            }
                        ),
                        placeholder: "0:00"
                    )
                case .speed:
                    TextField("0.0", text: Binding(
                        get: { String(cardio.speed.displayValue) },
                        set: { newValue in
                            if let speedValue = Double(newValue) {
                                var newSpeed = cardio.speed
                                newSpeed.setDisplay(speedValue)
                                cardio.updateSpeed(newSpeed, distance: distance)
                            }
                        }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                }
            }
            
            // Menu picker button
            Menu {
                Button("Time") {
                    cardio.showing = .time
                }
                Button("Speed") {
                    cardio.showing = .speed
                }
            } label: {
                HStack(spacing: 4) {
                    Text(cardio.showing.rawValue.capitalized)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
            }
        }
    }
}
