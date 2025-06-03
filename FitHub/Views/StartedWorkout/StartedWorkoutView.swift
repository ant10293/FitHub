import SwiftUI
import Symbols


struct StartedWorkoutView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exerciseData: ExerciseData
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase  // Observe the scenePhase here
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @StateObject var viewModel: WorkoutViewModel
    @State private var showingExitConfirmation = false
    @State private var selectedExerciseIndex: Int?
    @State private var isKeyboardVisible: Bool = false
    @State private var showingDetailView: Bool = false
    @State private var isDetailViewEnabled: Bool = false
    var onExit: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(timeString(from: timerManager.secondsElapsed))
                    .font(.largeTitle)
                    .padding()
                playPauseButton
            }
            Divider()
            
            List(viewModel.template.exercises.indices, id: \.self) { index in
                ExerciseRowView(
                    exercise: $viewModel.template.exercises[index],
                    onTap: {
                        selectedExerciseIndex = index
                        viewModel.isOverlayVisible = true
                    }
                )
                .id(viewModel.template.exercises[index].id) // Ensure unique ID per item
            }
            .listStyle(GroupedListStyle())
            .disabled(viewModel.isOverlayVisible)
        }
        .navigationBarTitle("\(viewModel.template.name)", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .overlay(
            Group {
                if viewModel.showWorkoutSummary {
                    let summary = viewModel.calculateWorkoutSummary(timerManager: timerManager)
                    WorkoutSummary(
                        totalVolume: summary.totalVolume,
                        totalWeight: summary.totalWeight,
                        totalReps: summary.totalReps,
                        totalTime: summary.totalTime,
                        exercisePRs: summary.exercisePRs,
                        exercises: viewModel.template.exercises,
                        onDone: {
                            if viewModel.finishWorkoutAndDismiss(userData: userData, exerciseData: exerciseData, timerManager: timerManager) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                }
            }
        ).zIndex(1)
        .overlay(
            Group {
                let restTimerEnabled = userData.restTimerEnabled
                let restPeriod = FitnessGoal.determineRestPeriod(for: userData.goal)
                
                if viewModel.isOverlayVisible {
                    if let selectedExerciseIdx = selectedExerciseIndex {
                        ZStack {
                            let isLastExercise = viewModel.isLastExerciseForIndex(selectedExerciseIdx)
                            ExerciseSetOverlay(
                                timerManager: timerManager,
                                viewModel: viewModel,
                                exercise: $viewModel.template.exercises[selectedExerciseIdx],
                                isPressed: .constant(false),
                                isLastExercise: isLastExercise,
                                restTimerEnabled: restTimerEnabled,
                                restPeriod: restPeriod,
                                goToNextSetOrExercise: {
                                    viewModel.goToNextSetOrExercise(for: selectedExerciseIdx, selectedExerciseIndex: &selectedExerciseIndex, timerManager: timerManager)
                                },
                                onClose: {
                                    viewModel.isOverlayVisible = false
                                    selectedExerciseIndex = nil
                                },
                                viewDetail: {
                                    if isDetailViewEnabled {
                                        showingDetailView = true
                                    }
                                },
                                saveTemplate: { detailBinding, exerciseBinding in
                                    viewModel.saveTemplate(userData: userData, detailBinding: detailBinding, exerciseBinding: exerciseBinding)
                                }
                            )
                            .padding()
                            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal, 5)
                    }
                }
            }
        )
        .onChange(of: selectedExerciseIndex) { oldValue, newValue in
            if oldValue != newValue {
                isDetailViewEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isDetailViewEnabled = true // Set to true after 1 second
                }
            }
        }
        .sheet(isPresented: $showingDetailView, onDismiss: {
            showingDetailView = false // Reset after dismissal
        }) {
            if let index = selectedExerciseIndex {
                ExerciseDetailView(
                    exerciseData: exerciseData,
                    viewingDuringWorkout: true,
                    exercise: viewModel.template.exercises[index],
                    onClose: {
                        showingDetailView = false
                    }
                )
            }
        }
        .onAppear {
            //print("Timer Active: \(timerManager.timerIsActive)")
            selectedExerciseIndex = viewModel.getExerciseIndex(timerManager: timerManager)
            setupKeyboardObservers()
        }
        .onDisappear(perform: removeKeyboardObservers)
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.saveWorkoutInProgress(userData: userData, timerManager: timerManager)
            }
        }
    }
    
    var backButton: some View {
        Button(action: {
            self.showingExitConfirmation = true
        }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Back")
            }
        }
        .alert(isPresented: $showingExitConfirmation) {
            Alert(
                title: Text("Are you sure you want to go back?"),
                message: Text("Doing so will end your workout."),
                primaryButton: .destructive(Text("End Workout")) {
                    if viewModel.endWorkoutAndDismiss(userData: userData, exerciseData: exerciseData, shouldRemoveNotifications: false, timerManager: timerManager) {
                        onExit()
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var playPauseButton: some View {
        Button(action: {
            if timerManager.timerIsActive {
                timerManager.stopTimer()
            } else {
                timerManager.startTimer()
            }
        }) {
            Image(systemName: timerManager.timerIsActive ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(timerManager.timerIsActive ? .yellow : .green)
                .background(Circle().fill(Color.black))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
    
    struct ExerciseRowView: View {
        @Binding var exercise: Exercise
        var onTap: () -> Void
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(exercise.fullImagePath)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(width: 50, height: 50)
                        .opacity(exercise.isCompleted ? 0.4 : 1.0)
                    
                    
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                            .opacity(exercise.isCompleted ? 0.4 : 1.0)
                        
                        Text("Sets: \(exercise.sets)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .opacity(exercise.isCompleted ? 0.4 : 1.0)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            }
            .disabled(exercise.isCompleted)
        }
    }
}

