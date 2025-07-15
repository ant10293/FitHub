//
//  WorkoutCustomization.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/11/25.
//

import SwiftUI


struct WorkoutCustomization: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingDayPicker: Bool = false
    @State private var showingSplitSelection: Bool = false
    @State private var showAlert: Bool = false
    @State private var showingResetAlert: Bool = false // State variable for showing the post-reset alert
    @State private var keepCurrentExercises: Bool = false
    @State private var daysPerWeek: Int = 3
    @State private var numberOfSets: Int = 3
    @State private var midpointReps: Int = 8
    @State private var rangeWidth: Int = 4
    @State private var selectedResistanceType: ResistanceType = .any
    @State private var selectedDays: [daysOfWeek] = []
    @State private var selectedSetStructure: SetStructures = .pyramid

    var body: some View {
        Form {
            Section {
                daysOfWeekSelector
                setsSelector
                repsSelector
                repsRangeSelector
                setStructureSelector
                keepCurrentExercisesToggle
                ResistanceTypeSelector
            } header: {
                Text("Generation Parameters")
            }
            
            Section {
                splitSelector
                workoutDaysSelector
            } footer: {
                ActionButton(title: "Reset to Defaults", enabled: !isDefault, color: .red, action: resetToDefaults)
                    .clipShape(Capsule())
                    .padding(.vertical, 30)
            }
        }
        .onAppear(perform: initializeVariables)
        .onChange(of: ctx.userData.workoutPrefs) { ctx.userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs) }
        .sheet(isPresented: $showingSplitSelection) { SplitSelection(userData: ctx.userData) }
        .sheet(isPresented: $showingDayPicker) { DayPickerView(selectedDays: $selectedDays, numDays: $daysPerWeek) }
        .background(Color(UIColor.systemGroupedBackground))
        .alert("Customization Reset", isPresented: $showingResetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All settings have been reset to their default values.")
        }
    }
    
    private var daysOfWeekSelector: some View {
        Picker("Workout Days per Week", selection: $daysPerWeek) {
            ForEach(2...6, id: \.self) {
                Text("\($0) days")
            }
        }
        .onChange(of: daysPerWeek) { oldValue, newValue in
            if oldValue != newValue {
                //print("workoutDaysPerWeek changed")
                ctx.userData.workoutPrefs.workoutDaysPerWeek = newValue
                selectedDays = daysOfWeek.resolvedWorkoutDays(customWorkoutDays: ctx.userData.workoutPrefs.customWorkoutDays, workoutDaysPerWeek: daysPerWeek)
            }
        }
    }
    
    private var setsSelector: some View {
        Stepper("Number of Sets: \(numberOfSets)", value: $numberOfSets, in: 1...10)
        .onChange(of: numberOfSets) { oldValue, newValue in
            if oldValue != newValue {
                //print("numberOfSets changed")
                if newValue == defaultRepsAndSets.sets {
                    ctx.userData.workoutPrefs.customSets = nil
                } else {
                    ctx.userData.workoutPrefs.customSets = newValue
                }
            }
        }
    }
    
    private var repsSelector: some View {
        HStack {
            Text("Rep Range: \(midpointReps)-\(midpointReps + rangeWidth)")
            Slider(value: Binding(
                get: { Double(midpointReps) },
                set: { newValue in
                    midpointReps = Int(newValue)
                }
            ), in: 1...20, step: 1)
        }
        .onChange(of: midpointReps) { oldValue, newValue in
            if oldValue != newValue {
                //print("midpointReps changed")
                if newValue == defaultRepsAndSets.repsRange.lowerBound && rangeWidth == (defaultRepsAndSets.repsRange.upperBound - defaultRepsAndSets.repsRange.lowerBound) {
                    ctx.userData.workoutPrefs.customRepsRange = nil
                } else {
                    ctx.userData.workoutPrefs.customRepsRange = (newValue)...(newValue+rangeWidth)
                }
            }
        }
    }
    
    private var repsRangeSelector: some View {
        Stepper("Range Width: \(rangeWidth)", value: $rangeWidth, in: 1...10)
        .onChange(of: rangeWidth) { oldValue, newValue in
            if oldValue != newValue  {
                //print("rangeWidth changed")
                if newValue == (defaultRepsAndSets.repsRange.upperBound - defaultRepsAndSets.repsRange.lowerBound) && midpointReps == defaultRepsAndSets.repsRange.lowerBound {
                    ctx.userData.workoutPrefs.customRepsRange = nil
                } else {
                    ctx.userData.workoutPrefs.customRepsRange = (midpointReps)...(midpointReps+newValue)
                }
            }
        }
    }
    
    private var setStructureSelector: some View {
        VStack {
            Picker("Set-weight Structure", selection: $selectedSetStructure) {
                ForEach(SetStructures.allCases, id: \.self) { structure in
                    Text(structure.rawValue)
                }
            }
            Text(selectedSetStructure.desc)
                .font(.caption)
                .frame(alignment: .leading)
        }
        .onChange(of: selectedSetStructure) { oldValue, newValue in
            if oldValue != newValue {
                //print("setStructure changed")
                ctx.userData.workoutPrefs.setStructure = newValue
            }
        }
    }
    
    private var keepCurrentExercisesToggle: some View {
        Toggle("Keep current Exercises", isOn: $keepCurrentExercises) // Add this line
        .onChange(of: keepCurrentExercises) { oldValue, newValue in
            if oldValue != newValue {
                //print("keepCurrentExercises changed")
                ctx.userData.workoutPrefs.keepCurrentExercises = newValue
            }
        }
    }
    
    private var ResistanceTypeSelector: some View {
        Picker("Resistance Type", selection: $selectedResistanceType) {
            ForEach(ResistanceType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .onChange(of: selectedResistanceType) { oldValue, newValue in
            if oldValue != newValue {
                //print("ResistanceType changed")
                ctx.userData.workoutPrefs.ResistanceType = newValue
            }
        }
    }
    
    private var splitSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingSplitSelection = true }) {
                HStack {
                    Text("Customize Split")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var workoutDaysSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingDayPicker = true }) {
                HStack {
                    Text("Select Workout Days")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 0) {
                ForEach(Array(selectedDays.sorted().enumerated()), id: \.element) { index, day in
                    Text(day.shortName)
                        .tag(day)
                        .bold()
                    
                    if index < selectedDays.count - 1 {
                        Text(", ") // Adds a comma after each day except the last one
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedDays) { oldValue, newValue in
            if oldValue != newValue {
                //print("selectedDays changed")
                if !newValue.isEmpty, newValue != daysOfWeek.defaultDays(for: ctx.userData.workoutPrefs.workoutDaysPerWeek) {
                    ctx.userData.workoutPrefs.customWorkoutDays = newValue
                    if newValue.count != daysPerWeek { daysPerWeek = newValue.count }
                } else {
                    ctx.userData.workoutPrefs.customWorkoutDays = nil
                }
            }
        }
    }
    
    private var defaultRepsAndSets: RepsAndSets {
        FitnessGoal.getRepsAndSets(for: ctx.userData.physical.goal, restPeriod: ctx.userData.workoutPrefs.customRestPeriod ?? FitnessGoal.determineRestPeriod(for: ctx.userData.physical.goal))
    }
    
    private var customRepsRange: ClosedRange<Int> {
        ctx.userData.workoutPrefs.customRepsRange ?? defaultRepsAndSets.repsRange
    }
    
    private func initializeVariables() {
        daysPerWeek = ctx.userData.workoutPrefs.workoutDaysPerWeek
        selectedDays = ctx.userData.workoutPrefs.customWorkoutDays ?? daysOfWeek.defaultDays(for: ctx.userData.workoutPrefs.workoutDaysPerWeek)
        numberOfSets = ctx.userData.workoutPrefs.customSets ?? defaultRepsAndSets.sets
        midpointReps = customRepsRange.lowerBound
        rangeWidth = customRepsRange.upperBound - customRepsRange.lowerBound
        keepCurrentExercises = ctx.userData.workoutPrefs.keepCurrentExercises
        selectedResistanceType = ctx.userData.workoutPrefs.ResistanceType
        selectedSetStructure = ctx.userData.workoutPrefs.setStructure
    }
    
    private func resetToDefaults() {
        ctx.userData.workoutPrefs.customRepsRange = nil
        ctx.userData.workoutPrefs.customSets = nil
        ctx.userData.workoutPrefs.customWorkoutDays = nil
        ctx.userData.workoutPrefs.customWorkoutSplit = nil
        ctx.userData.workoutPrefs.keepCurrentExercises = false
        ctx.userData.workoutPrefs.ResistanceType = .any
        ctx.userData.workoutPrefs.setStructure = .pyramid
        
        ctx.userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs)
        
        initializeVariables()

        showingResetAlert = true
    }
    
    private var isDefault: Bool {
        let pref = ctx.userData.workoutPrefs
        return (
            pref.customRepsRange == nil
            && pref.customSets == nil
            && pref.customWorkoutDays == nil
            && pref.customWorkoutSplit == nil
            && pref.keepCurrentExercises == false
            && pref.ResistanceType == .any
            && pref.setStructure == .pyramid
        )
    }
}


