//
//  TimeSpeedField.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//
import SwiftUI

struct TimeSpeedField: View {
    @Binding var cardio: TimeOrSpeed
    @State private var localText: String = ""
    let distance: Distance
    let style: TextFieldVisualStyle
    
    var body: some View {
        Group {
            switch cardio.showing {
            case .time:
                TimeEntryField(
                    text: Binding(
                        get: { !localText.isEmpty ? localText : (cardio.time.inSeconds > 0 ? cardio.time.displayStringCompact : "") },
                        set: { newValue in
                            localText = newValue
                            
                            let secs = TimeSpan.seconds(from: newValue)
                            cardio.updateTime(TimeSpan(seconds: secs), distance: distance)
                        }
                    ),
                    style: style
                )
                .overlay(alignment: .bottomTrailing) { menuButton }
                
            case .speed:
                TextField("spd.", text: Binding(
                    get: { !localText.isEmpty ? localText : (cardio.speed.inKmH > 0 ? cardio.speed.displayString : "") },
                    set: { newValue in
                        // TODO: add special filtering for speed
                        let filtered = InputLimiter.filteredWeight(old: cardio.speed.inKmH > 0 ? cardio.speed.displayString : "", new: newValue)
                        localText = filtered
                        
                        let val = Double(filtered) ?? 0
                        cardio.updateSpeed(Speed(speed: val), distance: distance)
                    }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .overlay(alignment: .bottomTrailing) { menuButton }
            }
        }
        .onChange(of: cardio.showing) { localText = "" }
    }
    
    private var menuButton: some View {
        Menu {
            ForEach(TimeOrSpeed.InputKey.allCases, id: \.self) { key in
                Button {
                    // Unfocus the text field first
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    cardio.showing = key
                } label: {
                    HStack {
                        Text(key.rawValue.capitalized)
                        if cardio.showing == key {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.2.circlepath")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
        .offset(x: 8, y: 8)
    }
}
