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
    @State private var showingUpdate1RMView: Bool = false
    @State private var showingSortPicker: Bool = false
    @State private var showingList: Bool = false
    @State private var editingExercise: Bool = false
    @State private var selectedOption: String = "Standards"
    @State private var selectedView: Views = .about
    let viewingDuringWorkout: Bool
    let exercise: Exercise
    
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
                    AboutView(exercise: exercise)
                case .history:
                    ExerciseHistory(
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
                    Text("\(exercise.performanceTitle(includeInstruction: false)) Percentages")
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

private struct AboutView: View {
    @EnvironmentObject private var ctx: AppContext
    @State private var showingAdjustmentsView: Bool = false
    private let modifier = ExerciseModifier()
    let exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ExEquipImage(image: exercise.fullImage, button: .expand)
                    .centerHorizontally()
                
                RatingIcon(
                    exercise: exercise,
                    favState: FavoriteState.getState(for: exercise, userData: ctx.userData),
                    size: .large,
                    onFavorite: {
                        modifier.toggleFavorite(for: exercise.id, userData: ctx.userData)
                    },
                    onDislike: {
                        modifier.toggleDislike(for: exercise.id, userData: ctx.userData)
                    }
                )
                .centerHorizontally()

                Text("How to perform: ").bold() // Placeholder text
                Group {
                    if let printedInstructions = exercise.instructions.formattedString() {
                        Text(printedInstructions)
                    } else {
                        Text("No instructions available.")
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.bottom)
                
                if let limbMovementType = exercise.limbMovementType {
                    limbMovementType.displayInfoText
                        .padding(.bottom)
                }
                
                (Text("Difficulty: ").bold() + Text(exercise.difficulty.fullName))
                    .padding(.bottom)
                
                if !exercise.primaryMuscleEngagements.isEmpty {
                    Text("Primary Muscles: ").bold()
                    exercise.primaryMusclesFormatted
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                if !exercise.secondaryMuscleEngagements.isEmpty {
                    Text("Secondary Muscles: ").bold()
                    exercise.secondaryMusclesFormatted
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                if !exercise.equipmentRequired.isEmpty {
                    let equipment = ctx.equipment.equipmentForExercise(exercise)
                    EquipmentScrollRow(equipment: equipment, title: "Equipment Required")
                        .padding(.vertical)
                }
                
                if ctx.equipment.hasEquipmentAdjustments(for: exercise) {
                    LabelButton(
                        title: "Equipment Adjustments",
                        systemImage: "slider.horizontal.3",
                        tint: .green,
                        controlSize: .large,
                        action: { showingAdjustmentsView.toggle() }
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAdjustmentsView) {
            AdjustmentsView(exercise: exercise)
        }
    }
}
