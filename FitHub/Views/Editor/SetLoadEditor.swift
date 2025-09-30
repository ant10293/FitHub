//
//  SetLoadEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/24/25.
//
import SwiftUI

// FIXME: use text buffers instead of binding directly to load
/*
struct SetLoadEditor: View {
    @Binding var load: SetLoad
    
    // Optional: customize placeholders if desired
    var weightPlaceholder: String = "wt."
    var distancePlaceholder: String = "dist."
    
    // Optional: expose filtered text outwards if a parent wants to mirror it
    //var onChange: ((SetLoad) -> Void)? = nil
    
    private var textBinding: Binding<String>? {
        switch load {
        case .weight(let mass):
            return Binding<String>(
                get: {
                    mass.displayValue > 0 ? mass.displayString : ""
                },
                set: { newValue in
                    let filtered = InputLimiter.filteredWeight(old: mass.displayValue > 0 ? mass.displayString : "", new: newValue)
                    let val = Double(filtered) ?? 0
                    load = .weight(Mass(weight: val))
                   // onChange?(load)
                }
            )
            
        case .distance(let dist):
            return Binding<String>(
                get: {
                    dist.displayValue > 0 ? dist.displayString : ""
                },
                set: { newValue in
                    // Reuse weight limiter for decimals; distance uses same numeric pattern
                    let filtered = InputLimiter.filteredWeight(old: dist.displayValue > 0 ? dist.displayString : "", new: newValue)
                    let val = Double(filtered) ?? 0
                    load = .distance(Distance(distance: val))
                    //onChange?(load)
                }
            )
            
        case .none:
            return nil
        }
    }
    
    private var placeholder: String {
        switch load {
        case .weight:   return weightPlaceholder
        case .distance: return distancePlaceholder
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
*/
import SwiftUI

struct SetLoadEditor: View {
    @Binding var load: SetLoad
    @FocusState private var isFocused: Bool
    
    // Local string buffer to preserve user input while editing
    @State private var localText: String = ""
    
    // Optional: customize placeholders if desired
    var weightPlaceholder: String = "wt."
    var distancePlaceholder: String = "dist."
    
    // Optional: expose filtered text outwards if a parent wants to mirror it
    var onChange: ((SetLoad) -> Void)? = nil
    
    private var textBinding: Binding<String> {
        Binding<String>(
            get: {
                if isFocused {
                    return localText
                } else {
                    // When not focused, show formatted value from model
                    return getDisplayString()
                }
            },
            set: { newValue in
                if isFocused {
                    // While focused, just update local buffer
                    localText = newValue
                } else {
                    // When not focused, commit to model
                    commitValue(newValue)
                }
            }
        )
    }
    
    private func getDisplayString() -> String {
        switch load {
        case .weight(let mass):
            return mass.displayValue > 0 ? mass.displayString : ""
        case .distance(let dist):
            return dist.displayValue > 0 ? dist.displayString : ""
        case .none:
            return ""
        }
    }
    
    private func commitValue(_ newValue: String) {
        let filtered = InputLimiter.filteredWeight(old: localText, new: newValue)
        let val = Double(filtered) ?? 0
        
        switch load {
        case .weight:
            load = .weight(Mass(weight: val))
        case .distance:
            load = .distance(Distance(distance: val))
        case .none:
            break
        }
        onChange?(load)
    }
    
    private var placeholder: String {
        switch load {
        case .weight:   return weightPlaceholder
        case .distance: return distancePlaceholder
        case .none:     return ""
        }
    }
    
    var body: some View {
        switch load {
        case .none:
            // Nothing to edit visually for no-load sets
            EmptyView()
            
        case .weight, .distance:
            TextField(placeholder, text: textBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onChange(of: isFocused) { _, newFocus in
                    if newFocus {
                        // When gaining focus, initialize local buffer with raw value
                        localText = getDisplayString()
                    } else {
                        // When losing focus, commit changes
                        commitValue(localText)
                    }
                }
        }
    }
}
