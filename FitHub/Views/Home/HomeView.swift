import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingFavoriteExercises: Bool = false
    @State private var showingExerciseSelection: Bool = false
    @State private var selectedExercise: Exercise.ID?
    @State private var selectedMeasurement: MeasurementType = .weight
    @State private var selectedView: GraphView = .exercisePerformance

    var body: some View {
        NavigationStack {
            List {
                profileSection
                graphSection
            }
            .onAppear(perform: initializeVariables)
            .navigationTitle("Home")
            .customToolbar(
                settingsDestination: { AnyView(SettingsView()) },
                menuDestination: { AnyView(MenuView()) }
            )
        }
    }

    private func initializeVariables() {
        selectedExercise = ctx.userData.sessionTracking.selectedExercise
        selectedMeasurement = ctx.userData.sessionTracking.selectedMeasurement
        selectedView = ctx.userData.sessionTracking.selectedView
    }

    private var unwrappedExercise: Exercise? {
        if let exerciseId = selectedExercise {
            return ctx.exercises.exercise(for: exerciseId)
        } else { // fallback
            return ctx.exercises.exercise(named: "Bench Press")
        }
    }

    private var profileSection: some View {
        Section {
            HStack {
                NavigationLink(destination: LazyDestination { UserProfileView() }) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenWidth * 0.125)
                        .foregroundStyle(colorScheme == .dark ? .gray : .black)

                    VStack(alignment: .leading) {
                        Text(ctx.userData.profile.displayName(.full))
                            .font(.title2)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)

                        Text("\(ctx.userData.sessionTracking.totalNumWorkouts) workouts")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? .gray : .black)
                    }
                    Spacer()
                }
            }
            .padding()

            Button(action: { showingFavoriteExercises = true }) {
                HStack {
                    Text("Favorite Exercises")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(alignment: .leading)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .frame(alignment: .trailing)
                }
                .padding()
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            }
            .sheet(isPresented: $showingFavoriteExercises) { FavoriteExercisesView() }
        }
        .background(Color.clear)
    }

    private var graphSection: some View {
        Section {
            VStack {
                Picker("Select View", selection: $selectedView) {
                    ForEach(GraphView.allCases, id: \.self) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedView) { oldValue, newValue in
                    ctx.userData.sessionTracking.selectedView = newValue
                }

                switch selectedView {
                case .exercisePerformance:
                    performanceGraphSection
                case .bodyMeasurements:
                    measurementsGraphSection
                }
            }
        }
        .background(Color.clear)
    }

    private var performanceGraphSection: some View {
        GraphSectionView(
            label: "Exercise",
            selectionControl: {
                Button(action: { showingExerciseSelection = true }) {
                    PickerLabel(text: unwrappedExercise?.name ?? "Select Exercise")
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            },
            content: {
                if let selectedExercise = unwrappedExercise {
                    let perf = ctx.exercises.performanceData(for: selectedExercise.id)
                    ExercisePerformanceGraph(exercise: selectedExercise, performance: perf)
                }
            }
        )
        .onChange(of: selectedExercise) { oldValue, newValue in
            if oldValue != newValue {
                ctx.userData.sessionTracking.selectedExercise = newValue
            }
        }
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelection(
                mode: .performanceView,
                onDone: { chosenExercises in
                    if let first = chosenExercises.first {
                        self.selectedExercise = first.id
                    }
                    showingExerciseSelection = false
                }
            )
        }
    }

    private var measurementsGraphSection: some View {
        GraphSectionView(
            label: "Measurement",
            selectionControl: {
                Menu {
                    ForEach(ctx.userData.getValidMeasurements()) { measurement in
                        Button(action: {
                            selectedMeasurement = measurement
                        }) {
                            HStack {
                                Text(measurement.rawValue)
                                if selectedMeasurement == measurement {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    PickerLabel(text: selectedMeasurement.rawValue)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            },
            content: {
                MeasurementsGraph(
                    selectedMeasurement: ctx.userData.sessionTracking.selectedMeasurement,
                    currentMeasurement: ctx.userData.physical.currentMeasurements[selectedMeasurement],
                    pastMeasurements: ctx.userData.physical.pastMeasurements[selectedMeasurement]
                )
            }
        )
        .onChange(of: selectedMeasurement) { old, new in
            if old != new {
                ctx.userData.sessionTracking.selectedMeasurement = new
            }
        }
    }
}
