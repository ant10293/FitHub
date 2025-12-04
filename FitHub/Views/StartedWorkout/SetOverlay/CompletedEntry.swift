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
    let hideCompleted: Bool
    let planned: SetMetric
    @Binding var showPicker: Bool
    @Binding var completed: SetMetric
    @Binding var rpe: Double
    
    private var isCardio: Bool { planned.timeSpeed != nil }
    
    var body: some View {
        if !hideCompleted {
            switch planned {
            case .reps(let plannedReps):
                repsField(plannedReps: plannedReps)
                
            case .hold(let plannedTime):
                holdField(plannedTime: plannedTime)
                
            case .cardio(let plannedTOS):
                cardioField(plannedTOS: plannedTOS)
            }
        }
        
        if !showPicker, !hideRPE, !isCardio {
            rpeEntry
        }
    }
    
    @ViewBuilder private func repsField(plannedReps: Int) -> some View {
        let completedLocal = completed.repsValue ?? plannedReps
        let completedBinding = Binding<Int>(
            get: { completedLocal },
            set: { newValue in
                completed = SetMetric.reps(newValue)
            }
        )
        
        HStack {
            Text("Reps Completed:").fontWeight(.bold)
            Spacer()
            Text(" \(completedLocal) ")
                .foregroundStyle(completedLocal < plannedReps ? .red :
                                    (completedLocal > plannedReps ? .green : .primary))
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
        let completedLocal = completed.holdTime ?? plannedTime
        let completedBinding = Binding<TimeSpan>(
            get: { completedLocal },
            set: { newValue in
                completed = SetMetric.hold(newValue)
            }
        )
        
        timeCompletedField(planned: plannedTime, timeBinding: completedBinding)
    }
    
    @ViewBuilder private func cardioField(plannedTOS: TimeOrSpeed) -> some View {
        let completedLocal = completed.timeSpeed?.time ?? plannedTOS.time
        let completedBinding = Binding<TimeSpan>(
            get: { completedLocal },
            set: { newValue in
                var newTOS = plannedTOS
                newTOS.updateTime(newValue, distance: Distance(km: 0)) // or get from setDetail.load
                completed = SetMetric.cardio(newTOS)
            }
        )
        
        timeCompletedField(planned: plannedTOS.time, timeBinding: completedBinding)
    }
    
    // MARK: - Reusable time field (accepts a Binding directly)
    @ViewBuilder
    private func timeCompletedField(
        title: String = "Time Completed:",
        planned: TimeSpan,
        timeBinding: Binding<TimeSpan>
    ) -> some View {

        TappableDisclosure(isExpanded: $showPicker) {
            HStack {
                Text(title).fontWeight(.bold)
                Spacer()
                let actual = timeBinding.wrappedValue
                Text(" \(actual.displayString) ")
                    .foregroundStyle(
                        actual.inSeconds < planned.inSeconds ? .red :
                        (actual.inSeconds > planned.inSeconds ? .green : .primary)
                    )
                Spacer()
            }
        } content: {
            VStack {
                MinSecPicker(time: timeBinding)
                HStack {
                    Spacer()
                    FloatingButton(image: "checkmark") { showPicker = false }
                }
            }
        }
    }
    
    @ViewBuilder private var rpeEntry: some View {
        if !isWarm {
            HStack(spacing: 0) {
                (Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpe)))
                    .overlay(alignment: .bottom) {
                        Text("(1 - 10)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(y: screenHeight * 0.01875)
                    }

                Slider(
                    value: Binding(
                        get: { rpe },
                        set: { rpe = $0 }
                    ),
                    in: 1...10, step: 0.5
                )
                .padding(.horizontal)
            }
        }
    }
}

