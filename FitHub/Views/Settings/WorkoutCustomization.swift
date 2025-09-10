//
//  WorkoutCustomization.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/11/25.
//

import SwiftUI


struct WorkoutCustomization: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var ctx: AppContext
    @State private var showingDayPicker: Bool = false
    @State private var showingTimePicker: Bool = false
    @State private var showingSplitSelection: Bool = false
    @State private var showAlert: Bool = false
    @State private var keepCurrentExercises: Bool = false
    @State private var isDurationExpanded = false
    @State private var daysPerWeek: Int = 3
    @State private var selectedResistanceType: ResistanceType = .any
    @State private var selectedDays: [DaysOfWeek] = []
    @State private var selectedSetStructure: SetStructures = .pyramid
    @State private var duration: TimeSpan = .hrMinToSec(hours: 1, minutes: 0)
    
    var body: some View {
        VStack {
            if ctx.toast.showingSaveConfirmation { InfoBanner(text: "Restored Default Preferences!") }
            
            Form {
                Section {
                    DaysOfWeekSelector
                    setsSelector
                    repsSelector
                    setStructureSelector
                    ResistanceTypeSelector
                    distributionSelector
                    workoutDurationSelector
                    keepCurrentExercisesToggle
                }
                
                Section {
                    splitSelector
                    workoutDaysSelector
                    if !ctx.userData.settings.useDateOnly {
                        workoutTimesSelector
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("Generation Parameters", displayMode: .inline)
        .onAppear(perform: initializeVariables)
        .onChange(of: ctx.userData.workoutPrefs) { ctx.userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs) }
        .sheet(isPresented: $showingSplitSelection) { SplitSelection(vm: SplitSelectionVM(userData: ctx.userData)) }
        .sheet(isPresented: $showingDayPicker) { DaysEditor(selectedDays: $selectedDays, numDays: $daysPerWeek) }
        .sheet(isPresented: $showingTimePicker) { TimesEditor(userData: ctx.userData, days: selectedDays) }
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button("Reset") { resetToDefaults() }
                .disabled(isDefault)
                .foregroundStyle(isDefault ? .gray : .red)
        }}
    }
    
    private var DaysOfWeekSelector: some View {
        Picker("Workout Days per Week", selection: $daysPerWeek) {
            ForEach(2...6, id: \.self) {
                Text("\($0) days")
            }
        }
        .onChange(of: daysPerWeek) { oldValue, newValue in
            if oldValue != newValue {
                //print("workoutDaysPerWeek changed")
                ctx.userData.workoutPrefs.workoutDaysPerWeek = newValue
                selectedDays = DaysOfWeek.resolvedWorkoutDays(customWorkoutDays: ctx.userData.workoutPrefs.customWorkoutDays, workoutDaysPerWeek: daysPerWeek)
            }
        }
    }

    private var setsSelector: some View {
        let defaultRange = defaultRepsAndSets.sets
        let binding = Binding(
            get: { ctx.userData.workoutPrefs.customSets ?? defaultRange },
            set: { newVal in
                ctx.userData.workoutPrefs.customSets = (newVal == defaultRange) ? nil : newVal
            }
        )
        
        let summary = (ctx.userData.workoutPrefs.customSets ?? defaultRange).formattedTotalRange(filteredBy: distribution)

        return DisclosureGroup {
            SetCountEditor(sets: binding, effort: distribution)
            .listRowSeparator(.hidden, edges: .top)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text("Sets per Exercise")
                Spacer()
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .tint(.gray)
    }
    
    private var repsSelector: some View {
        let defaultRange = defaultRepsAndSets.reps
        let binding = Binding(
            get: { ctx.userData.workoutPrefs.customRepsRange ?? defaultRange },
            set: { newVal in
                ctx.userData.workoutPrefs.customRepsRange = (newVal == defaultRange) ? nil : newVal
            }
        )
        
        let summary = (ctx.userData.workoutPrefs.customRepsRange ?? defaultRange).formattedTotalRange(filteredBy: distribution)

        return DisclosureGroup {
            RepRangeEditor(reps: binding, effort: distribution)
                .listRowSeparator(.hidden, edges: .top)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text("Rep Ranges")
                Spacer()
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .tint(.gray)
    }

    private var setStructureSelector: some View {
        VStack {
            Picker("Set Structure", selection: $selectedSetStructure) {
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
    
    private var distributionSelector: some View {
        DisclosureGroup("Effort Distribution") {
            let defaultDist = ctx.userData.physical.goal.defaultDistribution
            DistributionEditor(
                distribution: Binding(
                    get: { ctx.userData.workoutPrefs.customDistribution ?? defaultDist },
                    set: { newDist in
                        ctx.userData.workoutPrefs.customDistribution = (newDist == defaultDist) ? nil : newDist
                    }
                )
            )
            .listRowSeparator(.hidden, edges: .top)
        }
        .tint(.gray)
    }
        
    private var workoutDurationSelector: some View {
        DisclosureGroup(isExpanded: $isDurationExpanded) {
            DurationPicker(time: $duration, hourRange: 0...2, minuteStep: 15)
                .listRowSeparator(.hidden, edges: .top)
                .padding(.trailing)
                .overlay(alignment: .top, content: {
                    if duration.inMinutes < 15 {
                        Text("Invalid Duration (< 15 min) will not be used.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                })
        } label: {
            HStack {
                Text("Workout Duration")
                Spacer()
                Text(duration.inMinutes < 15 ? defaultDuration.displayString : duration.displayString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle()) // makes the whole row tappable
        }
        .tint(.gray) // makes the disclosure arrow gray
        .onChange(of: duration.inMinutes) { oldValue, newValue in
            if oldValue != newValue {
                if newValue == defaultDuration.inMinutes || newValue < 15 {
                    ctx.userData.workoutPrefs.customDuration = nil
                } else {
                    ctx.userData.workoutPrefs.customDuration = newValue
                }
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
    
    private var splitSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingSplitSelection = true }) {
                HStack {
                    Text("Customize Split")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    
    private var workoutDaysSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingDayPicker = true }) {
                HStack {
                    Text("Select Workout Days")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            DaysOfWeek.dayListText(selectedDays)
                .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedDays) { oldValue, newValue in
            if oldValue != newValue {
                //print("selectedDays changed")
                if !newValue.isEmpty, newValue != DaysOfWeek.defaultDays(for: ctx.userData.workoutPrefs.workoutDaysPerWeek) {
                    ctx.userData.workoutPrefs.customWorkoutDays = newValue
                    if newValue.count != daysPerWeek { daysPerWeek = newValue.count }
                } else {
                    ctx.userData.workoutPrefs.customWorkoutDays = nil
                }
            }
        }
    }
    
    private var workoutTimesSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingTimePicker = true }) {
                HStack {
                    Text("Select Workout Times")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    
    private var distribution: ExerciseDistribution {
        ctx.userData.workoutPrefs.customDistribution ?? defaultRepsAndSets.distribution
    }
    
    private var defaultRepsAndSets: RepsAndSets { RepsAndSets.defaultRepsAndSets(for: ctx.userData.physical.goal) }
    
    private var defaultDuration: TimeSpan {
        WorkoutParams.defaultWorkoutDuration(
            age: ctx.userData.profile.age,
            frequency: ctx.userData.workoutPrefs.workoutDaysPerWeek,
            strengthLevel: ctx.userData.evaluation.strengthLevel,
            goal: ctx.userData.physical.goal
        )
    }
    
    private func initializeVariables() {
        daysPerWeek = ctx.userData.workoutPrefs.workoutDaysPerWeek
        selectedDays = ctx.userData.workoutPrefs.customWorkoutDays ?? DaysOfWeek.defaultDays(for: ctx.userData.workoutPrefs.workoutDaysPerWeek)
        keepCurrentExercises = ctx.userData.workoutPrefs.keepCurrentExercises
        selectedResistanceType = ctx.userData.workoutPrefs.ResistanceType
        selectedSetStructure = ctx.userData.workoutPrefs.setStructure
        duration.setMin(minutes: ctx.userData.workoutPrefs.customDuration ?? defaultDuration.inMinutes)
    }
    
    private func resetToDefaults() {
        ctx.userData.workoutPrefs.customRepsRange = nil
        ctx.userData.workoutPrefs.customSets = nil
        ctx.userData.workoutPrefs.customWorkoutDays = nil
        ctx.userData.workoutPrefs.customWorkoutSplit = nil
        ctx.userData.workoutPrefs.keepCurrentExercises = false
        ctx.userData.workoutPrefs.ResistanceType = .any
        ctx.userData.workoutPrefs.setStructure = .pyramid
        ctx.userData.workoutPrefs.customDuration = nil
        ctx.userData.workoutPrefs.customDistribution = nil
        ctx.userData.workoutPrefs.customWorkoutTimes = nil
        
        ctx.userData.saveSingleStructToFile(\.workoutPrefs, for: .workoutPrefs)
        
        initializeVariables()

        ctx.toast.showSaveConfirmation()
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
            && pref.customDuration == nil
            && pref.customDistribution == nil
            && pref.customWorkoutTimes == nil
        )
    }
}

