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
    @State private var showingWarmupSettings: Bool = false
    @State private var showingSetIntensity: Bool = false
    @State private var showingWeightIncrementation: Bool = false
    @State private var showingSupersetSettings: Bool = false
    @State private var showAlert: Bool = false
    @State private var keepCurrentExercises: Bool = false
    @State private var isDurationExpanded: Bool = false
    @State private var daysPerWeek: Int = 3
    @State private var selectedResistanceType: ResistanceType = .any
    @State private var selectedDays: [DaysOfWeek] = []
    @State private var selectedSetStructure: SetStructures = .pyramid
    @StateObject private var toast = ToastManager()

    var body: some View {
        VStack {
            if toast.showingSaveConfirmation { InfoBanner(title: "Restored Default Preferences!") }

            Form {
                // Section 1: Generation Parameters
                Section {
                    daysOfWeekSelector
                    resistanceTypeSelector
                    workoutDurationSelector
                    keepCurrentExercisesToggle
                } header: {
                    Text("General")
                }

                // Section 2: Schedule
                Section {
                    splitSelector
                    workoutDaysSelector
                    if !ctx.userData.settings.useDateOnly {
                        workoutTimesSelector
                    }
                } header: {
                    Text("Scheduling")
                }

                // Section 3: Set Configuration
                Section {
                    distributionSelector
                    setsSelector
                    warmupSettingsSelector
                    repsSelector
                    setStructureSelector
                    setIntensitySelector
                    roundingSelector
                    supersetSettingsSelector
                } header: {
                    Text("Advanced")
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("Generation Parameters", displayMode: .inline)
        .onAppear(perform: initializeVariables)
        .sheet(isPresented: $showingSplitSelection) { SplitSelection(vm: SplitSelectionVM(userData: ctx.userData)) }
        .sheet(isPresented: $showingDayPicker) { DaysEditor(selectedDays: $selectedDays, numDays: $daysPerWeek) }
        .sheet(isPresented: $showingTimePicker) { TimesEditor(userData: ctx.userData, days: selectedDays) }
        .sheet(isPresented: $showingWarmupSettings) { WarmupSettingsView(userData: ctx.userData) }
        .sheet(isPresented: $showingSetIntensity) { SetDetailIntensity(userData: ctx.userData) }
        .sheet(isPresented: $showingWeightIncrementation) { WeightIncrementation() }
        .sheet(isPresented: $showingSupersetSettings) { SupersetSettingsView(userData: ctx.userData) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") { showAlert = true }
                    .disabled(isDefault)
                    .foregroundStyle(isDefault ? .gray : .red)
            }
        }
        .alert("Reset to Defaults", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { resetToDefaults() }
        } message: {
            Text("This will reset all workout customization preferences to their default values. This action cannot be undone.")
        }
    }

    private var daysOfWeekSelector: some View {
        Picker("Workout Days per Week", selection: $daysPerWeek) {
            ForEach(1...6, id: \.self) {
                Text(Format.countText($0, base: "day"))
            }
        }
        .onChange(of: daysPerWeek) { oldValue, newValue in
            if oldValue != newValue {
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
        let summary = binding.wrappedValue.formattedTotalRange(filteredBy: distribution)

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
        let summary = binding.wrappedValue.formattedTotalRange(filteredBy: distribution)

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
                ctx.userData.workoutPrefs.setStructure = newValue
            }
        }
    }

    private var resistanceTypeSelector: some View {
        let showWarning = (paramsBeforeSwitch?.contains(.resistance) == true)

        return HStack {
            if showWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .imageScale(.medium)
                    .foregroundStyle(.orange)
            }
            Picker("Resistance Type", selection: $selectedResistanceType) {
                ForEach(ResistanceType.allCases.filter { $0 != .banded }) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        }
        .onChange(of: selectedResistanceType) { oldValue, newValue in
            if oldValue != newValue, newValue != .banded {
                ctx.userData.workoutPrefs.resistance = newValue
            }
        }
    }

    private var distributionSelector: some View {
        let defaultDist = defaultRepsAndSets.distribution
        let showWarning = (paramsBeforeSwitch?.contains(.distribution) == true)

        return DisclosureGroup {
            DistributionEditor(
                distribution: Binding(
                    get: { ctx.userData.workoutPrefs.customDistribution ?? defaultDist },
                    set: { newDist in
                        ctx.userData.workoutPrefs.customDistribution = (newDist == defaultDist) ? nil : newDist
                    }
                )
            )
            .listRowSeparator(.hidden, edges: .top)
        } label: {
            HStack {
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.medium)
                        .foregroundStyle(.orange)
                }
                Text("Effort Distribution")
            }
        }
        .tint(.gray)
    }

    private var workoutDurationSelector: some View {
        let showWarning = (paramsBeforeSwitch?.contains(.duration) == true)
        let binding = Binding<TimeSpan>(
            get: { ctx.userData.workoutPrefs.customDuration ?? defaultDuration },
            set: { newDuration in
                ctx.userData.workoutPrefs.customDuration = (newDuration == defaultDuration) ? nil : newDuration
            }
        )

        return DisclosureGroup(isExpanded: $isDurationExpanded) {
            DurationPicker(time: binding, hourRange: 0...2, minuteStep: 15)
                .listRowSeparator(.hidden, edges: .top)
                .padding(.trailing)
                .overlay(alignment: .top, content: {
                    if binding.wrappedValue.inMinutes <= 15 {
                        ErrorFooter(message: "Invalid Duration (≤ 15 min) will not be used")
                    }
                })
        } label: {
            HStack {
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.medium)
                        .foregroundStyle(.orange)
                }
                Text("Workout Duration")
                Spacer()
                Text(binding.wrappedValue.inMinutes > 15 ? binding.wrappedValue.displayString : defaultDuration.displayString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle()) // makes the whole row tappable
        }
        .tint(.gray) // makes the disclosure arrow gray
    }

    private var keepCurrentExercisesToggle: some View {
        VStack {
            Toggle("Keep current Exercises", isOn: $keepCurrentExercises) // Add this line
                .disabled(ctx.userData.workoutPlans.trainerTemplates.isEmpty)

            if let params = paramsBeforeSwitch, !params.isEmpty {
                WarningFooter(message: "Changes made since last generation. Toggle off to implement parameter changes.")
            }
        }
        .onChange(of: keepCurrentExercises) { oldValue, newValue in
            if oldValue != newValue {
                ctx.userData.workoutPrefs.keepCurrentExercises = newValue
            }
        }
    }

    private var splitSelector: some View {
        let showWarning = (paramsBeforeSwitch?.contains(.split) == true)
        let splitWarning = WorkoutWeek.splitWarning(
            customSplit: ctx.userData.workoutPrefs.customWorkoutSplit,
            daysPerWeek: daysPerWeek
        )
        return VStack(alignment: .leading) {
            Button(action: { showingSplitSelection = true }) {
                VStack {
                    HStack {
                        if showWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.medium)
                                .foregroundStyle(.orange)
                        }
                        Text("Customize Split")
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    if let splitWarning {
                        WarningFooter(message: splitWarning)
                    }
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

    private var setIntensitySelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingSetIntensity = true }) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Set Intensity")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Text(ctx.userData.workoutPrefs.setIntensity.summary(setStructure: selectedSetStructure))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var warmupSettingsSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingWarmupSettings = true }) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Warmup Sets")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Text(ctx.userData.workoutPrefs.warmupSettings.summary(
                            setDistribution: ctx.userData.workoutPrefs.customSets ?? defaultRepsAndSets.sets,
                            effortDistribution: distribution
                        )
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var roundingSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingWeightIncrementation = true }) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Weight Rounding")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Text(ctx.userData.workoutPrefs.roundingPreference.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var supersetSettingsSelector: some View {
        VStack(alignment: .leading) {
            Button(action: { showingSupersetSettings = true }) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Supersetting")
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    Spacer()
                    Text(ctx.userData.workoutPrefs.supersetSettings.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var paramsBeforeSwitch: Set<ParamsBeforeSwitch.ParamsChanged>? {
        guard keepCurrentExercises, let params = ctx.userData.workoutPrefs.paramsBeforeSwitch else { return nil }
        
        return params.getChanges(
            resistance: selectedResistanceType,
            distribution: distribution,
            split: WorkoutWeek.determineSplit(
                customSplit: ctx.userData.workoutPrefs.customWorkoutSplit,
                daysPerWeek: daysPerWeek
            ),
            duration: ctx.userData.workoutPrefs.customDuration ?? defaultDuration
        )
    }

    private var distribution: EffortDistribution {
        ctx.userData.workoutPrefs.customDistribution ?? defaultRepsAndSets.distribution
    }

    private var defaultRepsAndSets: RepsAndSets { RepsAndSets.defaultRepsAndSets(for: ctx.userData.physical.goal) }
    
    private var defaultDuration: TimeSpan {
        return WorkoutParams.defaultWorkoutDuration(
            age: ctx.userData.profile.age,
            frequency: daysPerWeek,
            strengthLevel: ctx.userData.evaluation.strengthLevel,
            goal: ctx.userData.physical.goal
        )
    }

    private func initializeVariables() {
        daysPerWeek = ctx.userData.workoutPrefs.workoutDaysPerWeek
        selectedDays = ctx.userData.workoutPrefs.customWorkoutDays ?? DaysOfWeek.defaultDays(for: ctx.userData.workoutPrefs.workoutDaysPerWeek)
        keepCurrentExercises = (ctx.userData.workoutPlans.trainerTemplates.isEmpty ? false : ctx.userData.workoutPrefs.keepCurrentExercises)
        selectedResistanceType = ctx.userData.workoutPrefs.resistance
        selectedSetStructure = ctx.userData.workoutPrefs.setStructure
    }

    private func resetToDefaults() {
        ctx.userData.workoutPrefs.customRepsRange = nil
        ctx.userData.workoutPrefs.customSets = nil
        ctx.userData.workoutPrefs.customWorkoutDays = nil
        ctx.userData.workoutPrefs.customWorkoutSplit = nil
        ctx.userData.workoutPrefs.keepCurrentExercises = false
        ctx.userData.workoutPrefs.resistance = .any
        ctx.userData.workoutPrefs.setStructure = .pyramid
        ctx.userData.workoutPrefs.customDuration = nil
        ctx.userData.workoutPrefs.customDistribution = nil
        ctx.userData.workoutPrefs.customWorkoutTimes = nil

        ctx.userData.workoutPrefs.warmupSettings = WarmupSettings()
        ctx.userData.workoutPrefs.setIntensity = SetIntensitySettings()
        ctx.userData.workoutPrefs.roundingPreference = RoundingPreference()
        ctx.userData.workoutPrefs.supersetSettings = SupersetSettings()

        initializeVariables()

        toast.showSaveConfirmation()
    }

    private var isDefault: Bool {
        let pref = ctx.userData.workoutPrefs
        return (
            pref.customRepsRange == nil
            && pref.customSets == nil
            && pref.customWorkoutDays == nil
            && pref.customWorkoutSplit == nil
            && pref.keepCurrentExercises == false
            && pref.resistance == .any
            && pref.setStructure == .pyramid
            && pref.customDuration == nil
            && pref.customDistribution == nil
            && pref.customWorkoutTimes == nil
            && pref.warmupSettings == .init()
            && pref.setIntensity == .init()
            && pref.roundingPreference == .init()
            && pref.supersetSettings == .init()
        )
    }
}
