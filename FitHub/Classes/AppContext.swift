//
//  AppContext.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/2/25.
//


import Combine
import SwiftUI
import Foundation

@MainActor
final class AppContext: ObservableObject {

    // MARK: –  App‑wide singletons / services (stateless or long‑lived)
    // ------------------------------------------------------------------
    let persistence: PersistenceController = .shared       // Core Data wrapper

    // MARK: –  Domain data models that views observe via `@Published`
    // ------------------------------------------------------------------
    @Published var userData: UserData            // Profile & settings
    @Published var adjustments = AdjustmentsData()       // Progressive‑overload prefs
    @Published var exercises = ExerciseData()      // Exercise catalogue & stats
    @Published var equipment = EquipmentData()
    @Published var store: PremiumStore
    @Published var unitSystem: UnitSystem {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: UnitSystem.storageKey)
            // Post notification so views using UnitSystem.current can refresh
            NotificationCenter.default.post(name: Foundation.Notification.Name.unitSystemDidChange, object: nil)
        }
    }

    // MARK: –  Private
    private var sinks = Set<AnyCancellable>()

    // MARK: –  Init
    // ------------------------------------------------------------------
    init() {
        // Load persisted user‑modifiable models (or fallback to defaults)
        self.userData = UserData.loadFromFile() ?? .init()
        self.store = PremiumStore(appAccountToken: nil)
        
        // Load unit system from UserDefaults
        let raw = UserDefaults.standard.string(forKey: UnitSystem.storageKey) ?? UnitSystem.metric.rawValue
        self.unitSystem = UnitSystem(rawValue: raw) ?? .metric

        // Forward child updates so that *any* change triggers a view refresh
        stitch(userData)
        stitch(adjustments)
        stitch(exercises)
        stitch(equipment)
        stitch(store)

        // Kick StoreKit once at startup
        Task { await store.configure() }
    }

    // MARK: –  Helpers
    // ------------------------------------------------------------------
    /// Subscribes to the given ObservableObject and republishs
    /// its `objectWillChange` into *our* default publisher so SwiftUI
    /// sees a single source of truth.
    private func stitch<O: ObservableObject>(_ child: O)
    where O.ObjectWillChangePublisher == ObservableObjectPublisher {
        child.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &sinks)
    }

    func resetForSignOut() {
        NotificationManager.removeAllPending()

        let blankUserData = UserData()
        let blankAdjustments = AdjustmentsData()
        let blankExercises = ExerciseData()
        let blankEquipment = EquipmentData()

        replaceData(
            userData: blankUserData,
            adjustments: blankAdjustments,
            exercises: blankExercises,
            equipment: blankEquipment
        )
    }

    func reloadDataFromDisk() {
        let loadedUserData = UserData.loadFromFile() ?? .init(reloadingBlank: true)
        let loadedAdjustments = AdjustmentsData()
        let loadedExercises = ExerciseData()
        let loadedEquipment = EquipmentData()

        replaceData(
            userData: loadedUserData,
            adjustments: loadedAdjustments,
            exercises: loadedExercises,
            equipment: loadedEquipment
        )

        replaceNotifications()
    }

    private func replaceData(
        userData newUserData: UserData,
        adjustments newAdjustments: AdjustmentsData,
        exercises newExercises: ExerciseData,
        equipment newEquipment: EquipmentData
    ) {
        sinks.removeAll()

        self.userData = newUserData
        self.adjustments = newAdjustments
        self.exercises = newExercises
        self.equipment = newEquipment
        // Note: unitSystem is not reset here - it persists across sign out

        stitch(userData)
        stitch(adjustments)
        stitch(exercises)
        stitch(equipment)
        stitch(store)
    }

    private func replaceNotifications() {
        for template in userData.workoutPlans.allTemplates {
            var template = template
            let ids = NotificationManager.scheduleNotification(for: template, user: userData)
            template.notificationIDs = ids
            userData.updateTemplate(template: template)
        }
    }

    var disableCreateWorkout: Bool {
        store.membershipType == .free && userData.workoutPlans.userTemplates.count >= 4
    }

    var disableCreatePlan: Bool {
        store.membershipType == .free && userData.workoutPlans.workoutPlansGenerated >= 1
    }
}
