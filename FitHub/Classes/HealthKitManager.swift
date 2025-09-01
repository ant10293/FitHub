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
    
    var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKTypes.bodyMass, HKTypes.bodyFat, HKTypes.height, HKTypes.dateOfBirth, HKTypes.biologicalSex,
            HKTypes.stepCount, HKTypes.dietaryEnergy, HKTypes.dietaryFat, HKTypes.dietaryProtein, HKTypes.dietaryCarbs
        ]
        return Set(types.compactMap { $0 })
    }
    
    private func handleAuthorization(userData: UserData, onComplete: @escaping (Bool) -> Void) {
        self.completionHandler = onComplete

        healthStore?.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if success {
                guard let store = self.healthStore else {
                    DispatchQueue.main.async { self.completionHandler?(false) }
                    return
                }
                // first check if permission is valid
                if let components = self.checkDOB(store: store) {
                    self.retrieveDOB(components: components)
                }
                
                if let sex = self.checkSex(store: store) {
                    self.retrieveSex(sex: sex)
                }
                
                self.retrieveHeight()
                self.retrieveWeight()
                self.retrieveBodyFat()
                
                self.retrieveAverageSteps()
                self.retrieveCalories()
                self.retrieveCarbs()
                self.retrieveFats()
                self.retrieveProteins()
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
        // Make sure we have both a height & a DOB before proceeding
        guard heightCm > 0 else {
            // Not ready yet → retry in 0.5 s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.pollForData(userData: userData) }
            return
        }

        userData.physical.height.setCm(heightCm)
        userData.physical.avgSteps = avgSteps
        userData.updateMeasurementValue(for: .weight, with: weightKg, shouldSave: false)
        userData.updateMeasurementValue(for: .bodyFatPercentage, with: bodyFat, shouldSave: false)
        userData.updateMeasurementValue(for: .caloricIntake, with: Double(caloricIntake), shouldSave: false)
        userData.physical.carbs = Double(dietaryCarbs)
        userData.physical.proteins = Double(dietaryProtein)
        userData.physical.fats = Double(dietaryFats)
        if let sex = sex { userData.physical.gender = sex }
        if let dob = dob { userData.profile.dob = dob }

        userData.setup.setupState = .detailsView
        userData.saveToFile()
    }

    private func checkIfAllDataReady(shouldPoll: Bool) {
        guard !completionCalled else { return }
        
        if allCategoriesProcessed {
            completionCalled = true
            DispatchQueue.main.async { self.completionHandler?(shouldPoll) }
        }
    }
    
    private var allCategoriesProcessed: Bool {
        sex != nil && dob != nil && heightCm > -1 && weightKg > -1 && avgSteps > -1 &&
        caloricIntake > -1 && dietaryFats > -1 && dietaryCarbs > -1 && dietaryProtein > -1
    }
    
    private func checkDOB(store: HKHealthStore) -> DateComponents? {
        do {
            return try store.dateOfBirthComponents() // success
        } catch {
            // 3. Failure – log and notify the caller on the main queue.
            print("DOB read error:", error)
            DispatchQueue.main.async { self.completionHandler?(true) }
            return nil
        }
    }

    private func retrieveDOB(components: DateComponents) {
        if let day = components.day, let month = components.month, let year = components.year {
            if let dob = CalendarUtility.shared.date(from: DateComponents(year: year, month: month, day: day)) {
                DispatchQueue.main.async {
                    self.dob = dob
                    self.checkIfAllDataReady(shouldPoll: true)
                }
            } else {
                print("⚠️ Could not create date from components: \(components)")
                DispatchQueue.main.async {
                    self.dob = nil
                    self.checkIfAllDataReady(shouldPoll: true)
                }
            }
        } else {
            print("⚠️ Missing date components: \(components)")
            DispatchQueue.main.async {
                self.dob = nil
                self.checkIfAllDataReady(shouldPoll: true)
            }
        }
    }
    
    private func checkSex(store: HKHealthStore) -> HKBiologicalSex? {
        do {
            return try store.biologicalSex().biologicalSex // success
        } catch {
            print("Sex read error:", error)
            DispatchQueue.main.async { self.completionHandler?(true) }
            return nil
        }
    }

    private func retrieveSex(sex: HKBiologicalSex) {
        DispatchQueue.main.async {
            switch sex {
            case .female: self.sex = .female
            case .male: self.sex = .male
            default: self.sex = .male
            }

            self.checkIfAllDataReady(shouldPoll: true)
        }
    }
    
    private func retrieveHeight() {
        guard let heightType = HKTypes.height else {
            print("⚠️ Height type not available in HealthKit")
            DispatchQueue.main.async {
                self.heightCm = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        runSampleQuery(type: heightType, handler: { [weak self] sample in
            guard let self = self else { return }
            guard let q = sample as? HKQuantitySample else { return }
            let meters = q.quantity.doubleValue(for: .meter())           // e.g. 1.82
            let heightCm = meters * 100

            DispatchQueue.main.async {
                self.heightCm = heightCm
                self.checkIfAllDataReady(shouldPoll: true)
            }
        },
        assign: { newValue in
            self.heightCm = newValue
        })
    }

    private func retrieveWeight() {
        guard let bodyMassType = HKTypes.bodyMass else {
            print("⚠️ Body mass type not available in HealthKit")
            DispatchQueue.main.async {
                self.weightKg = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        runSampleQuery(type: bodyMassType, handler: { [weak self] sample in
            guard let self = self else { return }
            guard let q = sample as? HKQuantitySample else { return }
            let kg = q.quantity.doubleValue(for: .gramUnit(with: .kilo)) 
            
            DispatchQueue.main.async {
                self.weightKg = kg
                self.checkIfAllDataReady(shouldPoll: true)
                print("weight: \(kg) kg")
            }
        },
        assign: { newValue in
            self.weightKg = newValue
        })
    }

    private func retrieveBodyFat() {
        guard let bodyFatType = HKTypes.bodyFat else {
            print("⚠️ Body fat type not available in HealthKit")
            DispatchQueue.main.async {
                self.bodyFat = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        runSampleQuery(type: bodyFatType, handler: { [weak self] sample in
            guard let self = self else { return }
            guard let q = sample as? HKQuantitySample else { return }
            let pct = q.quantity.doubleValue(for: .percent()) * 100     // → human-readable %

            DispatchQueue.main.async {
                self.bodyFat = pct
                self.checkIfAllDataReady(shouldPoll: true)
            }
        },
        assign: { newValue in
            self.bodyFat = newValue
        })
    }

    // MARK: - Average steps (default = past 7 days)
    private func retrieveAverageSteps(daysBack: Int = 30) {
        guard let stepCountType = HKTypes.stepCount else {
            print("⚠️ Step count type not available in HealthKit")
            DispatchQueue.main.async {
                self.avgSteps = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        
        let endDay = CalendarUtility.shared.startOfDay(for: Date())            // today @ 00:00
        guard let startDay = CalendarUtility.shared.date(byAdding: .day, value: -daysBack, to: endDay) else { return }
        var dayComp = DateComponents(); dayComp.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDay, end: endDay, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: startDay,
            intervalComponents: dayComp)

        query.initialResultsHandler = { [weak self] _, collection, error in
            guard let self = self else { return }

            // -- 2. No data ------------------------------------------------------
            guard let collection = collection else {
                 let st = self.healthStore?.authorizationStatus(for: stepCountType)
                 print("⚠️ Steps query returned no collection – \(statusLabel(st)).")

                 DispatchQueue.main.async {
                     self.avgSteps = 0
                     self.checkIfAllDataReady(shouldPoll: true)
                 }
                 return
             }
            
            // -- 1. Error path ---------------------------------------------------
            if let error = error {
                print("❌ Steps query error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.avgSteps = 0
                    self.checkIfAllDataReady(shouldPoll: true)
                }
                return
            }

            // -- 3. Success ------------------------------------------------------
            var total: Double = 0; var days = 0
            collection.enumerateStatistics(from: startDay, to: endDay) { stats, _ in
                if let sum = stats.sumQuantity() {
                    total += sum.doubleValue(for: .count())
                    days  += 1
                }
            }

            let avg = days > 0 ? total / Double(days) : 0
            print("✅ Steps average over \(days) days →", Int(avg))

            DispatchQueue.main.async {
                self.avgSteps = Int(avg)
                self.checkIfAllDataReady(shouldPoll: true)
            }
        }
        healthStore?.execute(query)
    }
    
    private func retrieveCalories() {
        guard let dietaryEnergyType = HKTypes.dietaryEnergy else {
            print("⚠️ Dietary energy type not available in HealthKit")
            DispatchQueue.main.async {
                self.caloricIntake = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        retrieveDietaryTotal(quantityType: dietaryEnergyType, unit: .kilocalorie(), assign: {
            self.caloricIntake = Int($0)
        })
    }
    
    private func retrieveCarbs() {
        guard let dietaryCarbsType = HKTypes.dietaryCarbs else {
            print("⚠️ Dietary carbs type not available in HealthKit")
            DispatchQueue.main.async {
                self.dietaryCarbs = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        retrieveDietaryTotal(quantityType: dietaryCarbsType, unit: .gram(), assign: {
            self.dietaryCarbs = Int($0)
        })
    }
    
    private func retrieveFats() {
        guard let dietaryFatType = HKTypes.dietaryFat else {
            print("⚠️ Dietary fat type not available in HealthKit")
            DispatchQueue.main.async {
                self.dietaryFats = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        retrieveDietaryTotal(quantityType: dietaryFatType, unit: .gram(), assign: {
            self.dietaryFats = Int($0)
        })
    }
    
    private func retrieveProteins() {
        guard let dietaryProteinType = HKTypes.dietaryProtein else {
            print("⚠️ Dietary protein type not available in HealthKit")
            DispatchQueue.main.async {
                self.dietaryProtein = -1
                self.checkIfAllDataReady(shouldPoll: true)
            }
            return
        }
        retrieveDietaryTotal(quantityType: dietaryProteinType, unit: .gram(), assign: {
            self.dietaryProtein = Int($0)
        })
    }
}

extension HealthKitManager {
    /// Reads the most-recent *sample* of `type`, prints debug info, then calls `handler`.
    /// Only Quantity / Category / Correlation / Series / Workout / Document types are valid.
    private func runSampleQuery(type: HKSampleType, handler: @escaping (_ sample: HKSample?) -> Void, assign: @escaping (Double) -> Void) {
        let query = HKSampleQuery(sampleType: type, predicate:  nil, limit: 1, sortDescriptors: [
                NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            ]
        ) { _, results, error in

            // ---- Empty results --------------------------------------------------
            guard let sample = results?.first else {
                let st = self.healthStore?.authorizationStatus(for: type)
                print("⚠️ HK query for \(type) returned 0 results – \(self.statusLabel(st)).")
                DispatchQueue.main.async {
                    assign(0)
                }
                return
            }
            
            // ---- Error path -----------------------------------------------------
            if let error = error {
                print("❌ HK query error for \(type):", error.localizedDescription)
                return
            }

            // ---- Success --------------------------------------------------------
            if let qs = sample as? HKQuantitySample {
                let start = qs.startDate.formatted(date: .numeric, time: .standard)
                print("✅ HK query → \(type)  (\(start))")
            } else {
                print("✅ HK query → \(type)  (non-quantity sample)")
            }
            handler(sample)
        }
        healthStore?.execute(query)
    }
    
    // -----------------------------------------------------------------------------
    //  Shared “do the query” helper — private inside HealthKitManager
    // -----------------------------------------------------------------------------
    private func retrieveDietaryTotal(quantityType: HKQuantityType, unit: HKUnit, assign: @escaping (Double) -> Void) {
        let startDay = CalendarUtility.shared.startOfDay(for: Date())
        guard let endDay = CalendarUtility.shared.date(byAdding: .day, value: 1, to: startDay) else { return }
        let pred = HKQuery.predicateForSamples(withStart: startDay, end: endDay, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: pred, options: .cumulativeSum) { [weak self] _, stats, error in
            guard let self = self else { return }
            
            // ---------- Debug prints ----------
            if stats == nil {
                let st = self.healthStore?.authorizationStatus(for: quantityType)
                print("⚠️ HK macro query found NO samples for \(quantityType.identifier) – \(statusLabel(st)).")
            } else if let error = error {
                print("❌ HK macro query error (\(quantityType.identifier)):", error.localizedDescription)
            }

            // ---------- Result (nil ⇒ 0) ----------
            let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0

            DispatchQueue.main.async {
                assign(total)              // update local & UserData
                self.checkIfAllDataReady(shouldPoll: true)
            }
        }
        healthStore?.execute(query)
    }
    
    /// Human-readable text for a Health-Kit authorisation status
    private func statusLabel(_ s: HKAuthorizationStatus?) -> String {
        switch s {
            case .sharingAuthorized: return "authorised ✅"
            case .sharingDenied:     return "denied 🚫"
            case .notDetermined:     return "not-determined ❓"
            default:                 return "unknown"
        }
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
