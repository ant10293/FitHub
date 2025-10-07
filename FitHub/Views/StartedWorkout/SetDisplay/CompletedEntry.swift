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
    let planned: SetMetric
    @Binding var showPicker: Bool
    @Binding var completed: SetMetric
    @Binding var rpe: Double
    
    var body: some View {
        switch planned {
        case .reps(let plannedReps):
            repsField(plannedReps: plannedReps)
            
        case .hold(let plannedTime):
            holdField(plannedTime: plannedTime)
            
        case .cardio(let plannedTOS):
            cardioField(plannedTOS: plannedTOS)
        }
        
        if !showPicker, !hideRPE {
            rpeEntry
        }
    }
    
    @ViewBuilder private func repsField(plannedReps: Int) -> some View {
        let completedLocal = completed.repsValue ?? plannedReps
        let completedBinding = Binding<Int>(
            get: { completedLocal },
            set: { newValue in
                let newMetric = SetMetric.reps(newValue)
                completed = newMetric
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
                let newMetric = SetMetric.hold(newValue)
                completed = newMetric
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
                // FIXME: this isnt right. we shouldnt update with a value of 0
                newTOS.updateTime(newValue, distance: Distance(distance: 0)) // or get from setDetail.load
                let newMetric = SetMetric.cardio(newTOS)
                completed = newMetric
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
                (Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpe)))
                    .overlay(alignment: .bottom) {
                        Text("(1 - 10)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(y: 15)
                    }

                Slider(value: Binding(
                    get: { rpe },
                    set: { rpe = $0 }
                ), in: 1...10, step: 0.5)
                .padding(.horizontal)
            }
        }
    }
}


/*
struct CompletedEntry: View {
    let isWarm: Bool
    let hideRPE: Bool
    let planned: SetMetric
    @Binding var completed: SetMetric
    @Binding var showPicker: Bool
    @Binding var rpe: Double
    
    @State private var localReps: Int = 0
    @State private var localTime: TimeSpan = .init(seconds: 0)
    
    // Closures for updates
    let onCompletedChange: (SetMetric) -> Void
    let onRpeChange: (Double) -> Void
    
    var body: some View {
        Group {
            switch planned {
            case .reps(let plannedReps):
                repsField(plannedReps: plannedReps)
                
            case .hold(let plannedTime):
                holdField(plannedTime: plannedTime)
                
            case .cardio(let plannedTOS):
                cardioField(plannedTOS: plannedTOS)
            }
            
            if !showPicker, !hideRPE {
                rpeEntry
            }
        }
        .onAppear(perform: syncLocal)
    }
    
    @ViewBuilder private func repsField(plannedReps: Int) -> some View {
        let completedBinding = Binding<Int>(
            get: { localReps },
            set: { newValue in
                localReps = newValue
                let newMetric = SetMetric.reps(newValue)
                onCompletedChange(newMetric)
            }
        )
        
        HStack {
            Text("Reps Completed:").fontWeight(.bold)
            Spacer()
            Text(" \(localReps) ")
                .foregroundStyle(localReps < plannedReps ? .red :
                                    (localReps > plannedReps ? .green : .primary))
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
        let completedBinding = Binding<TimeSpan>(
            get: { localTime },
            set: { newValue in
                localTime = newValue
                let newMetric = SetMetric.hold(newValue)
                onCompletedChange(newMetric)
            }
        )
        
        timeCompletedField(planned: plannedTime, timeBinding: $localTime)
    }
    
    @ViewBuilder private func cardioField(plannedTOS: TimeOrSpeed) -> some View {
        let completedBinding = Binding<TimeSpan>(
            get: { localTime },
            set: { newValue in
                localTime = newValue
                var newTOS = plannedTOS
                // FIXME: this isnt right. we shouldnt update with a value of 0
                newTOS.updateTime(newValue, distance: Distance(distance: 0)) // or get from setDetail.load
                let newMetric = SetMetric.cardio(newTOS)
                onCompletedChange(newMetric)
            }
        )
        
        timeCompletedField(planned: plannedTOS.time, timeBinding: $localTime)
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
                (Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpe)))
                    .overlay(alignment: .bottom) {
                        Text("(1 - 10)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(y: 15)
                    }

                Slider(value: Binding(
                    get: { rpe },
                    set: { newValue in
                        rpe = newValue
                        onRpeChange(newValue)
                    }
                ), in: 1...10, step: 0.5)
                .padding(.horizontal)
            }
        }
    }
    
    private func syncLocal() {
        switch planned {
        case .reps(let plannedReps):
            localReps = completed.repsValue ?? plannedReps
        case .hold(let plannedTime):
            localTime = completed.holdTime ?? plannedTime
        case .cardio(let plannedTOS):
            localTime = completed.timeSpeed?.time ?? plannedTOS.time
        }
    }
}
*/
