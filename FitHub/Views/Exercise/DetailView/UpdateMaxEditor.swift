//
//  UpdateMax.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct UpdateMaxEditor: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var peak: PeakMetric
    @State private var plannedDate: Date?
    let exercise: Exercise
    let onSave: (PeakMetric, Date?) -> Void
    let onCancel: () -> Void
    
    init(exercise: Exercise, onSave: @escaping (PeakMetric, Date?) -> Void, onCancel: @escaping () -> Void) {
        self.exercise = exercise
        self.peak = exercise.getPeakMetric(metricValue: 0)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        GenericEditWrapper(
            title: "Update \(exercise.performanceTitle(includeInstruction: false))",
            onSave: {
                onSave(peak, plannedDate)
            },
            onCancel: {
                onCancel()
            },
            content: { focus in
                NewPeakEntry(newPeak: $peak, focus: focus)
            },
            additionalContent: {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { plannedDate ?? Date() },
                        set: { plannedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.horizontal)
            }
        )
    }
}

private struct NewPeakEntry: View {
    @Binding var newPeak: PeakMetric
    @State private var localText: String = ""
    let focus: FocusState<Bool>.Binding   // <<< receive focus
    
    var body: some View {
        Group {
            switch newPeak {
            case .oneRepMax, .maxReps, .hold30sLoad:
                if let binding = textBinding {
                    TextField(newPeak.placeholder, text: binding)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused(focus) 
                }
                
            case .maxHold:
                if let binding = textBinding {
                    TimeEntryField(text: binding, placeholder: newPeak.placeholder, style: .plain)
                        .focused(focus)
                }
                
            case .none:
                EmptyView()
            }
        }
    }

    private var textBinding: Binding<String>? {
        switch newPeak {
        case .oneRepMax(let mass):
            return Binding<String>(
                get: { localText.isEmpty ? mass.fieldString : localText },
                set: { newValue in
                    let filtered = InputLimiter.filteredWeight(old: mass.fieldString, new: newValue)
                    localText = filtered
                    let val = Double(filtered) ?? 0
                    newPeak = .oneRepMax(Mass(weight: val))
                }
            )
            
        case .maxReps(let r):
            return Binding<String>(
                get: { localText.isEmpty ? (r > 0 ? String(r) : "") : localText  },
                set: { newValue in
                    let filtered = InputLimiter.filteredReps(newValue)
                    localText = filtered
                    let val = Int(filtered) ?? 0
                    newPeak = .maxReps(val)
                }
            )
        
        case .maxHold(let h):
            return Binding<String>(
                get: { localText.isEmpty ? h.fieldString: localText },
                set: { newValue in
                    localText = newValue
                    let ts = TimeSpan.seconds(from: newValue)
                    newPeak = .maxHold(ts)
                }
            )
            
        case .hold30sLoad(let h30l):
            return Binding<String>(
                get: { h30l.fieldString },
                set: { newValue in
                    let filtered = InputLimiter.filteredWeight(old: h30l.fieldString, new: newValue)
                    localText = filtered
                    let val = Double(filtered) ?? 0
                    newPeak = .hold30sLoad(Mass(weight: val))
                }
            )
            
        case .none:
            return nil
        }
    }
}


