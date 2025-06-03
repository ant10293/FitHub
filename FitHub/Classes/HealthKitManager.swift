//
//  HealthKitManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation
import HealthKit


class HealthKitManager: ObservableObject {
    private var healthStore: HKHealthStore?
     var totalInches: Int = 0
     var weight: Double = 0.0
     var age: Int = 0
     var dob: Date? = nil
    
    private var completionCalled = false
    private var completionHandler: (() -> Void)?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization(onComplete: @escaping () -> Void) {
        self.completionHandler = onComplete

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.workoutType()
        ]

        healthStore?.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if success {
                self.retrieveDOB()
                self.retrieveHeight()
                self.retrieveWeight()
            } else {
                onComplete() // fallback if user denied permission
            }
        }
    }

    private func checkIfAllDataReady() {
        guard !completionCalled else { return }

        if totalInches > 0,
           weight > 0,
           dob != nil {
            completionCalled = true
            DispatchQueue.main.async {
                self.completionHandler?()
            }
        }
    }

    private func retrieveDOB() {
        do {
            let components = try healthStore?.dateOfBirthComponents()
            if let day = components?.day,
               let month = components?.month,
               let year = components?.year {
                let calendar = Calendar.current
                let dob = calendar.date(from: DateComponents(year: year, month: month, day: day))
                DispatchQueue.main.async {
                    self.dob = dob
                    self.checkIfAllDataReady()
                }
            }
        } catch {
            print("DOB error: \(error)")
        }
    }

    private func retrieveHeight() {
        let type = HKSampleType.quantityType(forIdentifier: .height)!
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) {
            _, results, _ in
            if let result = results?.first as? HKQuantitySample {
                let meters = result.quantity.doubleValue(for: .meter())
                let inches = Int(round(meters * 39.3701))
                DispatchQueue.main.async {
                    self.totalInches = inches
                    self.checkIfAllDataReady()
                }
            }
        }
        healthStore?.execute(query)
    }

    private func retrieveWeight() {
        let type = HKSampleType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) {
            _, results, _ in
            if let result = results?.first as? HKQuantitySample {
                let kg = result.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let lbs = round(kg * 2.20462)
                DispatchQueue.main.async {
                    self.weight = lbs
                    self.checkIfAllDataReady()
                }
            }
        }
        healthStore?.execute(query)
    }
}

