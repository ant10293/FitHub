//
//  ExerciseSetDisplay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseSetDisplay: View {
    @Environment(\.colorScheme) var colorScheme
    let timerManager: TimerManager
    @State private var showTimer: Bool = false
    @Binding var setDetail: SetDetail
    @Binding var shouldDisableNext: Bool
    @Binding var showPicker: Bool

    // Local editable buffers
    @State private var weightInput: String = ""
    @State private var plannedInput: String = ""
    @State private var completedMetric: SetMetric = .reps(0)
    @State private var rpeLocal: Double = 1.0
        
    var exercise: Exercise
    var saveTemplate: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            // ── Top line (label + inputs) – visuals unchanged ───────────────
            if !showPicker {
                HStack {
                    setLabel
                    // Weight input (unchanged)
                    weightSection
                    
                    // Metric input (reps or hold) – same visual container as reps
                    metricSection
                }
                .padding(.horizontal, -20)
                .padding(.bottom)
            }

            completedEntry
            
            if !showPicker {
                // ── RPE slider (skip for warmups) – unchanged ────────────────
                rpeEntry
            }
        }
        .padding()
        .onAppear(perform: resetInputs)
        .onChange(of: exercise) { oldValue, newValue in
            // if exercise has changed or moved to next set
            if oldValue.id != newValue.id || oldValue.currentSet != newValue.currentSet {
                saveTemplate()
                resetInputs()
            }
        }
        .sheet(isPresented: $showTimer) {
            if let hold = setDetail.planned.holdTime?.inSeconds {
                IsometricTimerRing(
                    manager: timerManager,
                    holdSeconds: hold,
                    onCompletion: { seconds in
                        showTimer = false
                        let ts = TimeSpan(seconds: seconds)
                        setDetail.completed = .hold(ts)
                        completedMetric = .hold(ts)
                    }
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ViewBuilder private var setLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            if exercise.isWarmUp {
                Text("warmup")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("Set \(setDetail.setNumber):")
                .fontWeight(.bold)
        }
    }

    @ViewBuilder private var weightSection: some View {
        if exercise.type.usesWeight {
            ZStack {
                //let weightText = $setDetail.weight.asText()
                let weightText: Binding<String> = Binding(
                    get: { weightInput },
                    set: { newText in
                        weightInput = newText
                        let val = Double(newText) ?? 0
                        setDetail.weight.set(val)   // commits in user’s selected unit
                    }
                )
                
                let width = calculateTextWidth(text: weightText.wrappedValue, minWidth: 60, maxWidth: 90)
                let isZero = (weightText.wrappedValue == "0")

                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark
                          ? Color(UIColor.systemGray4)
                          : Color(UIColor.secondarySystemBackground))
                    .frame(width: width, height: 35)

                TextField("wt.", text: weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isZero ? .red : .primary)
                    .frame(width: width, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(UnitSystem.current.weightUnit).bold()

                if let weightInstruction = exercise.weightInstruction {
                    Text(weightInstruction.rawValue)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.trailing, 2.5)
        }
    }
    
    @ViewBuilder private var metricSection: some View {
        switch setDetail.planned {
        case .reps:
            repsInputField
            VStack(alignment: .leading) {
                Text("Reps").bold()
                if let repsInstruction = exercise.repsInstruction {
                    Text(repsInstruction.rawValue)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(alignment: .trailing)
                }
            }

        case .hold:
            holdInputField   // same ZStack look as reps
            VStack(alignment: .leading) {
                RectangularButton(
                    title: "Start",
                    systemImage: "play.fill",
                    enabled: (setDetail.planned.holdTime?.inSeconds ?? 0) > 0,
                    color: .green,
                    width: .fit,
                    action: {
                        showTimer = true
                    }
                )
                .clipShape(.capsule)
                //Text("Time").bold()
            }
        }
    }
    
    @ViewBuilder private var completedEntry: some View {
        // ── Completed line – keep the row + paddings identical ─────────
        switch setDetail.planned {
        case .reps(let plannedReps):
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

        case .hold(let plannedTime):
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
    }
    
    @ViewBuilder private var rpeEntry: some View {
        if !exercise.isWarmUp {
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

    // MARK: - Subviews (visuals match original)

    private var repsInputField: some View {
        ZStack {
            let width  = calculateTextWidth(text: plannedInput, minWidth: 45, maxWidth: 70)
            let isZero = plannedInput == "0"

            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray4)
                      : Color(UIColor.secondarySystemBackground))
                .frame(width: width, height: 35)

            TextField("reps", text: Binding<String>(
                get: { plannedInput },
                set: { newValue in
                    let filtered = InputLimiter.filteredReps(newValue)
                    let r = Int(filtered) ?? 0
                    let reps: SetMetric = .reps(r)
                    plannedInput = filtered
                    setDetail.planned = reps
                    completedMetric = reps
                    validateSetMetric(actual: r)
                })
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .foregroundStyle(isZero ? .red : .primary)
            .frame(width: width, alignment: .center)
        }
    }

    // this actually needs to be a string to be formatted properly
    @ViewBuilder private var holdInputField: some View {
        ZStack {
            let width  = calculateTextWidth(text: plannedInput, minWidth: 60, maxWidth: 90)
            let isZero = TimeSpan.seconds(from: plannedInput) == 0

            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray4)
                      : Color(UIColor.secondarySystemBackground))
                .frame(width: width, height: 35)

            // Planned hold using your fixed-mask field (m:ss)
            TimeEntryField(text: Binding(
                get: { plannedInput },
                set: { newValue in
                    let s = TimeSpan.seconds(from: newValue)
                    let ts = TimeSpan.init(seconds: s)
                    let hold: SetMetric = .hold(ts)
                    plannedInput = ts.displayStringCompact
                    setDetail.planned = hold
                    completedMetric = hold
                    validateSetMetric(actual: s)
                }),
                style: .plain
            )
            .foregroundStyle(isZero ? .red : .primary)
            .frame(width: width, alignment: .center)
        }
    }
    // MARK: - Helpers

    private func resetInputs() {
        initializeVariables()
        validateNextButton()
    }
    
    private func initializeVariables() {
        rpeLocal = setDetail.rpe ?? 1
        weightInput = setDetail.weightFieldString
        plannedInput = setDetail.metricFieldString

        switch setDetail.planned {
        case .reps(let plannedReps):
            completedMetric = .reps(setDetail.completed?.repsValue ?? plannedReps)

        case .hold(let plannedTime):
            let plannedSec = plannedTime.inSeconds
            completedMetric = .hold(TimeSpan(seconds: setDetail.completed?.holdTime?.inSeconds ?? plannedSec))
        }
    }

    private func validateNextButton() {
        switch setDetail.planned {
        case .reps(let r): validateSetMetric(actual: r)
        case .hold(let t): validateSetMetric(actual: t.inSeconds)
        }
    }
    
    private func validateSetMetric(actual: Int) {
        shouldDisableNext = actual <= 0 || (exercise.type.usesWeight && setDetail.weight.inKg <= 0)
    }
}
