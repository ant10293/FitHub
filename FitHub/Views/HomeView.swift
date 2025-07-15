import SwiftUI


struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingFavoriteExercises: Bool = false
    @State private var showingExerciseSelection: Bool = false
    //@State private var selectedExercise: String = "Bench Press"
    @State private var selectedExercise: UUID?
    @State private var selectedMeasurement: MeasurementType = .weight
    @State private var selectedView: GraphView = .exercisePerformance
    
    var body: some View {
        NavigationStack {
            List {
                profileSection
                selectViewSection
            }
            .onAppear(perform: initializeVariables)
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MenuView()) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
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
                NavigationLink(destination: UserProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.125) 
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                    
                    VStack(alignment: .leading) {
                        Text(ctx.userData.profile.userName)
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(ctx.userData.sessionTracking.totalNumWorkouts) workouts")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .gray : .black)
                    }
                    Spacer()
                }
            }
            .padding()
            
            Button(action: { showingFavoriteExercises = true }) {
                HStack {
                    Text("Favorite Exercises")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(alignment: .leading)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .frame(alignment: .trailing)
                }
                .padding()
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            }
            .sheet(isPresented: $showingFavoriteExercises) { FavoriteExercisesView() }
        }
        .background(Color.clear)
    }
    
    private var selectViewSection: some View {
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
                    ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
                }
                if selectedView == .exercisePerformance {
                    exercisePerformanceSection
                } else {
                    measurementsGraphSection
                }
            }
        }
        .background(Color.clear)
    }
    
    private var exercisePerformanceSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Exercise")
                    .padding(.leading)
                Spacer()
                
                Button(action: { showingExerciseSelection = true }) {
                    pickerLabel
                    .padding(.trailing)
                    .contentShape(Rectangle()) // Ensure tap area is tightly bound
                }
                .buttonStyle(PlainButtonStyle()) // Prevents full-row tap behavior
            }
            .padding(.bottom)
            
            if let selectedExercise = selectedExercise ?? ctx.exercises.exercise(named: "Bench Press")?.id {
                let perf = ctx.exercises.allExercisePerformance[selectedExercise]
                
                if let ex = ctx.exercises.exercise(for: selectedExercise) {
                    ExercisePerformanceGraph(
                        exercise: ex,
                        value: perf?.maxValue,
                        currentMaxDate: perf?.currentMaxDate,
                        pastMaxes: perf?.pastMaxes ?? []
                    )
                }
            }
            
        }
        .onChange(of: selectedExercise) { oldValue, newValue in
            if oldValue != newValue { // Only perform side effects if the value has truly changed
                ctx.userData.sessionTracking.selectedExercise = newValue
                ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
            }
        }
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelection(
                selectedExercises: [], // supply an empty array because in "performance" mode we only pick one
                onDone: { chosenExercises in
                    // Because forPerformanceView = true, we expect only one exercise
                    if let first = chosenExercises.first {
                        self.selectedExercise = first.id
                    }
                    showingExerciseSelection = false
                },
                forPerformanceView: true // Hides checkboxes & filters out maxValue == 0
            )
        }
    }
    
    private var measurementsGraphSection: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Measurement")

                Picker("", selection: $selectedMeasurement) {
                    ForEach(ctx.userData.getValidMeasurements()) { measurement in
                        Text(measurement.rawValue).tag(measurement)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.top, -10)
            .padding(.bottom, 5)

            MeasurementsGraph(
                selectedMeasurement: ctx.userData.sessionTracking.selectedMeasurement,
                currentMeasurement: ctx.userData.physical.currentMeasurements[selectedMeasurement],
                pastMeasurements: ctx.userData.physical.pastMeasurements[selectedMeasurement]
            )
        }
        .onChange(of: selectedMeasurement) { old, new in
            if old != new {
                ctx.userData.sessionTracking.selectedMeasurement = new
                ctx.userData.saveSingleStructToFile(\.sessionTracking, for: .sessionTracking)
            }
        }
    }
    
    private var pickerLabel: some View {
        HStack(spacing: 5) {
            if let exercise = unwrappedExercise {
                Text(exercise.name)
                    .foregroundColor(.blue)
            } else {
                Text("Select Exercise")
                    .foregroundColor(.blue)
            }
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}




