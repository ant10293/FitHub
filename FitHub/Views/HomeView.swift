import SwiftUI


struct HomeView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var csvLoader: CSVLoader
    @EnvironmentObject var exerciseData: ExerciseData
    @EnvironmentObject var equipment: EquipmentData
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingMenuView: Bool = false
    @State private var showingFavoriteExercises: Bool = false
    @State private var showingExerciseSelection: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // Use userData values to initialize states
    @State private var selectedExercise: String
    @State private var selectedMeasurement: MeasurementType
    @State private var selectedView: GraphView
    
    init(userData: UserData) {
        self.userData = userData
        
        _selectedExercise = State(initialValue: userData.selectedExercise)
        _selectedMeasurement = State(initialValue: userData.selectedMeasurement)
        _selectedView = State(initialValue: userData.selectedView)
    }
    
    var body: some View {
        NavigationStack {
            List {
                profileSection
                
                selectViewSection
            }
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
    private var profileSection: some View {
        Section {
            HStack {
                NavigationLink(destination: UserProfileView(userData: userData)) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                    
                    VStack(alignment: .leading) {
                        Text(userData.userName)
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(userData.totalNumWorkouts) workouts")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .gray : .black)
                    }
                    Spacer()
                }
            }
            .padding()
            
            Button(action: {
                showingFavoriteExercises = true
            }) {
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
            .sheet(isPresented: $showingFavoriteExercises) {
                FavoriteExercisesView(exerciseData: exerciseData, userData: userData)
            }
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
                    userData.selectedView = newValue
                    userData.saveSingleVariableToFile(\.selectedView, for: .selectedView)
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
            if exerciseData.allExercisePerformance.isEmpty {
                VStack(alignment: .leading) {
                    Text("Exercise Performance")
                        .font(.headline)
                        .centerHorizontally()
                    List {
                        Text("No exercise performance data available.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .frame(height: 300)
                }
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        /*Picker("Select Exercise", selection: $selectedExercise) {
                            ForEach(exerciseData.allExercisePerformance.keys.sorted(), id: \.self) { exerciseName in
                                if let performance = exerciseData.allExercisePerformance[exerciseName],
                                    let max = performance.maxValue, max > 0 {
                                        Text(exerciseName).tag(exerciseName as String?)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)*/
                        
                        Text("Select Exercise")
                            .padding(.leading)
                        Spacer()
                        // Tappable button to present ExerciseSelectionView
                        Button(action: {
                                self.showingExerciseSelection = true
                        }) {
                            pickerLabel
                                .padding(.trailing)
                                .contentShape(Rectangle()) // Ensure tap area is tightly bound
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevents full-row tap behavior
                    }
                    .padding(.bottom)
                    
                    if let exercisePerformance = exerciseData.allExercisePerformance[selectedExercise] {
                        if let ex = exerciseData.exercise(named: selectedExercise),
                           let max = exercisePerformance.maxValue,
                           let date = exercisePerformance.currentMaxDate {
                            ExercisePerformanceGraph(
                                exercise: ex,
                                value: max,
                                currentMaxDate: date,
                                pastMaxes: exercisePerformance.pastMaxes ?? []
                            )
                        } else {
                            List {
                                Text("No data available for this exercise.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 15)
                            .frame(height: 400)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedExercise) { oldValue, newValue in
            // Only perform side effects if the value has truly changed
            if oldValue != newValue {
                userData.selectedExercise = newValue
                userData.saveSingleVariableToFile(\.selectedExercise, for: .selectedExercise)
            }
        }
        .sheet(isPresented: $showingExerciseSelection) {
            // 3) Present your custom selection view
            ExerciseSelection(
                // We supply an empty array because in "performance" mode we only pick one
                selectedExercises: [],
                onDone: { chosenExercises in
                    // Because forPerformanceView = true, we expect only one exercise
                    if let first = chosenExercises.first {
                        self.selectedExercise = first.name
                    }
                    showingExerciseSelection = false
                },
                forPerformanceView: true // Hides checkboxes & filters out maxValue == 0
            )
        }
    }
    
    private var measurementsGraphSection: some View {
        VStack(alignment: .leading) {
            Picker("Select Measurement", selection: $selectedMeasurement) {
                ForEach(userData.getValidMeasurements()) { measurement in
                    Text(measurement.rawValue).tag(measurement)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .padding(.top, -10)
            .padding(.bottom, 5)
            
            MeasurementsGraph(userData: userData, selectedMeasurement: userData.selectedMeasurement)
        }
        .onChange(of: selectedMeasurement) { old, new in
            if old != new {
                userData.selectedMeasurement = new
                userData.saveSingleVariableToFile(\.selectedMeasurement, for: .selectedMeasurement)
            }
        }
    }
    
    private var pickerLabel: some View {
        HStack(spacing: 5) {
            Text(selectedExercise.isEmpty ? "Select Exercise" : selectedExercise)
                .foregroundColor(.blue)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}




