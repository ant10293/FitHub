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
    @Binding var showPicker: Bool

    @State private var showTimer: Bool = false
    @State private var hideStartButton: Bool = false
    @State private var load: SetLoad = .weight(Mass(kg: 0))
    @State private var planned: SetMetric = .reps(0)
    @State private var completed: SetMetric = .reps(0)
    @State private var rpe: Double = 1.0
    
    let timerManager: TimerManager
    let hideRPE: Bool
    let hideCompleted: Bool
    let exercise: Exercise
    
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
                
                if !hideStartButton, let seconds = planned.secondsValue {
                    let completedSec = completed.secondsValue ?? 0
                    let isResume = completedSec > 0 && completedSec < seconds
                    RectangularButton(
                        title: isResume ? "Resume Countdown" : "Start Countdown",
                        systemImage: "play.fill",
                        enabled: seconds > 0,
                        bgColor: isResume ? .orange : .green,
                        width: .fit,
                        action: {
                            showTimer = true
                        }
                    )
                    .padding(.top)
                }
            }
            
            if !hideCompletedEntry, !timerManager.restIsActive, !shouldDisableNext {
                CompletedEntry(
                    isWarm: exercise.isWarmUp,
                    hideRPE: hideRPE,
                    hideCompleted: hideCompleted,
                    planned: planned,
                    setRPE: setDetail.rpe, // ensures that rpe editing is recognized visually
                    showPicker: $showPicker,
                    completed: Binding(
                        get: { completed },
                        set: {
                            completed = $0
                            setDetail.completed = $0
                        }
                    ),
                    rpe: Binding(
                        get: { rpe },
                        set: {
                            rpe = $0
                            setDetail.rpe = $0
                        }
                    )
                )
                .padding([.horizontal, .top])
            }
        }
        .padding(.vertical)
        .onAppear(perform: resetInputs)
        .onChange(of: setDetail.id) { resetInputs() }
        .sheet(isPresented: $showTimer) {
            PlannedTimerRing(
                manager: timerManager,
                planned: planned,
                completed: completed,
                onCompletion: { completedMetric in
                    showTimer = false
                    setDetail.completed = completedMetric
                    completed = completedMetric
                    toggleHideStartIfNeeded()
                }
            )
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var hideCompletedEntry: Bool {
        //if showPicker { return false } 
        let completedSec = completed.secondsValue ?? 0
        return planned.secondsValue != nil && completedSec <= 0
    }
    
    private func toggleHideStartIfNeeded() {
        if let plannedSec = planned.secondsValue, let completedSec = completed.secondsValue {
            if completedSec >= plannedSec {
                hideStartButton = true
            } else {
                hideStartButton = false
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

    // Inside ExerciseSetDisplay, replace `weightSection` contents
    @ViewBuilder private var weightSection: some View {
        if load != .none {
            let width = calculateTextWidth(text: load.fieldString, minWidth: screenWidth * 0.16, maxWidth: screenWidth * 0.267)
            let isZero = load.actualValue == 0
            
            FieldChrome(width: width, isZero: isZero) {
                SetLoadEditor(
                    load: Binding(
                        get: { load },
                        set: {
                            load = $0
                            setDetail.load = $0
                            validateSet()
                        }
                    )
                )
                .id(setDetail.id) // refresh for new set
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
    
    @ViewBuilder private var metricSection: some View {
        let width  = calculateTextWidth(text: planned.fieldString, minWidth: screenWidth * 0.16, maxWidth: screenWidth * 0.267)
        let isZero = planned.actualValue == 0

        FieldChrome(width: width, isZero: isZero) {
            SetMetricEditor(
                planned: Binding(
                    get: { planned },
                    set: {
                        planned = $0
                        setDetail.planned = $0
                        switch planned {
                        case .reps:
                            completed = $0
                            setDetail.completed = $0
                        case .cardio, .hold:
                            toggleHideStartIfNeeded()
                        }
                        validateSet()
                    }
                ),
                load: load,
                style: .plain
            )
            .id(setDetail.id) // refresh for new set
        }
        VStack(alignment: .leading) {
            Text(planned.label).bold()
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
        validateSet()
    }
    
    private func initializeVariables() {
        rpe = setDetail.rpe ?? 1
        load = setDetail.load
        planned = setDetail.planned

        if let comp = setDetail.completed {
            completed = comp
            toggleHideStartIfNeeded()
        } else {
            switch planned {
            case .reps:
                completed = planned
            case .hold, .cardio:
                completed = planned.zeroValue
            }
        }
    }
    
    private func validateSet() {
        shouldDisableNext = planned.actualValue <= 0 || (load != .none && load.actualValue <= 0)
    }
}
