//
//  SetMetricEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/24/25.
//
import SwiftUI

struct SetMetricEditor: View {
    @Binding var planned: SetMetric
    @Binding var showing: TimeOrSpeed.InputKey?
    let hideTOSMenu: Bool
    let load: SetLoad
    let style: TextFieldVisualStyle
    let onValidityChange: ((Bool) -> Void)?
    
    init(
        planned: Binding<SetMetric>,
        showing: Binding<TimeOrSpeed.InputKey?> = .constant(nil),
        hideTOSMenu: Bool = false,
        load: SetLoad,
        style: TextFieldVisualStyle = .rounded,
        onValidityChange: ((Bool) -> Void)? = nil,
    ) {
        _planned = planned
        _showing = showing
        self.hideTOSMenu = hideTOSMenu
        self.load = load
        self.style = style
        self.onValidityChange = onValidityChange
    }

    var body: some View {
        switch planned {
        case .reps:
            TextField("reps", text: repsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)

        case .hold:
            TimeEntryField(text: holdBinding, style: style)

        case .cardio:
            TimeSpeedField(
                tos: cardioBinding,
                showing: $showing,
                distance: load.distance ?? Distance(km: 0),
                hideMenuButton: hideTOSMenu,
                style: style
            )
        }
    }

    private var repsBinding: Binding<String> {
        Binding<String>(
            get: {
                if let r = planned.repsValue { return r > 0 ? String(r) : "" }
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
                if let ts = planned.holdTime { return ts.fieldString }
                return ""
            },
            set: { newValue in
                let ts = TimeSpan.seconds(from: newValue)
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
                if let tos = planned.timeSpeed { return tos }
                // Fallback default if planned isn’t cardio yet
                let defaultTOS = TimeOrSpeed(time: TimeSpan(seconds: 0), distance: load.distance ?? Distance(km: 0))
                return defaultTOS
            },
            set: { newValue in
                let newPlanned: SetMetric = .cardio(newValue)
                planned = newPlanned
                onValidityChange?(validate(planned: planned))
            }
        )
    }
    
    private func validate(planned: SetMetric) -> Bool {
        switch planned {
        case .reps(let r):     return r > 0
        case .hold(let t):     return t.inSeconds > 0
        case .cardio(let tos): return tos.actualValue > 0
        }
    }
}
