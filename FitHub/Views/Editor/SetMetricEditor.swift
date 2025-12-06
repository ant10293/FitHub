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
    
    init(
        planned: Binding<SetMetric>,
        showing: Binding<TimeOrSpeed.InputKey?> = .constant(nil),
        hideTOSMenu: Bool = false,
        load: SetLoad,
        style: TextFieldVisualStyle = .rounded
    ) {
        _planned = planned
        _showing = showing
        self.hideTOSMenu = hideTOSMenu
        self.load = load
        self.style = style
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
                    }
                ),
                showing: $showing,
                distance: load.distance ?? Distance(km: 0),
                hideMenuButton: hideTOSMenu,
                style: style
            )
        }
    }
}
