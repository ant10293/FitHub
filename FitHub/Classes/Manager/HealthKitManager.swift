//
//  HealthKitManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation
import HealthKit


final class HealthKitManager: ObservableObject {
    private var healthStore: HKHealthStore?
    private var completionCalled = false
    
    /// shouldPoll: Bool (true = should poll for data, false = should not poll -> Progress)
    private var completionHandler: ((Bool) -> Void)?
    
    private var processedKeys = Set<ReadKey>()
    
    @Published var dob: Date? = nil
    @Published var sex: Gender? = nil
    @Published var heightCm: Double = -1
    @Published var weightKg: Double = -1
    @Published var bodyFat: Double = -1
    
    @Published var avgSteps: Int = -1
    @Published var caloricIntake: Int = -1
    @Published var dietaryCarbs: Int = -1
    @Published var dietaryFats: Int = -1
    @Published var dietaryProtein: Int = -1
    
    init() {
        healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }
    
    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKTypes.bodyMass, HKTypes.bodyFat, HKTypes.height, HKTypes.dateOfBirth, HKTypes.biologicalSex,
            HKTypes.stepCount, HKTypes.dietaryEnergy, HKTypes.dietaryFat, HKTypes.dietaryProtein, HKTypes.dietaryCarbs
        ]
        return Set(types.compactMap { $0 })
    }
    
    private var allCategoriesProcessed: Bool {
        processedKeys.count == ReadKey.allCases.count
    }
    
    private func markProcessed(_ key: ReadKey, shouldPoll: Bool = true) {
        processedKeys.insert(key)
        checkIfAllDataReady(shouldPoll: shouldPoll)
    }
    
    private func handleAuthorization(userData: UserData, onComplete: @escaping (Bool) -> Void) {
        self.completionHandler = onComplete

        guard let store = self.healthStore else {
            DispatchQueue.main.async { self.completionHandler?(false) } 
            return
        }
        
        store.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if success {
                // first check if permission is valid
                if let components = self.checkDOB(store: store) {
                    self.retrieveDOB(components: components)
                }
                
                if let sex = self.checkSex(store: store) {
                    self.retrieveSex(sex: sex)
                }
                
                self.retrieveHeight(store: store)
                self.retrieveWeight(store: store)
                self.retrieveBodyFat(store: store)
                
                self.retrieveAverageSteps(store: store)
                self.retrieveCalories(store: store)
                self.retrieveCarbs(store: store)
                self.retrieveFats(store: store)
                self.retrieveProteins(store: store)
            }
        }
    }
    
    func requestAuthorization(userData: UserData) {
        handleAuthorization(userData: userData, onComplete: { shouldPoll in
            if shouldPoll { // start polling on the main thread
                DispatchQueue.main.async { self.pollForData(userData: userData) }
            } else {
                userData.setup.setupState = .detailsView
                userData.saveToFile()
            }
        })
    }
    
    private func pollForData(userData: UserData) {
        userData.physical.height.setCm(heightCm)
        userData.physical.avgSteps = avgSteps
        userData.updateMeasurementValue(for: .weight, with: weightKg)
        userData.updateMeasurementValue(for: .bodyFatPercentage, with: bodyFat)
        userData.updateMeasurementValue(for: .caloricIntake, with: Double(caloricIntake))
        userData.physical.carbs = Double(dietaryCarbs)
        userData.physical.proteins = Double(dietaryProtein)
        userData.physical.fats = Double(dietaryFats)
        if let sex = sex { userData.physical.gender = sex }
        if let dob = dob { userData.profile.dob = dob }

        userData.setup.setupState = .detailsView
    }

    private func checkIfAllDataReady(shouldPoll: Bool) {
        guard !completionCalled else { return }
        
        if allCategoriesProcessed {
            completionCalled = true
            // this is the only way to trigger completion
            DispatchQueue.main.async { self.completionHandler?(shouldPoll) }
        }
    }
}

// MARK: DOB
extension HealthKitManager {
    private func checkDOB(store: HKHealthStore) -> DateComponents? {
        do {
            return try store.dateOfBirthComponents() // success
        } catch {
            // 3. Failure – log and notify the caller on the main queue.
            print("DOB read error:", error)
            DispatchQueue.main.async { self.markProcessed(.dob) }
            return nil
        }
    }

    private func retrieveDOB(components: DateComponents) {
        if let day = components.day, let month = components.month, let year = components.year,
           let dob = CalendarUtility.shared.date(from: DateComponents(year: year, month: month, day: day))
        {
            DispatchQueue.main.async {
                self.dob = dob
                self.markProcessed(.dob)
            }
        } else {
            print("⚠️ Missing date components: \(components)")
            DispatchQueue.main.async {
                self.dob = nil
                self.markProcessed(.dob)
            }
        }
    }
}

// MARK: Sex
extension HealthKitManager {
    private func checkSex(store: HKHealthStore) -> HKBiologicalSex? {
        do {
            return try store.biologicalSex().biologicalSex // success
        } catch {
            print("Sex read error:", error)
            DispatchQueue.main.async { self.markProcessed(.sex) }
            return nil
        }
    }

    private func retrieveSex(sex: HKBiologicalSex) {
        DispatchQueue.main.async {
            switch sex {
            case .female: self.sex = .female
            case .male: self.sex = .male
            default: break // keep sex as nil
            }
            self.markProcessed(.sex)
        }
    }
}

// MARK: Physical Stats (Height, Weight, BF%)
extension HealthKitManager {
    private func retrieveHeight(store: HKHealthStore) {
        guard let heightType = HKTypes.height else {
            print("⚠️ Height type not available in HealthKit")
            DispatchQueue.main.async { self.markProcessed(.height) }
            return
        }
        runQuantitySample(store: store, type: heightType, unit: .meter()) { meters in
            self.heightCm = meters * 100
            self.markProcessed(.height)
        }
    }

    private func retrieveWeight(store: HKHealthStore) {
        guard let bodyMassType = HKTypes.bodyMass else {
            print("⚠️ Body mass type not available in HealthKit")
            DispatchQueue.main.async { self.markProcessed(.weight) }
            return
        }
        runQuantitySample(store: store, type: bodyMassType, unit: .gramUnit(with: .kilo)) { kg in
            self.weightKg = kg
            self.markProcessed(.weight)
        }
    }

    private func retrieveBodyFat(store: HKHealthStore) {
        guard let bodyFatType = HKTypes.bodyFat else {
            print("⚠️ Body fat type not available in HealthKit")
            DispatchQueue.main.async { self.markProcessed(.bodyFat) }
            return
        }
        runQuantitySample(store: store, type: bodyFatType, unit: .percent()) { fraction in
            self.bodyFat = fraction * 100 // 0.23 → 23.0%
            self.markProcessed(.bodyFat)
        }
    }

    /// Reads the most-recent quantity sample, converts with `unit`,
    /// calls `assign(value)`, and *always* marks `key` processed.
    private func runQuantitySample(
        store: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit,
        assign: @escaping (Double) -> Void
    ) {
        let query = HKSampleQuery(
            sampleType: type,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, results, error in
            guard let self = self else { return }

            let value: Double
            if let error = error {
                print("❌ HK query error for \(type.identifier):", error.localizedDescription)
                value = 0
            } else if let sample = results?.first as? HKQuantitySample {
                value = sample.quantity.doubleValue(for: unit)
                let start = sample.startDate.formatted(date: .numeric, time: .standard)
                print("✅ HK query → \(type.identifier) (\(start)) = \(value)")
            } else {
                let st = store.authorizationStatus(for: type)
                print("⚠️ No sample for \(type.identifier) – \(self.statusLabel(st)).")
                value = 0
            }

            DispatchQueue.main.async { assign(value) } // exactly once
        }

        store.execute(query)
    }
}

// MARK: - Average steps (default = past 7 days)
extension HealthKitManager {
    private func retrieveAverageSteps(store: HKHealthStore) {
        guard let stepCountType = HKTypes.stepCount else {
            print("⚠️ Step count type not available in HealthKit")
            DispatchQueue.main.async {
                self.markProcessed(.steps)
            }
            return
        }

        retrieveDailyAverage(store: store, quantityType: stepCountType, unit: .count(), assign: { avg in
            self.avgSteps = Int(avg)
            self.markProcessed(.steps)
        })
    }

    private func retrieveDailyAverage(
        store: HKHealthStore,
        quantityType: HKQuantityType,
        unit: HKUnit,
        assign: @escaping (Double) -> Void
    ) {
        let endDay = CalendarUtility.shared.startOfDay(for: Date())
        guard let startDay = CalendarUtility.shared.date(byAdding: .day, value: -30, to: endDay) else { return }
        var dayComp = DateComponents(); dayComp.day = 1

        let pred = HKQuery.predicateForSamples(withStart: startDay, end: endDay, options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: pred,
            options: .cumulativeSum,
            anchorDate: startDay,
            intervalComponents: dayComp
        )

        query.initialResultsHandler = { [weak self] _, collection, error in
            guard let self = self else { return }

            let value: Double
            if let error = error {
                print("❌ Stats collection error (\(quantityType.identifier)):", error.localizedDescription)
                value = 0
            } else if let collection = collection {
                var total: Double = 0
                var days: Int = 0
                collection.enumerateStatistics(from: startDay, to: endDay) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        total += sum.doubleValue(for: unit)
                        days += 1
                    }
                }
                value = days > 0 ? total / Double(days) : 0
                print("✅ \(quantityType.identifier) daily average over \(days) days → \(value)")
            } else {
                let st = store.authorizationStatus(for: quantityType)
                print("⚠️ Stats collection nil for \(quantityType.identifier) – \(self.statusLabel(st)).")
                value = 0
            }

            DispatchQueue.main.async { assign(value) } // ← exactly once
        }

        store.execute(query)
    }
}

// MARK: - Dietary Needs
extension HealthKitManager {
    private func retrieveCalories(store: HKHealthStore) {
        guard let dietaryEnergyType = HKTypes.dietaryEnergy else {
            print("⚠️ Dietary energy type not available in HealthKit")
            DispatchQueue.main.async {
                self.markProcessed(.calories)
            }
            return
        }
        retrieveDietaryTotal(store: store, quantityType: dietaryEnergyType, unit: .kilocalorie(), assign: {
            self.caloricIntake = Int($0)
            self.markProcessed(.calories)
        })
    }
    
    private func retrieveCarbs(store: HKHealthStore) {
        guard let dietaryCarbsType = HKTypes.dietaryCarbs else {
            print("⚠️ Dietary carbs type not available in HealthKit")
            DispatchQueue.main.async {
                self.markProcessed(.carbs)
            }
            return
        }
        retrieveDietaryTotal(store: store, quantityType: dietaryCarbsType, unit: .gram(), assign: {
            self.dietaryCarbs = Int($0)
            self.markProcessed(.carbs)
        })
    }
    
    private func retrieveFats(store: HKHealthStore) {
        guard let dietaryFatType = HKTypes.dietaryFat else {
            print("⚠️ Dietary fat type not available in HealthKit")
            DispatchQueue.main.async {
                self.markProcessed(.fats)
            }
            return
        }
        retrieveDietaryTotal(store: store, quantityType: dietaryFatType, unit: .gram(), assign: {
            self.dietaryFats = Int($0)
            self.markProcessed(.fats)
        })
    }
    
    private func retrieveProteins(store: HKHealthStore) {
        guard let dietaryProteinType = HKTypes.dietaryProtein else {
            print("⚠️ Dietary protein type not available in HealthKit")
            DispatchQueue.main.async {
                self.markProcessed(.proteins)
            }
            return
        }
        retrieveDietaryTotal(store: store, quantityType: dietaryProteinType, unit: .gram(), assign: {
            self.dietaryProtein = Int($0)
            self.markProcessed(.proteins)
        })
    }
    
    // -----------------------------------------------------------------------------
    //  Shared “do the query” helper — private inside HealthKitManager
    // -----------------------------------------------------------------------------
    private func retrieveDietaryTotal(
        store: HKHealthStore,
        quantityType: HKQuantityType,
        unit: HKUnit,
        assign: @escaping (Double) -> Void
    ) {
        let startDay = CalendarUtility.shared.startOfDay(for: Date())
        guard let endDay = CalendarUtility.shared.date(byAdding: .day, value: 1, to: startDay) else { return }
        let pred = HKQuery.predicateForSamples(withStart: startDay, end: endDay, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: pred, options: .cumulativeSum) { [weak self] _, stats, error in
            guard let self = self else { return }
            
            // ---------- Debug prints ----------
            if stats == nil {
                let st = store.authorizationStatus(for: quantityType)
                print("⚠️ HK macro query found NO samples for \(quantityType.identifier) – \(statusLabel(st)).")
            } else if let error = error {
                print("❌ HK macro query error (\(quantityType.identifier)):", error.localizedDescription)
            }

            // ---------- Result (nil ⇒ 0) ----------
            let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0

            DispatchQueue.main.async { assign(total) }
        }
        store.execute(query)
    }
}

extension HealthKitManager {
    /// Human-readable text for a Health-Kit authorisation status
    private func statusLabel(_ s: HKAuthorizationStatus?) -> String {
        switch s {
            case .sharingAuthorized: return "authorized ✅"
            case .sharingDenied:     return "denied 🚫"
            case .notDetermined:     return "not-determined ❓"
            default:                 return "unknown"
        }
    }
    
    private enum ReadKey: CaseIterable {
        case dob, sex, height, weight, bodyFat, steps, calories, carbs, fats, proteins
    }
    
    // MARK: - One-stop list of the HK types we care about
    private enum HKTypes {
        static let bodyMass: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        static let bodyFat: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        static let height: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .height)
        static let dateOfBirth: HKCharacteristicType? = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)
        static let biologicalSex: HKCharacteristicType? = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)

        // Activity & nutrition
        static let stepCount: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .stepCount)
        static let dietaryEnergy: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        static let dietaryCarbs: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)
        static let dietaryFat: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
        static let dietaryProtein: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)
    }
}
