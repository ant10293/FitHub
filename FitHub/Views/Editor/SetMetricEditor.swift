//
//  SetMetricEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/24/25.
//
import SwiftUI

struct SetMetricEditor: View {
    @Binding var planned: SetMetric
    let load: SetLoad
    var style: TextFieldVisualStyle = .rounded
    var onValidityChange: ((Bool) -> Void)? = nil
    @State private var cardioShowing: TimeOrSpeed.InputKey = .time

    var body: some View {
        switch planned {
        case .reps:
            TextField("reps", text: repsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)

        case .hold:
            TimeEntryField(text: holdBinding, style: style)

        case .cardio:
            TimeSpeedField(cardio: cardioBinding, distance: cardioDistance, style: style)
        }
    }
    
    private func validate(planned: SetMetric) -> Bool {
        switch planned {
        case .reps(let r):     return r > 0
        case .hold(let t):     return t.inSeconds > 0
        case .cardio(let tos): return tos.actualValue > 0
        }
    }

    private var repsBinding: Binding<String> {
        Binding<String>(
            get: {
                if case let .reps(r) = planned { return r > 0 ? String(r) : "" }
                return ""
            },
            set: { newValue in
                let filtered = InputLimiter.filteredReps(newValue)
                
                let r = Int(filtered) ?? 0
                let newPlanned: SetMetric = .reps(r)
                planned = newPlanned
                onValidityChange?(validate(planned: planned))
            }
        )
    }

    private var holdBinding: Binding<String> {
        Binding<String>(
            get: {
                if case let .hold(ts) = planned {
                    return ts.inSeconds > 0 ? ts.displayStringCompact : ""
                }
                return ""
            },
            set: { newValue in
                let secs = TimeSpan.seconds(from: newValue)
                
                let ts = TimeSpan(seconds: secs)
                let newPlanned: SetMetric = .hold(ts)
                planned = newPlanned
                onValidityChange?(validate(planned: planned))
            }
        )
    }
    // TODO: use text or else 0:00 will always be present
    // Cardio binding uses your TimeSpeedField component
    private var cardioBinding: Binding<TimeOrSpeed> {
        Binding<TimeOrSpeed>(
            get: {
                if case let .cardio(tos) = planned { return tos }
                // Fallback default if planned isn’t cardio yet
                let defaultTOS = TimeOrSpeed(time: TimeSpan(seconds: 0), distance: .init(distance: 0))
                return defaultTOS
            },
            set: { newValue in
                let newPlanned: SetMetric = .cardio(newValue)
                planned = newPlanned
                onValidityChange?(validate(planned: planned))
            }
        )
    }

    private var cardioDistance: Distance {
        switch load {
        case .distance(let d): return d
        default: return Distance(distance: 0)
        }
    }
}
