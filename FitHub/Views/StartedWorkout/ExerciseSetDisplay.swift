//
//  ExerciseSetDisplay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct ExerciseSetDisplay: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var setDetail: SetDetail
    @Binding var shouldDisableNext: Bool

    // Local editable buffers
    @State private var repInput: String
    @State private var repsLocal: Int

    @State private var holdInput: String
    @State private var holdLocal: TimeSpan

    @State private var rpeLocal: Double = 1.0

    var exercise: Exercise
    var saveTemplate: () -> Void

    // MARK: - Init
    init(
        setDetail: Binding<SetDetail>,
        shouldDisableNext: Binding<Bool>,
        exercise: Exercise,
        saveTemplate: @escaping () -> Void
    ) {
        _setDetail         = setDetail
        _shouldDisableNext = shouldDisableNext
        self.exercise      = exercise
        self.saveTemplate  = saveTemplate

        switch setDetail.wrappedValue.planned {
        case .reps(let plannedReps):
            _repInput  = State(initialValue: plannedReps > 0 ? String(plannedReps) : "")
            _repsLocal = State(initialValue: plannedReps)

            _holdInput = State(initialValue: "")
            _holdLocal = State(initialValue: TimeSpan(seconds: 0))

        case .hold(let plannedTime):
            let plannedSec = plannedTime.inSeconds
            _holdInput = State(initialValue: plannedSec > 0 ? TimeSpan(seconds: plannedSec).displayStringCompact : "")
            _holdLocal = State(initialValue: TimeSpan(seconds: plannedSec))

            _repInput  = State(initialValue: "")
            _repsLocal = State(initialValue: 0)
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            // ── Top line (label + inputs) – visuals unchanged ───────────────
            HStack {
                setLabel
                // Weight input (unchanged)
                weightSection

                // Metric input (reps or hold) – same visual container as reps
                metricSection
            }
            .padding(.horizontal, -20)
            .padding(.bottom)

            completedEntry
            
            // ── RPE slider (skip for warmups) – unchanged ────────────────
            rpeEntry
        }
        .padding()
        .onAppear(perform: validateNextButton)
        .onChange(of: exercise) { oldValue, newValue in
            if oldValue.id != newValue.id || oldValue.currentSet != newValue.currentSet {
                saveTemplate()
                resetInputs()
            }
        }
    }
    
    @ViewBuilder private var setLabel: some View {
        if isWarm {
            VStack(alignment: .leading, spacing: 2) {
                Text("warmup")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Set \(setDetail.setNumber):")
                    .fontWeight(.bold)
            }
        } else {
            Text("Set \(setDetail.setNumber):")
                .fontWeight(.bold)
        }
    }
    
    @ViewBuilder private var weightSection: some View {
        if exercise.type.usesWeight {
            ZStack {
                let weightText = $setDetail.weight.asText()
                let width      = calculateTextWidth(text: weightText.wrappedValue, minWidth: 60, maxWidth: 90)
                let isZero     = (weightText.wrappedValue == "0")

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
            plannedHoldInputField   // same ZStack look as reps
            VStack(alignment: .leading) {
                Text("Time").bold()
                // (no extra note previously for time)
            }
        }
    }
    
    @ViewBuilder private var completedEntry: some View {
        // ── Completed line – keep the row + paddings identical ─────────
        switch setDetail.planned {
        case .reps(let plannedReps):
            HStack {
                Text("Reps Completed: ").fontWeight(.bold)
                Spacer()
                Text("\(repsLocal) ")
                    .foregroundStyle(repsLocal < plannedReps ? .red :
                        (repsLocal > plannedReps ? .green : .primary))
                Spacer()

                Stepper(
                    "",
                    value: $repsLocal,
                    in: 0...(max(1, plannedReps) * 5),
                    step: 1
                )
                .labelsHidden()
            }
            .padding(.horizontal, -15)
            .onChange(of: repsLocal) { setDetail.completed = .reps(repsLocal) }

        case .hold(let plannedTime):
            let plannedSec = plannedTime.inSeconds
            // Replace stepper with TimeEntryField, keep same HStack + paddings
            HStack {
                Text("Time Completed: ").fontWeight(.bold)
                Spacer()
                Text("\(holdLocal.displayStringCompact) ")
                    .foregroundStyle(holdLocal.inSeconds < plannedSec ? .red :
                        (holdLocal.inSeconds > plannedSec ? .green : .primary))
                Spacer()

                // Stepper with 1-second increments, binding to holdLocal.inSeconds
                Stepper(
                    "",
                    value: Binding(
                        get: { holdLocal.inSeconds },
                        set: { newVal in
                            let clamped = max(0, newVal)
                            holdLocal = TimeSpan(seconds: clamped)
                            setDetail.completed = .hold(holdLocal)
                        }
                    ),
                    in: 0...(max(1, plannedSec) * 3),
                    step: 1
                )
                .labelsHidden()
            }
            .padding(.horizontal, -15)
        }
    }
    
    @ViewBuilder private var rpeEntry: some View {
        if !isWarm {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpeLocal))

                    Slider(
                        value: Binding(
                            get: { rpeLocal },
                            set: { newValue in
                                rpeLocal = newValue
                                setDetail.rpe = newValue
                            }
                        ),
                        in: 1...10,
                        step: 0.5
                    )
                    .padding(.horizontal)
                }
                .padding(.horizontal, -15)

                Text("(1 - 10)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, -10)
        }
    }

    // MARK: - Subviews (visuals match original)

    private var repsInputField: some View {
        ZStack {
            let width  = calculateTextWidth(text: repInput, minWidth: 45, maxWidth: 70)
            let isZero = repInput == "0"

            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray4)
                      : Color(UIColor.secondarySystemBackground))
                .frame(width: width, height: 35)

            TextField("reps",
              text: Binding<String>(
                get: { repInput },
                set: { newValue in
                    let filtered = InputLimiter.filteredReps(newValue)
                    repInput = filtered

                    if let r = Int(filtered), r > 0 {
                        setDetail.planned = .reps(r)
                        repsLocal = r
                        shouldDisableNext = false
                    } else {
                        shouldDisableNext = true
                    }
                }
              )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .foregroundStyle(isZero ? .red : .primary)
            .frame(width: width, alignment: .center)
        }
    }

    // this actually needs to be a string to be formatted properly
    private var plannedHoldInputField: some View {
        ZStack {
            let width  = calculateTextWidth(text: holdInput, minWidth: 60, maxWidth: 90)
            let secs   = TimeSpan.seconds(from: holdInput)
            let isZero = secs <= 0

            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray4)
                      : Color(UIColor.secondarySystemBackground))
                .frame(width: width, height: 35)

            // Planned hold using your fixed-mask field (m:ss)
            TimeEntryField(
                text: Binding(
                    get: { holdInput },
                    set: { newValue in
                        let s = TimeSpan.seconds(from: newValue)    // ✅ your parser
                        let ts = TimeSpan.init(seconds: s)
                        setDetail.planned = .hold(ts)
                        holdInput = ts.displayStringCompact
                        holdLocal = ts
                        shouldDisableNext = s <= 0 || (exercise.type.usesWeight && setDetail.weight.inKg <= 0)
                    }
                ),
                style: .plain
            )
            .foregroundStyle(isZero ? .red : .primary)
            .frame(width: width, alignment: .center)
        }
    }

    // MARK: - Helpers

    private var isWarm: Bool { exercise.currentSet <= exercise.warmUpSets }

    private func resetInputs() {
        switch setDetail.planned {
        case .reps(let r):
            repInput  = r > 0 ? String(r) : ""
            repsLocal = r
            holdInput = ""
            holdLocal = .init(seconds: 0)

        case .hold(let t):
            let s = t.inSeconds
            holdInput = s > 0 ? TimeSpan(seconds: s).displayStringCompact : ""
            holdLocal = TimeSpan(seconds: s)
            repInput  = ""
            repsLocal = 0
        }
        
        rpeLocal = setDetail.rpe ?? 1
        validateNextButton()
    }

    private func validateNextButton() {
        switch setDetail.planned {
        case .reps(let r):
            shouldDisableNext = r <= 0 || (exercise.type.usesWeight && setDetail.weight.inKg <= 0)

        case .hold(let t):
            shouldDisableNext = t.inSeconds <= 0 || (exercise.type.usesWeight && setDetail.weight.inKg <= 0)
        }
    }

    private func calculateTextWidth(text: String, minWidth: CGFloat, maxWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let measured = (text as NSString).size(withAttributes: [.font: font]).width + 20 // padding
        return min(max(measured, minWidth), maxWidth)
    }
}


