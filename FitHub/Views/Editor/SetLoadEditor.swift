//
//  SetLoadEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/24/25.
//
import SwiftUI

struct SetLoadEditor: View {
    @EnvironmentObject var ctx: AppContext
    @Binding var load: SetLoad
    @State var localText: String = ""
    let exercise: Exercise

    var body: some View {
        switch load {
        case .none:
            // Nothing to edit visually for no-load sets
            EmptyView()

        case .weight, .distance:
            if let binding = textBinding {
                TextField(placeholder, text: binding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            
        case .band(let currentBandImpl):
            let available = ctx.equipment.implementsForExercise(exercise)
            let availableBands = available?.resistanceBands?.availableBands ?? []
            
            Menu {
                if availableBands.isEmpty {
                    // Optional: show a disabled “info” item inside the menu too
                    Text("No bands available. Check your selected equipment.")
                } else {
                    ForEach(availableBands, id: \.level) { bandImpl in
                        Button(action: {
                            load = .band(bandImpl)
                        }) {
                            HStack {
                                Text(bandImpl.level.displayName)
                                if bandImpl.level == currentBandImpl.level {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                TextField(placeholder, text: .constant(currentBandImpl.level.shortName))
                    .foregroundStyle(currentBandImpl.resolvedColor.color)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var textBinding: Binding<String>? {
        switch load {
        case .weight(let mass):
            return Binding<String>(
                get: { localText.isEmpty ? mass.fieldString : localText },
                set: { newValue in
                    let filtered = InputLimiter.filteredWeight(old: mass.fieldString, new: newValue)
                    localText = filtered
                    let val = Double(filtered) ?? 0
                    load = .weight(Mass(weight: val))
                }
            )

        case .distance(let dist):
            return Binding<String>(
                get: { localText.isEmpty ? dist.fieldString : localText },
                set: { newValue in
                    // TODO: add special filtering for distance
                    let filtered = InputLimiter.filteredWeight(old: dist.fieldString, new: newValue)
                    localText = filtered
                    let val = Double(filtered) ?? 0
                    load = .distance(Distance(distance: val))
                }
            )

        case .none, .band:
            return nil
        }
    }

    private var placeholder: String {
        switch load {
        case .weight:   return "wt."
        case .distance: return "dist."
        case .band:     return ""
        case .none:     return ""
        }
    }
}
