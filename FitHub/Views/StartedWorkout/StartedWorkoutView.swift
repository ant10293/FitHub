import SwiftUI
import Symbols


struct StartedWorkoutView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject var viewModel: WorkoutVM
    @StateObject private var timer = TimerManager()
    @State private var showingExitConfirmation = false
    @State private var selectedExerciseIndex: Int?
    @State private var showingDetailView: Bool = false
    var onExit: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Format.timeString(from: timer.secondsElapsed))
                    .font(.largeTitle)
                    .padding()
                
                playPauseButton
            }
            
            Divider()
            
            exerciseList
        }
        .navigationBarTitle("\(viewModel.template.name)", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .overlay(viewModel.showWorkoutSummary ? workoutSummaryOverlay : nil).zIndex(1)
        .overlay(viewModel.isOverlayVisible ? exerciseSetOverlay : nil)
        .sheet(isPresented: $showingDetailView, onDismiss: { showingDetailView = false }) {
            if let index = selectedExerciseIndex {
                ExerciseDetailView(viewingDuringWorkout: true, exercise: viewModel.template.exercises[index])
            }
        }
        .onAppear(perform: performSetup)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.saveWorkoutInProgress(userData: ctx.userData, timer: timer)
            }
        }
    }
    
    private func performSetup() {
        if !ctx.userData.isWorkingOut {
            ctx.userData.isWorkingOut = true
            selectedExerciseIndex = viewModel.getExerciseIndex(timer: timer)
            viewModel.setTemplateCompletionStatus(completedWorkouts: ctx.userData.workoutPlans.completedWorkouts)
        }
    }
    
    private var exerciseList: some View {
      List {
          ForEach(viewModel.template.exercises) { exercise in
              ExerciseRow(
                exercise,
                heartOverlay: true,
                favState: FavoriteState.getState(for: exercise, userData: ctx.userData)
              ) { }
              detail: {
                  Text("Sets: \(exercise.workingSets)")
                      .font(.subheadline)
                      .foregroundStyle(Color.secondary)
              } onTap: {
                  // find its index at tap time
                  if let idx = viewModel.template.exercises.firstIndex(where: { $0.id == exercise.id }) {
                      selectedExerciseIndex = idx
                      viewModel.isOverlayVisible = true
                  }
              }
              .id(exercise.id)
              .disabled(exercise.isCompleted)
              .opacity(exercise.isCompleted ? 0.25 : 1.0)
          }
      }
      .opacity((viewModel.isOverlayVisible || viewModel.showWorkoutSummary) ? 0.6 : 1.0)
      .listStyle(GroupedListStyle())
      .disabled(viewModel.isOverlayVisible)
    }
    
    private var workoutSummaryOverlay: some View {
        WorkoutSummary(
            summary: viewModel.calculateWorkoutSummary(secondsElapsed: timer.secondsElapsed),
            exercises: viewModel.template.exercises,
            onDone: {
                viewModel.finishWorkoutAndDismiss(ctx: ctx, timer: timer, completion: { dismiss() })
            }
        )
    }
    
    @ViewBuilder
    private var exerciseSetOverlay: some View {
        if let selectedExerciseIdx = selectedExerciseIndex {
            ZStack {
                ExerciseSetOverlay(
                    timerManager: timer,
                    equipment: ctx.equipment,
                    exercise: $viewModel.template.exercises[selectedExerciseIdx],
                    progress: TemplateProgress(
                        exerciseIdx: selectedExerciseIdx,
                        numExercises: viewModel.template.numExercises,
                        isLastExercise: viewModel.isLastExerciseForIndex(selectedExerciseIdx),
                        restTimerEnabled: ctx.userData.settings.restTimerEnabled,
                        restPeriods: RestPeriods.determineRestPeriods(
                            customRest: ctx.userData.workoutPrefs.customRestPeriods,
                            goal: ctx.userData.physical.goal
                        )
                    ),
                    goToNextSetOrExercise: {
                        viewModel.goToNextSetOrExercise(for: selectedExerciseIdx, selectedExerciseIndex: &selectedExerciseIndex, timer: timer)
                    },
                    onClose: {
                        viewModel.isOverlayVisible = false
                        selectedExerciseIndex = nil
                    },
                    viewDetail: {
                        showingDetailView = true
                    },
                    getPriorMax: { id in
                        ctx.exercises.peakMetric(for: id)
                    },
                    onPerformanceUpdate: { update in
                        viewModel.updatePerformance(update)
                    },
                    saveTemplate: { detailBinding, exerciseBinding in
                        viewModel.saveTemplate(userData: ctx.userData, detailBinding: detailBinding, exerciseBinding: exerciseBinding)
                    }
                )
                .padding()
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
            }
            .padding(.horizontal, 5)
        }
    }
    
    private var backButton: some View {
        Button(action: { showingExitConfirmation = true }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Back")
            }
        }
        .alert(isPresented: $showingExitConfirmation) {
            Alert(title: Text("Are you sure you want to go back?"),
                message: Text("Doing so will end your workout."),
                primaryButton: .destructive(Text("End Workout")) {
                    viewModel.endWorkoutAndDismiss(ctx: ctx, timer: timer, shouldRemoveDate: false, completion: {
                        onExit()
                        dismiss()
                    })
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var playPauseButton: some View {
        Button(action: {
            if timer.isActive { timer.stopTimer() }
            else { timer.startTimer() }
        }) {
            Image(systemName: timer.isActive ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(timer.isActive ? .yellow : .green)
                .background(Circle().fill(Color.black))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
}

