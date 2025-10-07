//
//  SetLoadEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/24/25.
//
import SwiftUI

struct SetLoadEditor: View {
    @Binding var load: SetLoad
    @State var localText: String = ""
    
    private var textBinding: Binding<String>? {
        switch load {
        case .weight(let mass):
            return Binding<String>(
                get: { !localText.isEmpty ? localText : (mass.inKg > 0 ? mass.displayString : "") },
                set: { newValue in
                    let filtered = InputLimiter.filteredWeight(old: mass.inKg > 0 ? mass.displayString : "", new: newValue)
                    localText = filtered
                    
                    let val = Double(filtered) ?? 0
                    load = .weight(Mass(weight: val))
                }
            )
            
        case .distance(let dist):
            return Binding<String>(
                get: { !localText.isEmpty ? localText : (dist.inKm > 0 ? dist.displayString : "") },
                set: { newValue in                    
                    // TODO: add special filtering for distance
                    let filtered = InputLimiter.filteredWeight(old: dist.inKm > 0 ? dist.displayString : "", new: newValue)
                    localText = filtered
                    
                    let val = Double(filtered) ?? 0
                    load = .distance(Distance(distance: val))
                }
            )
            
        case .none:
            return nil
        }
    }
    
    private var placeholder: String {
        switch load {
        case .weight:   return "wt."
        case .distance: return "dist."
        case .none:     return ""
        }
    }
    
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
        }
    }
}
