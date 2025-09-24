//
//  CompletedEntry.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import SwiftUI

struct CompletedEntry: View {
    let isWarm: Bool
    let hideRPE: Bool
    @Binding var completedMetric: SetMetric
    @Binding var setDetail: SetDetail
    @Binding var showPicker: Bool
    @Binding var rpeLocal: Double
    
    var body: some View {
        switch setDetail.planned {
        case .reps(let plannedReps):
            repsField(plannedReps: plannedReps)
            
        case .hold(let plannedTime):
            holdField(plannedTime: plannedTime)
            
        //case .cardio(let ts):
        }
        
        if !showPicker, !hideRPE {
            rpeEntry
        }
    }
    
    @ViewBuilder private func repsField(plannedReps: Int) -> some View {
        let completed = completedMetric.repsValue ?? plannedReps
        let completedBinding = Binding<Int>(
            get: { completed },
            set: { newValue in
                completedMetric = .reps(newValue)
                setDetail.completed = .reps(newValue)
            }
        )
        
        HStack {
            Text("Reps Completed: ").fontWeight(.bold)
            Spacer()
            Text("\(completed) ")
                .foregroundStyle(completed < plannedReps ? .red :
                                    (completed > plannedReps ? .green : .primary))
            Spacer()
            
            Stepper(
                "",
                value: completedBinding,
                in: 0...(max(1, plannedReps) * 5),
                step: 1
            )
            .labelsHidden()
        }
    }
    
    @ViewBuilder private func holdField(plannedTime: TimeSpan) -> some View {
        let completed = completedMetric.holdTime ?? plannedTime
        let completedBinding = Binding<TimeSpan>(
            get: { completed },
            set: { newValue in
                completedMetric = .hold(newValue)
                setDetail.completed = .hold(newValue)
            }
        )
        
        TappableDisclosure(isExpanded: $showPicker) {
            // LABEL
            HStack {
                Text("Time Completed: ").fontWeight(.bold)
                Spacer()
                Text("\(completed.displayString) ")
                    .foregroundStyle(completed.inSeconds < plannedTime.inSeconds ? .red :
                                        (completed.inSeconds > plannedTime.inSeconds ? .green : .primary))
                Spacer()
            }
        } content: {
            VStack {
                // CONTENT
                MinSecPicker(time: completedBinding)
                
                HStack {
                    Spacer()
                    FloatingButton(image: "checkmark", action: { showPicker = false })
                        .padding()
                }
                .padding(.top, 6)
            }
        }
        .padding(.trailing)
    }
    
    @ViewBuilder private var rpeEntry: some View {
        if !isWarm {
            HStack(spacing: 0) {
                (Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpeLocal)))
                    .overlay(alignment: .bottom) {
                        Text("(1 - 10)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(y: 15)
                    }

                Slider(value: Binding(
                    get: { rpeLocal },
                    set: { newValue in
                        rpeLocal = newValue
                        setDetail.rpe = newValue
                    }
                ), in: 1...10, step: 0.5)
                .padding(.horizontal)
            }
        }
    }
}
