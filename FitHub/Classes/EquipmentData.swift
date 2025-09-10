//
//  EquipmentData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation


/// One global instance you inject where needed
final class EquipmentData: ObservableObject {
    private static let userEquipmentFilename: String = "user_equipment.json"
    private static let bundledBaseWeightsFilename: String = "base_weights.json"
    private static let bundledEquipmentFilename: String = "equipment.json"

    // MARK: – Single shared instance
    static let shared = EquipmentData()

    // MARK: – Private storage
    /// Read-only “seed” gear that ships inside the bundle
    private var bundledEquipment: [GymEquipment]

    /// Mutable user-created gear (lives in Documents/)
    @Published private(set) var userEquipment: [GymEquipment]
    @Published var bundledBaseWeights: [UUID: BaseWeight]

    // MARK: – Public unified view
    var allEquipment: [GymEquipment] { bundledEquipment + userEquipment }
    
    
    // MARK: – Init
    init() {
        let overrides = EquipmentData.loadBaseWeightsForBundle()
        let bundled = EquipmentData.loadBundledEquipment(overrides: overrides)
        let user = EquipmentData.loadUserEquipment(from: EquipmentData.userEquipmentFilename)

        self.bundledBaseWeights = overrides
        self.bundledEquipment   = bundled
        self.userEquipment      = user
    }
    
    // MARK: – Persistence Logic
    private static func loadBundledEquipment(overrides: [UUID: BaseWeight]) -> [GymEquipment] {
        do {
            let seed: [InitEquipment] = try Bundle.main.decode(bundledEquipmentFilename)
            let mapping = seed.map { item -> GymEquipment in
                var eq = GymEquipment(from: item)
                if let bw = overrides[eq.id] { eq.baseWeight = bw }   // <-- apply override
                return eq
            }
            print("✅ Successfully loaded \(mapping.count) equipment items from \(bundledEquipmentFilename)")
            return mapping
        } catch {
            print("❌ Standard decoding from equipment.json failed. Falling back to manual parsing...")
            return JSONFileManager.loadBundledData(
                filename: "equipment",
                itemType: "equipment",
                decoder: { jsonDict in
                    let equipmentData = try JSONSerialization.data(withJSONObject: jsonDict)
                    let initEquipment = try JSONDecoder().decode(InitEquipment.self, from: equipmentData)
                    var eq = GymEquipment(from: initEquipment)
                    if let bw = overrides[eq.id] { eq.baseWeight = bw }   // <-- apply override
                    return eq
                },
                validator: { equipment in
                    !equipment.name.isEmpty && !equipment.image.isEmpty
                }
            )
        }
    }

    private static func loadUserEquipment(from file: String) -> [GymEquipment] {
        return JSONFileManager.shared.loadUserEquipment(from: file) ?? []
    }

    private func persistUserEquipment() {
        let snapshot = userEquipment                  // value copy, thread-safe
        JSONFileManager.shared.save(snapshot, to: EquipmentData.userEquipmentFilename)
    }
    
    private static func loadBaseWeightsForBundle() -> [UUID: BaseWeight] {
        return JSONFileManager.shared.loadBaseWeights(from: EquipmentData.bundledBaseWeightsFilename) ?? [:]
    }
    
    private func persistBaseWeights() {
        let snapshot = bundledBaseWeights
        JSONFileManager.shared.save(snapshot, to: EquipmentData.bundledBaseWeightsFilename)
    }
}

extension EquipmentData {
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
    
    // MARK: – Helpers
    func isUserEquipment(_ equipment: GymEquipment) -> Bool {
        userEquipment.contains(where: { $0.id == equipment.id })
    }
    
    private func updateBundledBaseWeight(equipmentId: UUID, new: BaseWeight) {
        bundledBaseWeights[equipmentId] = new
        if let index = bundledEquipment.firstIndex(where: { $0.id == equipmentId }) {
            bundledEquipment[index].baseWeight = new
            persistBaseWeights()
        }
    }
    
    private func updateUserBaseWeight(equipmentId: UUID, new: BaseWeight) {
        if let index = userEquipment.firstIndex(where: { $0.id == equipmentId }) {
            userEquipment[index].baseWeight = new
            persistUserEquipment()
        }
    }
    
    func updateBaseWeight(equipment: GymEquipment, new: BaseWeight) {
        if isUserEquipment(equipment) {
            updateUserBaseWeight(equipmentId: equipment.id, new: new)
        } else {
            updateBundledBaseWeight(equipmentId: equipment.id, new: new)
        }
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

    func filteredEquipment(searchText: String, category: EquipmentCategory? = nil) -> [GymEquipment] {
        let searchKey = normalize(searchText.removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))) // make this a reusable func in Formatter

        var results = allEquipment.filter { item in
            // a) category
            let okCat = category.map { $0 == item.equCategory } ?? true

            // b) text match
            if searchKey.isEmpty { return okCat }

            let nameKey   = normalize(item.name)
            let aliasKeys = (item.aliases ?? []).map(normalize)

            let okText = nameKey.contains(searchKey) || aliasKeys.contains(where: { $0.contains(searchKey) })

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

    func equipmentForExercise(_ ex: Exercise, includeAlternatives: Bool = false) -> [GymEquipment] {
        let equipment = getEquipment(from: ex.equipmentRequired)
        if includeAlternatives {
            return equipment + alternativesFor(equipment: equipment)
        } else {
            return equipment
        }
    }
    
    func equipment(for id: UUID) -> GymEquipment? { allEquipment.first { $0.id == id } }
    
    func equipmentObjects(for selection: [UUID]) -> [GymEquipment] { selection.compactMap { equipment(for: $0) } }

    func equipmentForCategory(for rounding: RoundingCategory) -> [GymEquipment] {
        allEquipment.filter { $0.roundingCategory == rounding }
    }
    
    func alternativesFor(equipment: [GymEquipment]) -> [GymEquipment] {
        return getEquipment(from: Array(altFromOwned(equipment)))
    }
    
    func altFromOwned(_ equipment: [GymEquipment]) -> Set<String> {
        return Set(
            equipment
                .compactMap(\.alternativeEquipment)
                .flatMap { $0 }
                .map(normalize)
        )
    }

    func hasEquipmentAdjustments(for exercise: Exercise) -> Bool {
        exercise.equipmentRequired.contains { req in
            allEquipment.first(where: { normalize($0.name) == normalize(req) })?
                .adjustments?
                .isEmpty == false
        }
    }
    
    func incrementForEquipment(names: [String], rounding p: RoundingPreference) -> Mass {
        let names = names.map(normalize)
        let pref = (UnitSystem.current == .imperial) ? p.lb : p.kg
        
        let inc: Mass =
              names.contains { n in
                  allEquipment.contains { normalize($0.name) == n &&
                      ($0.equCategory == .weightMachines || $0.equCategory == .cableMachines) }
              } ? pref.pinLoaded
            : names.contains { n in
                  allEquipment.contains { normalize($0.name) == n && $0.equCategory == .smallWeights }
            } ? pref.smallWeights
            : names.contains { n in
                allEquipment.contains { normalize($0.name) == n && ($0.pegCount == .single) }
            } ? pref.platedSinglePeg
        : pref.plated
            
        return inc
    }
    
    // MARK: Weight rounding with string names
    func roundWeight(_ weight: Mass, for equipmentNames: [String], rounding p: RoundingPreference) -> Mass {
        let increment = incrementForEquipment(names: equipmentNames, rounding: p)

        // Round in the chosen unit, then convert back to canonical kg
        switch UnitSystem.current {
        case .imperial:
            let roundedLb = (weight.inLb / increment.inLb).rounded() * increment.inLb
            return Mass(lb: roundedLb)
            
        case .metric:
            let roundedKg = (weight.inKg / increment.inKg).rounded() * increment.inKg
            return Mass(kg: roundedKg)
        }
    }
}


