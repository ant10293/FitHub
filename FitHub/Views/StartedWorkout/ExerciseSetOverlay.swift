//
//  ExerciseSetOverlay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct ExerciseSetOverlay: View {
    let timerManager: TimerManager
    @ObservedObject var viewModel: WorkoutViewModel
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var adjustmentsViewModel: AdjustmentsViewModel
    @Binding var exercise: Exercise
    @Binding var isPressed: Bool
    @State private var showingAdjustmentsView = false
    @State private var shouldDisableNext = false
    @State private var showOverlay: Bool = false
    let isLastExercise: Bool
    var restTimerEnabled: Bool
    var restPeriod: Int
    var goToNextSetOrExercise: () -> Void
    var onClose: () -> Void
    var viewDetail: () -> Void
    var saveTemplate: (Binding<SetDetail>, Binding<Exercise>) -> Void

    init(timerManager: TimerManager,
        viewModel: WorkoutViewModel,
        exercise: Binding<Exercise>,
        isPressed: Binding<Bool>,
        isLastExercise: Bool,
        restTimerEnabled: Bool,
        restPeriod: Int,
        goToNextSetOrExercise: @escaping () -> Void,
        onClose: @escaping () -> Void,
        viewDetail: @escaping () -> Void,
        saveTemplate: @escaping (Binding<SetDetail>, Binding<Exercise>) -> Void
    ){
        self.timerManager = timerManager
        self.viewModel = viewModel
        self._exercise = exercise
        self._isPressed = isPressed
        self.isLastExercise = isLastExercise
        self.goToNextSetOrExercise = goToNextSetOrExercise
        self.onClose = onClose
        self.viewDetail = viewDetail
        self.saveTemplate = saveTemplate
        self.restTimerEnabled = restTimerEnabled
        self.restPeriod = restPeriod
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Exercise \(viewModel.getIndex(exercise: exercise)+1) of \(viewModel.getExerciseCount())")
                    .frame(maxWidth: 50)
                    .foregroundColor(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                VStack(alignment: .center) {
                    Text("\(exercise.name)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 150)
                    
                    Text("Sets: \(exercise.sets)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }.padding(.horizontal)
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                        .frame(alignment: .topTrailing)
                }
                .padding()
            }
            .padding(.top, -25)
            
            let warmCount = exercise.warmUpSets
            let all = exercise.allSetDetails
            let idx = exercise.currentSet - 1

            if idx >= 0, idx < all.count {
                // Equipment Adjustments + Info button
                HStack {
                    VStack(alignment: .leading) {
                        if adjustmentsViewModel.hasEquipmentAdjustments(for: exercise) {
                            Button(action: { showingAdjustmentsView = true }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Equipment Adjustments")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.blue)
                                        .minimumScaleFactor(0.8)

                                    if let adjustments = adjustmentsViewModel.getEquipmentAdjustments(for: exercise),
                                       !adjustments.isEmpty {
                                        let nonEmpty = adjustments.filter { !$0.value.displayValue.isEmpty }
                                        if nonEmpty.isEmpty {
                                            Text("+ Add Adjustment")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                        } else {
                                            ForEach(nonEmpty.keys.sorted(), id: \.self) { cat in
                                                if let val = nonEmpty[cat]?.displayValue {
                                                    HStack {
                                                        Text("\(cat.rawValue):")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                        Text(val)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                            .bold()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, -5)
                            }
                        }
                    }
                    Button(action: viewDetail) {
                        exerciseImage
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Binding into warmUpDetails or setDetails
                let detailBinding = Binding<SetDetail>(
                    get: { all[idx] },
                    set: { newValue in
                        if idx < warmCount {
                            exercise.warmUpDetails[idx] = newValue
                        } else {
                            exercise.setDetails[idx - warmCount] = newValue
                        }
                    }
                )

                // Display the set editor
                ExerciseSetDisplay(
                    setDetail: detailBinding,
                    shouldDisableNext: $shouldDisableNext,
                    exercise: exercise,
                    saveTemplate: {
                        saveTemplate(detailBinding, $exercise)
                    }
                )

                if !exercise.isCompleted {
                    NextButton(
                        timerManager: timerManager,
                        exercise: $exercise,
                        isPressed: $isPressed,
                        getPriorMax: { name in
                            exerciseData.getMax(for: name) ?? 0
                        },
                        index: idx,
                        isLastExercise: isLastExercise,
                        goToNextSetOrExercise: goToNextSetOrExercise,
                        restTimerEnabled: restTimerEnabled,
                        restPeriod: restPeriod,
                        onPerformanceUpdate: { name, maxVal, rxw, setNum in
                            viewModel.updatePerformance(name, maxVal, rxw, setNum)
                        }
                    )
                    .disabled(shouldDisableNext)
                }
            } else {
                Text("No current set available")
            }
        }
        .padding()
        .disabled(exercise.isCompleted)
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exerciseData: exerciseData, exercise: exercise)
                .ignoresSafeArea()
        }
    }
    private var exerciseImage: some View {
        ZStack {
            Image(exercise.fullImagePath)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 150, height: 150)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle()) // Ensure tap area is tightly bound
        .frame(width: 150, height: 150)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

