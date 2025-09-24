//
//  ExerciseSetDisplay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


// FIXME: this view is too long and disorganized. too much reused logic
struct ExerciseSetDisplay: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var setDetail: SetDetail
    @Binding var shouldDisableNext: Bool
    @Binding var showPicker: Bool

    @State private var showTimer: Bool = false
    @State private var weightInput: String = ""
    @State private var plannedInput: String = ""
    @State private var completedMetric: SetMetric = .reps(0)
    @State private var rpeLocal: Double = 1.0
    
    let timerManager: TimerManager
    let hideRPE: Bool
    let exercise: Exercise
    let load: SetLoad
    let metric: SetMetric
    let saveTemplate: () -> Void
    
    init(
        setDetail: Binding<SetDetail>,
        shouldDisableNext: Binding<Bool>,
        showPicker: Binding<Bool>,
        timerManager: TimerManager,
        hideRPE: Bool,
        exercise: Exercise,
        saveTemplate: @escaping () -> Void
    ) {
        _setDetail = setDetail
        _shouldDisableNext = shouldDisableNext
        _showPicker = showPicker
        self.timerManager = timerManager
        self.hideRPE = hideRPE
        self.exercise = exercise
        self.saveTemplate = saveTemplate
        self.load = exercise.getLoadMetric(metricValue: 0)
        self.metric = exercise.getPlannedMetric(value: 0)
    }

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

            CompletedEntry(
                isWarm: exercise.isWarmUp,
                hideRPE: hideRPE,
                completedMetric: $completedMetric,
                setDetail: $setDetail,
                showPicker: $showPicker,
                rpeLocal: $rpeLocal
            )
        }
        .padding()
        .onAppear(perform: resetInputs)
        // TODO: test with setDetail changes
        .onChange(of: exercise) { oldValue, newValue in
            // if exercise has changed or moved to next set
            if oldValue.id != newValue.id || oldValue.currentSet != newValue.currentSet {
                saveTemplate()
                resetInputs()
            }
        }
        .sheet(isPresented: $showTimer) {
            // TODO: should also work with cardio based exercises
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
        if load != .none {
            let width = calculateTextWidth(text: weightInput, minWidth: 60, maxWidth: 90)
            let isZero = weightInput == "0"
            
            let weightText: Binding<String> = Binding(
                get: { weightInput },
                set: { newText in
                    weightInput = newText
                    let val = Double(newText) ?? 0
                    
                    switch setDetail.load {
                    case .weight:
                        setDetail.load = .weight(Mass(weight: val))
                    case .distance:
                        setDetail.load = .distance(Distance(distance: val))
                    case .none:
                        break
                    }
                }
            )
           
            FieldChrome(width: width, isZero: isZero) {
                TextField("wt.", text: weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(load.label).bold()
                if let weightInstruction = exercise.weightInstruction {
                    Text(weightInstruction.rawValue)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.trailing, 2.5)
        }
    }
    
    @ViewBuilder private var repsInputField: some View {
        let width  = calculateTextWidth(text: plannedInput, minWidth: 45, maxWidth: 70)
        let isZero = plannedInput == "0"
        
        let repText: Binding<String> = Binding(
            get: { plannedInput },
            set: { newValue in
                let filtered = InputLimiter.filteredReps(newValue)
                let r = Int(filtered) ?? 0
                let reps: SetMetric = .reps(r)
                plannedInput = filtered
                setDetail.planned = reps
                completedMetric = reps
                validateSetMetric(actual: Double(r))
            }
        )

        FieldChrome(width: width, isZero: isZero) {
            TextField("reps", text: repText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
        }
    }

    // this actually needs to be a string to be formatted properly
    @ViewBuilder private var holdInputField: some View {
        let width  = calculateTextWidth(text: plannedInput, minWidth: 60, maxWidth: 90)
        let isZero = TimeSpan.seconds(from: plannedInput) == 0
        
        // Planned hold using your fixed-mask field (m:ss)
        let timeText: Binding<String> = Binding(
            get: { plannedInput },
            set: { newValue in
                let s = TimeSpan.seconds(from: newValue)
                let ts = TimeSpan.init(seconds: s)
                let hold: SetMetric = .hold(ts)
                plannedInput = ts.displayStringCompact
                setDetail.planned = hold
                completedMetric = hold
                validateSetMetric(actual: Double(s))
            }
        )

        FieldChrome(width: width, isZero: isZero) {
            TimeEntryField(text: timeText, style: .plain)
        }
    }
    
    /*
    @ViewBuilder private var cardioInputField: some View {
        let width  = calculateTextWidth(text: plannedInput, minWidth: 60, maxWidth: 90)
        let isZero = TimeSpan.seconds(from: plannedInput) == 0
        
        FieldChrome(width: width, isZero: isZero) {
            //TimeSpeedField(cardio:, distance: <#T##Distance#>)
        }
    }
    */
    
    @ViewBuilder private var metricSection: some View {
        switch setDetail.planned {
        case .reps:
            repsInputField

        case .hold:
            holdInputField   // same ZStack look as reps
            /*
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
            */
        //case .cardio: cardioInputField
        }
        VStack(alignment: .leading) {
            Text(metric.label).bold()
            if let repsInstruction = exercise.repsInstruction {
                Text(repsInstruction.rawValue)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .frame(alignment: .trailing)
            }
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
            completedMetric = .hold(TimeSpan(seconds: setDetail.completed?.holdTime?.inSeconds ?? plannedTime.inSeconds))
           
        /*
        case .cardio(let timeSpeed):
            completedMetric = .cardio(TimeOrSpeed(speed: timeSpeed.speed, distance: load.distance ?? .init(distance: 0)))
        */
        }
    }

    private func validateNextButton() {
        switch setDetail.planned {
        case .reps(let r): validateSetMetric(actual: Double(r))
        case .hold(let t): validateSetMetric(actual: Double(t.inSeconds))
        //case .cardio(let ts): validateSetMetric(actual: ts.actualValue)
        }
    }
    
    private func validateSetMetric(actual: Double) {
        shouldDisableNext = actual <= 0 || (setDetail.load != .none && setDetail.load.actualValue <= 0)
    }
}

