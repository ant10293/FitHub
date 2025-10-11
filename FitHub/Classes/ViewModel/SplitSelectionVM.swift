//
//  SplitSelectionVM.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/15/25.
//
import SwiftUI
import Foundation
import Combine

@MainActor
final class SplitSelectionVM: ObservableObject {
    // ───── Public reactive state ──────────────────────────────────────
    @Published var selectedDay: DaysOfWeek?          // nil ⇒ single-template mode
    @Published var showFrontView: Bool = true

    /// Per-day selections (or just one “virtual day” in single mode)
    @Published private(set) var selections: [DaysOfWeek: [SplitCategory]] = [:]

    // ───── Dependencies / constants ───────────────────────────────────
    private let userData: UserData
    let workoutDays: [DaysOfWeek]

    // Keep a copy so we know when the user really changed something
    private var originalSelections: [DaysOfWeek: [SplitCategory]] = [:]
    
    var hasUnsavedChanges: Bool { selections != originalSelections }


    // MARK: – Init ­­­­­­­­­­­­­­­­­­­­­­­­­­­­–––––––––––––––––––––––––

    /// Multi-day constructor (used by **SplitSelection**)
    init(userData: UserData) {
        self.userData    = userData
        self.workoutDays = userData.workoutPrefs.customWorkoutDays ?? DaysOfWeek.defaultDays(for: userData.workoutPrefs.workoutDaysPerWeek)
        self.selectedDay = workoutDays.first

        // Seed with the saved split (or an empty template)
        let savedSplit   = userData.workoutPrefs.customWorkoutSplit ?? WorkoutWeek.createSplit(forDays: userData.workoutPrefs.workoutDaysPerWeek)

        for (idx, day) in workoutDays.enumerated()
            where idx < savedSplit.categories.count {
            selections[day] = savedSplit.categories[idx]
        }
        originalSelections = selections
    }

    /// Single-template constructor (used by **CategorySelection**)
    convenience init(initialCategories: [SplitCategory] = []) {
        // Use a dummy UserData so the helpers compile, but it’s never touched
        let dummyUD = UserData()
        self.init(userData: dummyUD)

        // Collapse to “single-day” mode
        selectedDay = nil
        selections.removeAll()
        selections[.monday] = initialCategories   // arbitrary key
        originalSelections = selections
    }

    // ───── API the views call ­­­­­­­­­­­­­­­­­­­­­­­­­­­­–––––––––––––

    /// Returns the array the view should bind to for *this* day (or the single template).
    func binding(for day: DaysOfWeek? = nil) -> Binding<[SplitCategory]> {
        let key = day ?? .monday
        return Binding(
            get: { self.selections[key] ?? [] },
            set: { self.selections[key] = $0 }
        )
    }
    
    /// Returns true when `cat` should be drawn as a button.
    func shouldShow(_ cat: SplitCategory, in list: [SplitCategory]) -> Bool {
        let legFocused = list.contains(.legs) && SplitCategory.legsFocus.contains(cat) 
        return !(legFocused && list.contains(cat))
    }

    func toggle(_ muscleGroup: SplitCategory, on day: DaysOfWeek? = nil) {
        // 0️⃣  Resolve the key exactly once
        let key = day ?? .monday                        // .monday is the single-template bucket

        // 1️⃣  Pull the current list for that key
        var list = selections[key] ?? []

        // 2️⃣  Mutate *locally*
        if list.contains(muscleGroup) {                 // ─── DE-SELECT ───────────
            if muscleGroup == .legs {
                // Remove “Legs” *and* every specific leg category in a single pass
                list.removeAll { $0 == .legs || SplitCategory.legsFocus.contains($0) }
            } else {
                // Remove just the specific muscle group
                list.removeAll { $0 == muscleGroup }
            }
        } else {                                        // ─── SELECT ──────────────
            list.append(muscleGroup)
        }

        // 3️⃣  Write back – this publishes the change
        selections[key] = list
    }

    func shouldDisable(_ category: SplitCategory, on day: DaysOfWeek? = nil) -> Bool {
        let list          = binding(for: day).wrappedValue
        let pickedLegCats = list.filter { SplitCategory.legsFocus.contains($0) }

        if list.contains(.all)   && category != .all                                    { return true }
        if list.contains(.arms)  && [.biceps,.triceps,.forearms].contains(category)     { return true }
        if pickedLegCats.count > 1 && SplitCategory.legsFocus.contains(category) && !list.contains(category) { return true }
        return false
    }

    func displayName(for category: SplitCategory, on day: DaysOfWeek? = nil) -> String {
        guard category == .legs else { return category.rawValue }

        let list  = binding(for: day).wrappedValue
        let focus = list.filter { SplitCategory.legsFocus.contains($0) }
        let focusFormatted = focus.map { $0.legDetail ?? $0.rawValue }

        if focus.isEmpty { return "Legs" }
        if list.contains(.legs)  {
            return "Legs: " + focusFormatted.joined(separator: ", ") + " focus"
        }
        
        return category.rawValue
    }
    
    // (single-day mode only)
    func saveIfNeeded(singleSave: (([SplitCategory]) -> Void)? = nil) {
        // • multi-day mode keeps the old code unchanged
        guard selectedDay == nil else {
            saveIfNeeded()          // existing impl.
            return
        }

        // • single-template mode
        guard selections != originalSelections else { return }
        if let singleSave {
            singleSave(binding().wrappedValue)      // hand updated list to the caller
        }
        originalSelections = selections
    }

    // ───── Persistence helpers (multi-day mode only) ­­­­­­­­­­­­­­­­­––
    func saveIfNeeded() {
        guard selectedDay != nil else { return }          // single-template mode
        guard originalSelections != selections else { return }

        var cats = Array(repeating: [SplitCategory](), count: userData.workoutPrefs.workoutDaysPerWeek)

        for (idx, day) in workoutDays.enumerated()
            where idx < cats.count {
            cats[idx] = selections[day] ?? []
        }
        userData.workoutPrefs.customWorkoutSplit = WorkoutWeek(categories: cats)
        originalSelections = selections
    }

    func clearDay(_ day: DaysOfWeek? = nil) { binding(for: day).wrappedValue.removeAll() }
    
    func clearAll() { for day in workoutDays { selections[day] = [] } }

    func revertChanges() { selections = originalSelections }
}
