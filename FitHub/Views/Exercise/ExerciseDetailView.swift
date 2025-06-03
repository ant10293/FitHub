//
//  ExerciseDetailView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// this view is an abomination and must be fixed
struct ExerciseDetailView: View {
    @ObservedObject var exerciseData: ExerciseData
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var equipmentData: EquipmentData
    @EnvironmentObject var csvLoader: CSVLoader
    @State private var showingAdjustmentsView: Bool = false
    @State private var showingUpdate1RMView: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @State private var selectedOption: String = "Standards"
    @State private var selectedSortOption: CompletedExerciseSortOption = .mostRecent
    @State private var showingSortPicker = false
    @State private var showingList: Bool = false
    var viewingDuringWorkout: Bool
    var exercise: Exercise
    var onClose: () -> Void
    @State private var selectedView: String = "About"
    
    var body: some View {
        ZStack {
            VStack {
                if viewingDuringWorkout {
                    HStack {
                        Text("\(exercise.name)").bold()
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 30)
                            .centerHorizontally()
                            .overlay(
                                Button(action: onClose) {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.gray)
                                }
                                    .padding(.bottom, 30)
                                    .padding(.trailing),
                                alignment: .trailing
                            )
                    }
                }
                
                Picker("View", selection: $selectedView) {
                    Text("About").tag("About")
                    Text("History").tag("History")
                    Text("PRs").tag("PRs")
                    Text("Percentile").tag("Percentile")
                }
                .padding(.top, -30)
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedView {
                case "About":
                    aboutView
                case "History":
                    historyView
                case "Percentile":
                    percentileView
                case "PRs":
                    VStack {
                        if showingUpdate1RMView {
                            UpdateMaxView(
                                usesWeight: exercise.usesWeight,
                                onSave: { newOneRepMax in
                                    exerciseData.updateExercisePerformance(for: exercise.name, newValue: newOneRepMax, reps: nil, weight: nil, csvEstimate: false)
                                    exerciseData.savePerformanceData()
                                    showingUpdate1RMView = false
                                    isKeyboardVisible = false
                                },
                                onCancel: {
                                    showingUpdate1RMView = false
                                    isKeyboardVisible = false
                                }
                            )
                        }
                        
                        else if let exercisePerformance = exerciseData.allExercisePerformance[exercise.name],
                                let max = exercisePerformance.maxValue,
                                let date = exercisePerformance.currentMaxDate {
                            
                            if !showingList {
                                ExercisePerformanceGraph(
                                    exercise: exercise,
                                    value: max,
                                    currentMaxDate: date,
                                    pastMaxes: exercisePerformance.pastMaxes ?? []
                                )
                            } else {
                                ExercisePerformanceView(
                                    exercise: exercise,
                                    maxValue: max,
                                    repsXweight: exercisePerformance.repsXweight,
                                    currentMaxDate: date,
                                    pastMaxes: exercisePerformance.pastMaxes ?? []
                                )
                            }
                        }
                        else {
                            // add ability to add one rep maxes
                            List {
                                Text("No data available for this exercise.")
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 15)
                            .frame(height: 300)
                        }
                        if !showingList {
                            if !showingUpdate1RMView {
                                Button(action: {
                                    showingUpdate1RMView = true
                                }) {
                                    HStack {
                                        Text(exercise.usesWeight ? "Update 1 Rep Max" : "Update Max Reps")
                                            .foregroundColor(.white)
                                        Image(systemName: "square.and.pencil")
                                            .foregroundColor(.white)
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }
                    }
                default:
                    aboutView
                }
                Spacer()
            }
            .padding()
        }
        .overlay(!isKeyboardVisible && selectedView == "PRs" && !showingUpdate1RMView ? ListToggleButton(showingList: $showingList) : nil, alignment: .bottomTrailing)
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .overlay(isKeyboardVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationTitle(exercise.name).multilineTextAlignment(.center)
    }
    
    struct ListToggleButton: View {
        @Binding var showingList: Bool
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        
        var body: some View {
            Button(action: {
                showingList.toggle()
            }) {
                Image(systemName: showingList ? "list.bullet.rectangle" : "chart.bar")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
                    .foregroundColor(.blue)
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                    .padding()
            }
            .padding(.leading)
        }
    }
    
    private var aboutView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(exercise.fullImagePath)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 6)) // Apply rounded rectangle shape
                .centerHorizontally()
            //Text("Description: ").bold() + Text(exercise.exDesc)
            Text("How to perform: ").bold() // Placeholder text
            
            Text("Primary Muscles: ").bold()
            primaryMusclesFormatted
                .multilineTextAlignment(.leading)
                .font(.caption)
                .foregroundColor(.secondary)
            // Join all secondary muscles into a single comma-separated string
            Text("Secondary Muscles: ").bold()
            secondaryMusclesFormatted
                .multilineTextAlignment(.leading)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !exercise.equipmentRequired.isEmpty {
                Text("Equipment Required: ").bold()
                HStack {
                    ForEach(exercise.equipmentRequired, id: \.self) { equipmentName in
                        if let equipment = equipmentData.allEquipment.first(where: { $0.name == equipmentName }) {
                            VStack {
                                Image(equipment.fullImagePath)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 6)) // Apply rounded rectangle shape
                                
                                Text(equipment.name.rawValue)
                                    .font(.caption)
                                //  .font(.body)
                                //.padding(.top, -10)
                            }
                        }
                    }
                }
                //.padding(.top, -20)
            }
            
            if equipmentData.hasEquipmentAdjustments(for: exercise) {
                HStack {
                    Spacer()
                    Button(action: {
                        showingAdjustmentsView.toggle()
                    }) {
                        Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                            .foregroundColor(.darkGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                    }
                    .centerHorizontally()
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .sheet(isPresented: $showingAdjustmentsView) {
                        AdjustmentsView(exerciseData: exerciseData, exercise: exercise)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var historyView: some View {
        VStack {
            HStack {
                Text("Sort by").bold()
                    .padding(.trailing)
                Picker("", selection: $selectedSortOption) {
                    ForEach(CompletedExerciseSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing)
            }
            .padding(.bottom, -10)
            .zIndex(0)
            
            List {
                if sortedExercise.isEmpty {
                    Text("No recent sets available for this exercise.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sortedExercise, id: \.self) { workout in
                        VStack(alignment: .leading) {
                            Text("\(workout.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(workout.template.name)")
                            ForEach(workout.template.exercises.filter { $0.name == exercise.name }) { ex in
                                ForEach(ex.setDetails, id: \.self) { set in
                                    let repsCompleted = set.repsCompleted ?? 0
                                    
                                    HStack {
                                        Text("Set \(set.setNumber):").bold()
                                            .font(.caption)
                                        // this implementation sucks but it works
                                        if !ex.usesWeight {
                                            Text("\(repsCompleted) reps completed")
                                                .font(.caption)
                                        } else {
                                            Text("\(smartFormat(set.weight)) lb x \(repsCompleted) reps")
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }
    
    private var primaryMusclesFormatted: Text {
        let primaryEngagements = exercise.primaryMuscleEngagements
        
        let muscleTexts = primaryEngagements.map { engagement -> Text in
            let muscleName = Text("• \(engagement.muscleWorked.rawValue): ").bold() // Bold muscle name with bullet
            
            // Process submuscles using their `simpleName`
            let subMusclesText = engagement.allSubMuscles
                .map { $0.simpleName } // Use simpleName instead of rawValue
                .joined(separator: ", ")
            
            if subMusclesText.isEmpty {
                return muscleName // Only the muscle name if no submuscles exist
            } else {
                return muscleName + Text(subMusclesText) // Append submuscles
            }
        }
        
        guard let firstText = muscleTexts.first else { return Text("None") }
        return muscleTexts.dropFirst().reduce(firstText) { $0 + Text("\n") + $1 }
    }
    
    private var secondaryMusclesFormatted: Text {
        let secondaryEngagements = exercise.secondaryMuscleEngagements
        
        let muscleTexts = secondaryEngagements.map { engagement -> Text in
            let muscleName = Text("• \(engagement.muscleWorked.rawValue): ").bold() // Bold muscle name with bullet
            
            // Process submuscles using their `simpleName`
            let subMusclesText = engagement.allSubMuscles
                .map { $0.simpleName } // Use simpleName instead of rawValue
                .joined(separator: ", ")
            
            if subMusclesText.isEmpty {
                return muscleName // Only the muscle name if no submuscles exist
            } else {
                return muscleName + Text(subMusclesText) // Append submuscles
            }
        }
        
        guard let firstText = muscleTexts.first else { return Text("• None") }
        return muscleTexts.dropFirst().reduce(firstText) { $0 + Text("\n") + $1 }
    }
    
    private var sortedExercise: [CompletedWorkout] {
        let filteredWorkouts = userData.completedWorkouts.filter { workout in
            workout.template.exercises.contains(where: { $0.name == exercise.name })
        }
        
        switch selectedSortOption {
        case .mostRecent:
            return filteredWorkouts.sorted { $0.date > $1.date }
        case .leastRecent:
            return filteredWorkouts.sorted { $0.date < $1.date }
        case .thisWeek:
            let calendar = Calendar.current
            let weekOfYear = calendar.component(.weekOfYear, from: Date())
            return filteredWorkouts.filter {
                calendar.component(.weekOfYear, from: $0.date) == weekOfYear
            }
        case .thisMonth:
            let currentMonth = Calendar.current.component(.month, from: Date())
            return filteredWorkouts.filter {
                Calendar.current.component(.month, from: $0.date) == currentMonth
            }
        case .mostSets:
            return filteredWorkouts.sorted {
                let setsInFirst = $0.template.exercises.reduce(0) { $0 + $1.setDetails.count }
                let setsInSecond = $1.template.exercises.reduce(0) { $0 + $1.setDetails.count }
                return setsInFirst > setsInSecond
            }
        case .leastSets:
            return filteredWorkouts.sorted {
                let setsInFirst = $0.template.exercises.reduce(0) { $0 + $1.setDetails.count }
                let setsInSecond = $1.template.exercises.reduce(0) { $0 + $1.setDetails.count }
                return setsInFirst < setsInSecond
            }
        }
    }
    
    private var percentileView: some View {
        VStack {
            if selectedOption == "Standards" {
                VStack {
                    StrengthPercentileView(csvLoader: csvLoader, userData: userData, exerciseData: exerciseData, exercise: exercise)
                }
            } else if selectedOption == "Percentages" {
                let oneRepMax = exerciseData.getMax(for: exercise.name) ?? 0.0
                
                VStack {
                    Text("1RM Percentages")
                        .font(.title2)
                        .padding(.vertical)
                    
                    Text("Use this table to determine your working weight for each rep range.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                        .padding(.horizontal, 25)
                    
                    Section {
                        MaxRecordTable(oneRepMax: oneRepMax)
                    }
                    .padding(.vertical)
                }
            }
            Picker("Options", selection: $selectedOption) {
                Text("Standards").tag("Standards")
                Text("Percentages").tag("Percentages")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
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
}
