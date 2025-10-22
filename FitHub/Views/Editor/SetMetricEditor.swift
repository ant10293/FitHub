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
    @State private var localText: String = ""
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
        case .reps(let r):
            TextField("reps", text: Binding<String>(
                get: { localText.isEmpty ? (r > 0 ? String(r) : "") : localText },
                set: { newValue in
                    let filtered = InputLimiter.filteredReps(newValue)
                    localText = filtered
                    let r = Int(filtered) ?? 0
                    let newPlanned: SetMetric = .reps(r)
                    planned = newPlanned
                    onValidityChange?(validate(planned: planned))
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)

        case .hold(let t):
            TimeEntryField(
                text: Binding<String>(
                    get: { return localText.isEmpty ? t.fieldString : localText },
                    set: { newValue in
                        localText = newValue
                        let ts = TimeSpan.seconds(from: newValue)
                        let newPlanned: SetMetric = .hold(ts)
                        planned = newPlanned
                        onValidityChange?(validate(planned: planned))
                    }
                ),
                style: style
            )

        case .cardio(let tos):
            TimeSpeedField(
                tos: Binding<TimeOrSpeed>(
                    get: { return tos },
                    set: { newValue in
                        let newPlanned: SetMetric = .cardio(newValue)
                        planned = newPlanned
                        onValidityChange?(validate(planned: planned))
                    }
                ),
                showing: $showing,
                distance: load.distance ?? Distance(km: 0),
                hideMenuButton: hideTOSMenu,
                style: style
            )
        }
    }

    private func validate(planned: SetMetric) -> Bool {
        switch planned {
        case .reps(let r):     return r > 0
        case .hold(let t):     return t.inSeconds > 0
        case .cardio(let tos): return tos.actualValue > 0
        }
    }
}
