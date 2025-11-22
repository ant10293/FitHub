import SwiftUI
import Symbols

struct StartedWorkoutView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var kbd = KeyboardManager.shared
    @StateObject var viewModel: WorkoutVM
    @StateObject private var timer = TimerManager() // needs to remain here for rest timer
    @State private var showingExitConfirmation = false
    @State private var selectedExerciseIndex: Int?
    @State private var showingDetailView: Bool = false
    var onExit: () -> Void = {}

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                SimpleStopwatch(start: viewModel.startDate, isStopped: viewModel.showWorkoutSummary)
                    .font(.largeTitle)
                    .padding()
               
                Divider()
               
                exerciseList
            }
            // Overlay content
            if viewModel.isOverlayVisible { exerciseSetOverlay }
            if viewModel.showWorkoutSummary { workoutSummaryOverlay }
            if !ctx.userData.evaluation.askedRPEprompt { rpePromptOverlay }
        }
        .navigationBarTitle("\(viewModel.template.name)", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .onAppear(perform: performSetup)
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .sheet(isPresented: $showingDetailView, onDismiss: { showingDetailView = false }) {
            if let index = selectedExerciseIndex, let exercise = viewModel.template.exercises[safe: index] {
                ExerciseDetailView(viewingDuringWorkout: true, exercise: exercise)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .active, newPhase == .inactive {
                viewModel.saveWorkoutInProgress(userData: ctx.userData)
            }
        }
    }
    
    private func performSetup() {
        if selectedExerciseIndex == nil {
            selectedExerciseIndex = viewModel.performSetup(userData: ctx.userData)
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
                  exercise.setsSubtitle
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
    
    private var rpePromptOverlay: some View {
        RPEPrompt(
            onSelect: { hideRPE in
                ctx.userData.settings.hideRpeSlider = hideRPE
                ctx.userData.evaluation.askedRPEprompt = true
            }
        )
    }
    
    private var workoutSummaryOverlay: some View {
        WorkoutSummary(
            summary: viewModel.calculateWorkoutSummary(),
            exercises: viewModel.template.exercises,
            onDone: {
                viewModel.finishWorkoutAndDismiss(ctx: ctx, completion: onExit)
            }
        )
    }
    
    @ViewBuilder private var exerciseSetOverlay: some View {
        if let selectedExerciseIdx = selectedExerciseIndex {
            ExerciseSetOverlay(
                exercise: $viewModel.template.exercises[selectedExerciseIdx],
                timerManager: timer,
                progress: TemplateProgress(
                    exerciseIdx: selectedExerciseIdx,
                    numExercises: viewModel.template.numExercises,
                    isLastExercise: viewModel.isLastExerciseForIndex(selectedExerciseIdx)
                ),
                params: UserParams(
                    restTimerEnabled: ctx.userData.settings.restTimerEnabled,
                    restPeriods: RestPeriods.determineRestPeriods(
                        customRest: ctx.userData.workoutPrefs.customRestPeriods,
                        goal: ctx.userData.physical.goal
                    ),
                    hideRPE: ctx.userData.settings.hideRpeSlider,
                    hideCompleted: ctx.userData.settings.hideCompletedInput,
                    hideImage: ctx.userData.settings.hideExerciseImage
                ),
                goToNextSetOrExercise: {
                    viewModel.goToNextSetOrExercise(for: selectedExerciseIdx, selectedExerciseIndex: &selectedExerciseIndex)
                },
                onClose: {
                    viewModel.isOverlayVisible = false
                    selectedExerciseIndex = nil
                },
                viewDetail: {
                    showingDetailView = true
                },
                getPriorMax: { id in
                    return ctx.exercises.peakMetric(for: id)
                },
                onPerformanceUpdate: { update in
                    viewModel.updatePerformance(update)
                },
                saveTemplate: { detailBinding, exerciseBinding in
                    viewModel.saveTemplate(userData: ctx.userData, detailBinding: detailBinding, exerciseBinding: exerciseBinding)
                }
            )
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
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
            Alert(
                title: Text("Are you sure you want to go back?"),
                message: Text("Workout still in progress. Save as a completed workout?"),
                primaryButton: .default(Text("Yes")) {
                    viewModel.finishWorkoutAndDismiss(ctx: ctx, completion: onExit)
                },
                secondaryButton: .default(Text("No")) {
                    viewModel.endWorkoutAndDismiss(ctx: ctx, completion: onExit)
                }
            )
        }
    }
}
