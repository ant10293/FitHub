//
//  ExerciseDetailView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// this view is an abomination and must be fixed
struct ExerciseDetailView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showingAdjustmentsView: Bool = false
    @State private var showingUpdate1RMView: Bool = false
    @State private var showingSortPicker = false
    @State private var showingList: Bool = false
    @State private var editingExercise: Bool = false
    @State private var selectedOption: String = "Standards"
    @State private var selectedView: String = "About"
    var viewingDuringWorkout: Bool
    var exercise: Exercise
    var onClose: () -> Void = {}
    
    var body: some View {
        VStack {
            if viewingDuringWorkout {
                workoutToolbar
            }
            
            Picker("View", selection: $selectedView) {
                Text("About").tag("About")
                Text("History").tag("History")
                Text("PRs").tag("PRs")
                Text("Percentile").tag("Percentile")
            }
            .padding(.horizontal)
            .pickerStyle(SegmentedPickerStyle())
            
            Group {
                switch selectedView {
                case "About":
                    aboutView
                case "History":
                    historyView(completedWorkouts: ctx.userData.workoutPlans.completedWorkouts, exerciseName: exercise.name)
                case "Percentile":
                    percentileView
                case "PRs":
                    PRsView
                default:
                    aboutView
                }
            }
            .padding()
            
            Spacer()
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationTitle(exercise.name).multilineTextAlignment(.center)
        .sheet(isPresented: $showingAdjustmentsView, onDismiss: { showingAdjustmentsView = false }) {
            AdjustmentsView(AdjustmentsData: ctx.adjustments, exercise: exercise)
        }
        .sheet(isPresented: $editingExercise) { NewExercise(original: exercise) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingExercise = true
                } label: {
                    Image(systemName: "square.and.pencil")   // notepad-with-pencil icon
                }
            }
        }
    }
    
    private var workoutToolbar: some View {
        HStack {
            Text("\(exercise.name)").bold()
                .frame(maxWidth: UIScreen.main.bounds.width * 0.66)  // ≈ 2/3 screen
                .multilineTextAlignment(.center)
                .centerHorizontally()
                .overlay(
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing),
                    alignment: .trailing
                )
        }
        .padding(.vertical)
    }
    
    private var aboutView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ExEquipImage(exercise.fullImage, infoCircle: false)
                    .centerHorizontally()
                
                //Text(exercise.description)
                 //   .multilineTextAlignment(.leading)

                //Text("Description: ").bold() + Text(exercise.description)
                Text("How to perform: ").bold() // Placeholder text
                
                Text("Primary Muscles: ").bold()
                exercise.primaryMusclesFormatted
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Join all secondary muscles into a single comma-separated string
                Text("Secondary Muscles: ").bold()
                exercise.secondaryMusclesFormatted
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !exercise.equipmentRequired.isEmpty {
                    Text("Equipment Required: ").bold()
                    ScrollView(.horizontal) {
                        LazyHStack {
                            let size: CGFloat = UIScreen.main.bounds.height * 0.1
                            
                            ForEach(exercise.equipmentRequired, id: \.self) { equipmentName in
                                if let equipment = ctx.equipment.allEquipment.first(where: {
                                    normalize($0.name) == normalize(equipmentName)
                                }) {
                                    VStack {
                                        equipment.fullImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: size, height: size)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        
                                        Text(equipment.name)          // ← no .rawValue anymore
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                }
                
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    Button(action: { showingAdjustmentsView.toggle() }) {
                        Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                            .foregroundColor(.green)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .centerHorizontally()
                }
                
                Spacer()

            }
        }
    }
    
    struct historyView: View {
        @State private var selectedSortOption: CompletedExerciseSortOption = .mostRecent
        let completedWorkouts: [CompletedWorkout]
        let exerciseName: String

        var body: some View {
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
                            .padding()
                    } else {
                        ForEach(sortedExercise, id: \.self) { workout in
                            VStack(alignment: .leading) {
                                Text("\(workout.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(workout.template.name)")
                                ForEach(workout.template.exercises.filter { $0.name == exerciseName }) { ex in
                                    ForEach(ex.setDetails, id: \.self) { set in
                                        let repsCompleted = set.repsCompleted ?? 0
                                        
                                        HStack {
                                            Text("Set \(set.setNumber):").bold()
                                                .font(.caption)
                                            // this implementation sucks but it works
                                            if !ex.type.usesWeight {
                                                Text("\(repsCompleted) reps completed")
                                                    .font(.caption)
                                            } else {
                                                Text("\(Format.smartFormat(set.weight)) lb x \(repsCompleted) reps")
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
        
        private var sortedExercise: [CompletedWorkout] {
            let filteredWorkouts = completedWorkouts.filter { workout in
                workout.template.exercises.contains(where: { $0.name == exerciseName })
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
    }
    
    private var percentileView: some View {
        VStack {
            let maxValue = ctx.exercises.getMax(for: exercise.id) ?? 0.0

            if selectedOption == "Standards" {
                VStack {
                    StrengthPercentileView(
                        maxValue: maxValue,
                        age: ctx.userData.profile.age,
                        weight: ctx.userData.currentMeasurementValue(for: .weight),
                        gender: ctx.userData.physical.gender,
                        exercise: exercise,
                        maxValuesAge: CSVLoader.get1RMValues(for: exercise.url, key: "Age", value: Double(ctx.userData.profile.age), userData: ctx.userData),
                        maxValuesBW: CSVLoader.get1RMValues(for: exercise.url, key: "BW", value: ctx.userData.currentMeasurementValue(for: .weight), userData: ctx.userData),
                        percentile: CSVLoader.calculateExercisePercentile(userData: ctx.userData, exercise: exercise, maxValue: maxValue),
                    )
                }
            } else if selectedOption == "Percentages" {
                let usesWeight = exercise.type.usesWeight
                    VStack {
                        Text(usesWeight ? "1RM Percentages" : "Max Rep Percentages")
                            .font(.title2)
                            .padding(.vertical)
                        
                        Text(usesWeight ?
                             "Use this table to determine your working weight for each rep range."
                             : "Use this table to determine your working reps based on exertion percentage.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                            .padding(.horizontal, 25)
                        
                        Section {
                            if usesWeight {
                                OneRMTable(oneRepMax: maxValue)
                            } else {
                                MaxRepsTable(maxReps: Int(maxValue))
                            }
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
    
    private var PRsView: some View {
        VStack {
            let perf = ctx.exercises.allExercisePerformance[exercise.id]
            if !showingList {
                ExercisePerformanceGraph(
                    exercise: exercise,
                    value: perf?.maxValue,
                    currentMaxDate: perf?.currentMaxDate,
                    pastMaxes: perf?.pastMaxes ?? []
                )
            } else {
                ExercisePerformanceView(
                    exercise: exercise,
                    maxValue: perf?.maxValue,
                    repsXweight: perf?.repsXweight,
                    currentMaxDate: perf?.currentMaxDate,
                    pastMaxes: perf?.pastMaxes ?? []
                )
            }
            
            if !showingList, !showingUpdate1RMView {
                Button(action: { showingUpdate1RMView = true }) {
                    HStack {
                        Text(exercise.type.usesWeight ? "Update 1 Rep Max" : "Update Max Reps")
                            .foregroundColor(.white)
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .padding(.vertical)
                
                Spacer()
            }
        }
        .overlay(alignment: .center) {
            if showingUpdate1RMView {
                UpdateMaxView(
                    usesWeight: exercise.type.usesWeight,
                    onSave: { newOneRepMax in
                        ctx.exercises.updateExercisePerformance(for: exercise, newValue: newOneRepMax, reps: nil, weight: nil, csvEstimate: false)
                        ctx.exercises.savePerformanceData()
                        showingUpdate1RMView = false
                        kbd.dismiss()
                    },
                    onCancel: {
                        showingUpdate1RMView = false
                        kbd.dismiss()
                    }
                )
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !kbd.isVisible && !showingUpdate1RMView {
                FloatingButton(
                    image: showingList ? "chart.bar" : "list.bullet.rectangle",
                    foreground: .blue,
                    background: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white,
                    action: {
                        showingList.toggle()
                    }
                )
            }
        }
    }
}
