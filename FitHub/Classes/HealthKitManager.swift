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
    @Published var totalInches: Int = -1
    @Published var weight: Double = -1
    @Published var bodyFat: Double = -1
    
    @Published var avgSteps: Int = -1
    @Published var caloricIntake: Int = -1
    @Published var dietaryCarbs: Int = -1
    @Published var dietaryFats: Int = -1
    @Published var dietaryProtein: Int = -1
    
    init() {
        healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }
    
    let readTypes: Set<HKObjectType> = [
        HKTypes.bodyMass, HKTypes.bodyFat, HKTypes.height, HKTypes.dateOfBirth, HKTypes.biologicalSex,
        HKTypes.stepCount, HKTypes.dietaryEnergy, HKTypes.dietaryFat, HKTypes.dietaryProtein, HKTypes.dietaryCarbs
    ]
    
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
        guard totalInches > 0 else {
            // Not ready yet → retry in 0.5 s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.pollForData(userData: userData) }
            return
        }

        // ✅ We’ve got valid data—process it once and stop polling
        let feet = totalInches / 12
        let inches = totalInches % 12
        
        userData.physical.heightFeet = Int(feet)
        userData.physical.heightInches = Int(inches)
        userData.physical.avgSteps = avgSteps
        userData.updateMeasurementValue(for: .weight, with: weight, shouldSave: false)
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
        sex != nil && dob != nil && totalInches > -1 && weight > -1 && avgSteps > -1 &&
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
            let calendar = Calendar.current
            let dob = calendar.date(from: DateComponents(year: year, month: month, day: day))
            DispatchQueue.main.async {
                self.dob = dob
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
        runSampleQuery(type: HKTypes.height, handler: { [weak self] sample in
            guard let self = self else { return }
            guard let q = sample as? HKQuantitySample else { return }
            let inches = Int(round(q.quantity.doubleValue(for: .meter()) * 39.3701))

            DispatchQueue.main.async {
                self.totalInches = inches
                self.checkIfAllDataReady(shouldPoll: true)
            }
        },
        assign: { newValue in
            self.totalInches = Int(newValue)
        })
    }

    private func retrieveWeight() {
        runSampleQuery(type: HKTypes.bodyMass, handler: { [weak self] sample in
            guard let self = self else { return }
            guard let q = sample as? HKQuantitySample else { return }
            let lbs = round(q.quantity.doubleValue(for: .gramUnit(with: .kilo)) * 2.20462)
            
            DispatchQueue.main.async {
                self.weight = lbs
                self.checkIfAllDataReady(shouldPoll: true)
            }
        },
        assign: { newValue in
            self.weight = newValue
        })
    }

    private func retrieveBodyFat() {
        runSampleQuery(type: HKTypes.bodyFat, handler: { [weak self] sample in
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
        let cal = Calendar.current
        let endDay = cal.startOfDay(for: Date())            // today @ 00:00
        guard let startDay = cal.date(byAdding: .day, value: -daysBack, to: endDay) else { return }
        var dayComp = DateComponents(); dayComp.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: HKTypes.stepCount,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDay, end: endDay, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: startDay,
            intervalComponents: dayComp)

        query.initialResultsHandler = { [weak self] _, collection, error in
            guard let self = self else { return }

            // -- 2. No data ------------------------------------------------------
            guard let collection = collection else {
                 let st = self.healthStore?.authorizationStatus(for: HKTypes.stepCount)
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
        retrieveDietaryTotal(quantityType: HKTypes.dietaryEnergy, unit: .kilocalorie(), assign: {
            self.caloricIntake = Int($0)
        })
    }
    
    private func retrieveCarbs() {
        retrieveDietaryTotal(quantityType: HKTypes.dietaryCarbs, unit: .gram(), assign: {
            self.dietaryCarbs = Int($0)
        })
    }
    
    private func retrieveFats() {
        retrieveDietaryTotal(quantityType: HKTypes.dietaryFat, unit: .gram(), assign: {
            self.dietaryFats = Int($0)
        })
    }
    
    private func retrieveProteins() {
        retrieveDietaryTotal(quantityType: HKTypes.dietaryProtein, unit: .gram(), assign: {
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
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: Date())
        let endDay = cal.date(byAdding: .day, value: 1, to: startDay)!
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
        static let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        static let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        static let height = HKQuantityType.quantityType(forIdentifier: .height)!
        static let dateOfBirth = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!
        static let biologicalSex = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!

        // Activity & nutrition
        static let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        static let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        static let dietaryCarbs = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        static let dietaryFat = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
        static let dietaryProtein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
    }
}
