//
//  ExerciseDetailView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

// this view is an abomination and must be fixed
struct ExerciseDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @StateObject private var kbd = KeyboardManager.shared
    @State private var showingAdjustmentsView: Bool = false
    @State private var showingUpdate1RMView: Bool = false
    @State private var showingSortPicker: Bool = false
    @State private var showingList: Bool = false
    @State private var editingExercise: Bool = false
    @State private var selectedOption: String = "Standards"
    @State private var selectedView: Views = .about
    var viewingDuringWorkout: Bool
    var exercise: Exercise
    
    var body: some View {
        VStack {
            if viewingDuringWorkout {
                workoutToolbar
            }
            
            Picker("View", selection: $selectedView) {
                ForEach(Views.allCases) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .padding(.horizontal)
            .pickerStyle(SegmentedPickerStyle())
            
            Group {
                switch selectedView {
                case .about:
                    aboutView
                case .history:
                    historyView(
                        completedWorkouts: ctx.userData.workoutPlans.completedWorkouts,
                        exerciseId: exercise.id
                    )
                case .percentile:
                    percentileView
                case .prs:
                    PRsView
                }
            }
            .padding()
            
            Spacer()
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationTitle(exercise.name).multilineTextAlignment(.center)
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
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
    
    private enum Views: String, CaseIterable, Identifiable {
        case about = "About"
        case history = "History"
        case prs = "PRs"
        case percentile = "Percentile"
        
        var id: String { self.rawValue }
    }
        
    private var workoutToolbar: some View {
        HStack {
            Text("\(exercise.name)").bold()
                .frame(maxWidth: UIScreen.main.bounds.width * 0.66)  // ≈ 2/3 screen
                .multilineTextAlignment(.center)
                .centerHorizontally()
                .overlay(
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(.gray)
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
                ExEquipImage(image: exercise.fullImage, button: .expand)
                    .centerHorizontally()

                //Text("Description: ").bold() + Text(exercise.description)
                Text("How to perform: ").bold() // Placeholder text
                
                if let limbMovementType = exercise.limbMovementType {
                    limbMovementType.displayInfoText
                }
                
                Text("Difficulty: ").bold() + Text(exercise.difficulty.fullName)
                
                Text("Primary Muscles: ").bold()
                exercise.primaryMusclesFormatted
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                
                
                // Join all secondary muscles into a single comma-separated string
                Text("Secondary Muscles: ").bold()
                exercise.secondaryMusclesFormatted
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                
                if !exercise.equipmentRequired.isEmpty {
                    let equipment = ctx.equipment.equipmentForExercise(exercise)
                    EquipmentScrollRow(equipment: equipment, title: "Equipment Required")
                }
                
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    Button(action: { showingAdjustmentsView.toggle() }) {
                        Label("Equipment Adjustments", systemImage: "slider.horizontal.3")
                            .foregroundStyle(.green)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
    
    struct historyView: View {
        @State private var selectedSortOption: CompletedExerciseSortOption = .mostRecent
        let completedWorkouts: [CompletedWorkout]
        let exerciseId: UUID

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
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        ForEach(sortedExercise, id: \.self) { workout in
                            VStack(alignment: .leading) {
                                Text("\(workout.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text("\(workout.template.name)")
                                ForEach(workout.template.exercises.filter { $0.id == exerciseId }) { ex in
                                    ForEach(ex.setDetails, id: \.self) { set in
                                        set.formattedCompletedText(usesWeight: ex.type.usesWeight)
                                            .font(.caption)
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
                workout.template.exercises.contains(where: { $0.id == exerciseId })
            }
            
            switch selectedSortOption {
            case .mostRecent:
                return filteredWorkouts.sorted { $0.date > $1.date }
            case .leastRecent:
                return filteredWorkouts.sorted { $0.date < $1.date }
            case .thisWeek:
                let weekOfYear = CalendarUtility.shared.weekOfYear(from: Date())
                return filteredWorkouts.filter {
                    CalendarUtility.shared.weekOfYear(from: $0.date) == weekOfYear
                }
            case .thisMonth:
                let currentMonth = CalendarUtility.shared.month(from: Date())
                return filteredWorkouts.filter {
                    CalendarUtility.shared.month(from: $0.date) == currentMonth
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
            let maxValue = ctx.exercises.peakMetric(for: exercise.id) ?? exercise.getPeakMetric(metricValue: 0)
            let bw = Mass(kg: ctx.userData.currentMeasurementValue(for: .weight).actualValue)
            if selectedOption == "Standards" {
                VStack {
                    StrengthPercentileView(
                        maxValue: maxValue,
                        age: ctx.userData.profile.age,
                        bodyweight: bw,
                        gender: ctx.userData.physical.gender,
                        exercise: exercise,
                        maxValuesAge: CSVLoader.getMaxValues(for: exercise, key: .age, value: Double(ctx.userData.profile.age), userData: ctx.userData),
                        maxValuesBW: CSVLoader.getMaxValues(for: exercise, key: .bodyweight, value: bw.inKg, userData: ctx.userData),
                        percentile: CSVLoader.calculateExercisePercentile(for: exercise, maxValue: maxValue.actualValue, userData: ctx.userData)
                    )
                }
            } else if selectedOption == "Percentages" {
                VStack {
                    Text("\(exercise.performanceTitle) Percentages")
                        .font(.title2)
                        .padding(.vertical)
                    
                    Text(maxValue.percentileHeader)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                        .padding(.horizontal, 25)
                    
                    Section {
                        MaxTable(peak: maxValue)
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
                ExercisePerformanceGraph(exercise: exercise, performance: perf)
            } else {
                ExercisePerformanceView(
                    exercise: exercise,
                    performance: perf,
                    onDelete: { entryID in
                        ctx.exercises.deleteEntry(id: entryID, exercise: exercise)
                    },
                    onSetMax: { entryID in
                        ctx.exercises.setAsCurrentMax(id: entryID, exercise: exercise)
                    }
                )
            }
            
            if !showingUpdate1RMView {
                RectangularButton(
                    title: "Update Max",
                    systemImage: "square.and.pencil",
                    width: .fit,
                    action: {
                        showingUpdate1RMView = true
                    }
                )
                .clipShape(.capsule)
                .padding(.vertical)
            }
        }
        .overlay(alignment: .center) {
            if showingUpdate1RMView {
                UpdateMaxEditor(
                    exercise: exercise,
                    onSave: { newMax in
                        ctx.exercises.updateExercisePerformance(for: exercise, newValue: newMax)
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
