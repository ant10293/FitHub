//
//  EquipmentData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation


/// One global instance you inject where needed
final class EquipmentData: ObservableObject {

    // MARK: – Single shared instance
    static let shared = EquipmentData()

    // MARK: – Private storage
    private let saveQueue = DispatchQueue(label: "EquipmentSaveQueue")

    /// Read-only “seed” gear that ships inside the bundle
    private let bundledEquipment: [GymEquipment]

    /// Mutable user-created gear (lives in Documents/)
    @Published private(set) var userEquipment: [GymEquipment]

    // MARK: – Public unified view
    var allEquipment: [GymEquipment] { bundledEquipment + userEquipment }

    // MARK: – Init
    init() {
        bundledEquipment = EquipmentData.loadBundledEquipment(from: "equipment.json")
        userEquipment = EquipmentData.loadUserEquipment(from: "user_equipment.json")
    }

    // MARK: – Loading helpers
    private static func loadBundledEquipment(from file: String) -> [GymEquipment] {
        do {
            // 1. Decode the seed JSON as InitEquipment
            let seed: [InitEquipment] = try Bundle.main.decode(file)
            // 2. Convert to GymEquipment on the fly
            return seed.map { GymEquipment(from: $0) }
        } catch {
            fatalError("❌ Couldn’t load bundled equipment: \(error)")
        }
    }

    private static func loadUserEquipment(from file: String) -> [GymEquipment] {
        let url = getDocumentsDirectory().appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return [] }   // first run
        do { return try JSONDecoder().decode([GymEquipment].self, from: data) }
        catch {
            print("⚠️ Corrupt user equipment file – starting fresh. \(error)")
            return []
        }
    }

    // MARK: – Mutations
    func addEquipment(_ newEquipment: GymEquipment) {
        guard !allEquipment.contains(where: { $0.id == newEquipment.id }) else { return }
        userEquipment.append(newEquipment)
        persistUserEquipment()
    }

    func replace(_ old: GymEquipment, with updated: GymEquipment) {
        userEquipment.removeAll { $0.id == old.id }
        userEquipment.append(updated)
        persistUserEquipment()
    }
    
    func removeEquipment(_ equipment: GymEquipment) {
        userEquipment.removeAll { $0.id == equipment.id }
        persistUserEquipment()
    }

    // MARK: – Private helper
    private func persistUserEquipment() {
        let snapshot = userEquipment                  // value copy, thread-safe
        saveQueue.async {
            let url = getDocumentsDirectory()
                .appendingPathComponent("user_equipment.json")
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url,
                               options: [.atomicWrite, .completeFileProtection])
                #if DEBUG
                print("✅ Saved \(snapshot.count) user equipment items.")
                #endif
            } catch {
                print("❌ Failed saving user equipment:", error.localizedDescription)
            }
        }
    }

    func isUserEquipment(_ equipment: GymEquipment) -> Bool {
        userEquipment.contains(where: { $0.id == equipment.id })
    }
}

// MARK: – NON-MUTATING HELPERS (were previously static)
extension EquipmentData {
    
    func selectEquipment(basedOn option: String) -> [GymEquipment] {

        let homeKit:  Set<String> = [
            "Barbell", "Dumbbells", "Pull-Up Bar", "Squat Rack",
            "Flat Bench", "Incline Bench Rack", "Dip Bar", "EZ Bar"
        ].map(normalize).reduce(into: []) { $0.insert($1) }

        let bodyKit:  Set<String> = [
            "Pull-Up Bar", "Dip Bar"
        ].map(normalize).reduce(into: []) { $0.insert($1) }

        switch option {
        case "All (Gym Membership)":
            return allEquipment

        case "Some (Home Gym)":
            return allEquipment.filter { homeKit.contains(normalize($0.name)) }

        case "None (Bodyweight Only)":
            return allEquipment.filter { bodyKit.contains(normalize($0.name)) }

        default:
            return []
        }
    }

    // MARK: Search + category filtering

    func filteredEquipment(searchText: String, category: EquipmentCategory? = nil) -> [GymEquipment] {
        let searchKey = normalize(searchText.removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)))

        var results = allEquipment.filter { item in
            // a) category
            let okCat = category.map { $0 == item.equCategory } ?? true

            // b) text match
            if searchKey.isEmpty { return okCat }

            let nameKey   = normalize(item.name)
            let aliasKeys = (item.aliases ?? []).map(normalize)

            let okText = nameKey.contains(searchKey)
                      || aliasKeys.contains(where: { $0.contains(searchKey) })

            return okCat && okText
        }

        // c) sort: prefix match first, then alphabetical
        results.sort { a, b in
            let na = normalize(a.name)
            let nb = normalize(b.name)

            if !searchKey.isEmpty {
                let aStarts = na.hasPrefix(searchKey)
                let bStarts = nb.hasPrefix(searchKey)
                if aStarts != bStarts { return aStarts }
            }
            return na < nb
        }
        return results
    }

    // MARK: Simple look-ups

    func category(for equipName: String) -> EquipmentCategory? {
        allEquipment.first { normalize($0.name) == normalize(equipName) }?.equCategory
    }

    func getEquipment(from names: [String]) -> [GymEquipment] {
        let want = names.map(normalize)
        return allEquipment.filter { want.contains(normalize($0.name)) }
    }

    func equipmentForExercise(_ ex: Exercise) -> [GymEquipment] {
        getEquipment(from: ex.equipmentRequired)
    }

    func equipmentForCategory(for rounding: RoundingCategory) -> [GymEquipment] {
        allEquipment.filter { $0.roundingCategory == rounding }
    }

    func hasEquipmentAdjustments(for exercise: Exercise) -> Bool {
        exercise.equipmentRequired.contains { req in
            allEquipment.first(where: { normalize($0.name) == normalize(req) })?
                .adjustments?
                .isEmpty == false
        }
    }

    // MARK: Weight rounding with string names
    func roundWeight(_ weight: Double, for equipmentNames: [String], roundingPreference p: RoundingPreference) -> Double {
        let names = equipmentNames.map(normalize)

        let increment: Double =
              // 1️⃣ pin-loaded / cable stacks
              names.contains { n in
                  allEquipment.contains {
                      normalize($0.name) == n &&
                      ($0.equCategory == .weightMachines || $0.equCategory == .cableMachines)
                  }
              } ? p.pinLoaded

            // 2️⃣ small free-weight implements
            : names.contains { n in
                  allEquipment.contains {
                      normalize($0.name) == n && $0.equCategory == .smallWeights
                  }
              } ? p.smallWeights

            // 3️⃣ single-peg plated tools
            : names.contains { n in
                  allEquipment.contains {
                      normalize($0.name) == n && ($0.singlePeg ?? false)
                  }
              } ? p.platedSinglePeg

            // 4️⃣ regular two-peg plated machines
            : p.plated

        return round(weight / increment) * increment
    }
}


