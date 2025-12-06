import SwiftUI
import Symbols

struct StartedWorkoutView: View {
    @EnvironmentObject private var ctx: AppContext
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
                CenteredOverlayHeader(
                    leading: {
                        Text("\(viewModel.completedExercisesCount) of \(viewModel.totalExercises)\n Completed")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    },
                    center: {
                        SimpleStopwatch(start: viewModel.startDate, isStopped: viewModel.showWorkoutSummary)
                            .font(.largeTitle)
                    },
                    trailing: {
                        (Text("\(viewModel.prCount) ")
                         + Text(Image(systemName: "trophy.fill")))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                )
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
                ExerciseDetailView(exercise: exercise, viewingAsSheet: true)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .active, newPhase == .inactive,
               !viewModel.workoutEnded {
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
        TemplateExerciseList(
            template: viewModel.template,
            userData: ctx.userData,
            heartOverlay: true,
            showCount: false,
            tapAction: .showOverlay,
            detail: { exercise in
                exercise.setsSubtitle
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            },
            onTap: { exercise, index in
                selectedExerciseIndex = index
                viewModel.isOverlayVisible = true
            }
        )
        .listStyle(GroupedListStyle())
        .opacity((viewModel.isOverlayVisible || viewModel.showWorkoutSummary) ? 0.6 : 1.0)
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
        Button(action: {
            if viewModel.noSetsCompleted {
                viewModel.endWorkoutAndDismiss(ctx: ctx, completion: onExit)
            } else {
                showingExitConfirmation = true
            }
        }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Back")
            }
        }
        .alert("Workout still in progress", isPresented: $showingExitConfirmation) {
            Button("Save") {
                viewModel.finishWorkoutAndDismiss(ctx: ctx, completion: onExit)
            }
            Button("Discard", role: .destructive) {
                viewModel.endWorkoutAndDismiss(ctx: ctx, completion: onExit)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save as a completed workout?")
        }
    }
}
