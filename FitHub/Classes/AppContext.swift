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
    let persistence: PersistenceController = .shared       // Core Data wrapper
    let toast = ToastManager()      // In‑app toast helper

    // MARK: –  Domain data models that views observe via `@Published`
    // ------------------------------------------------------------------
    @Published var userData: UserData            // Profile & settings
    @Published var adjustments: AdjustmentsData       // Progressive‑overload prefs
    @Published var exercises = ExerciseData()      // Exercise catalogue & stats
    @Published var equipment = EquipmentData()
    
    @Published var store: PremiumStore
    

    // MARK: –  Private
    private var sinks = Set<AnyCancellable>()

    // MARK: –  Init
    // ------------------------------------------------------------------
    init() {
        // Load persisted user‑modifiable models (or fallback to defaults)
        self.userData = UserData.loadFromFile() ?? .init()
        self.adjustments = AdjustmentsData.loadAdjustmentsFromFile() ?? .init()

        self.store = PremiumStore(appAccountToken: nil)

        // Forward child updates so that *any* change triggers a view refresh
        stitch(userData)
        stitch(adjustments)
        stitch(exercises)
        stitch(equipment)
        stitch(toast)
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
}

