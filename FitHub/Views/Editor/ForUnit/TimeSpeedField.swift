//
//  TimeSpeedField.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//
import SwiftUI

struct TimeSpeedField: View {
    @Binding var tos: TimeOrSpeed
    @Binding var showing: TimeOrSpeed.InputKey?
    @State private var localText: String = ""
    let distance: Distance
    let hideMenuButton: Bool
    let style: TextFieldVisualStyle
    
    var body: some View {
        Group {
            switch showingResolved {
            case .time:
                TimeEntryField(
                    text: Binding(
                        get: { localText.isEmpty ? tos.time.fieldString : localText },
                        set: { newValue in
                            localText = newValue
                            let ts = TimeSpan.seconds(from: newValue)
                            tos.updateTime(ts, distance: distance, keyOverride: showing)
                        }
                    ),
                    style: style
                )
                .overlay(alignment: .bottomTrailing) { if !hideMenuButton { menuButton } }
  
            case .speed:
                TextField("spd.", text: Binding(
                    get: { localText.isEmpty ? tos.speed.fieldString : localText },
                    set: { newValue in
                        let filtered = InputLimiter.filteredWeight(old: tos.speed.fieldString, new: newValue)
                        localText = filtered
                        let val = Double(filtered) ?? 0
                        tos.updateSpeed(Speed(speed: val), distance: distance, keyOverride: showing)
                    }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .overlay(alignment: .bottomTrailing) { if !hideMenuButton { menuButton } }
            }
        }
        .onChange(of: distance) { _, newD in
            switch showingResolved {
            case .time:
                let speed = Speed.speedFromTime(tos.time, distance: distance)
                if speed != tos.speed { tos.speed = speed } // avoid redundant writes
            case .speed:
                let time = Speed.timeFromSpeed(tos.speed, distance: distance)
                if time != tos.time { tos.time = time } // avoid redundant writes
            }
        }
        .onChange(of: showingResolved) { _, newShowing in
            switch newShowing {
            case .time:
                let t = tos.time.fieldString
                if localText != t { localText = t }
            case .speed:
                let s = tos.speed.fieldString
                if localText != s { localText = s }
            }
        }
    }
    
    private var showingResolved: TimeOrSpeed.InputKey { showing ?? tos.showing }
    
    private var menuButton: some View {
        Menu {
            ForEach(TimeOrSpeed.InputKey.allCases, id: \.self) { key in
                Button {
                    // Unfocus the text field first
                    KeyboardManager.dismissKeyboard()
                    if showing != nil { showing = key }
                    tos.showing = key
                } label: {
                    HStack {
                        Text(key.rawValue.capitalized)
                        if showingResolved == key {
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
