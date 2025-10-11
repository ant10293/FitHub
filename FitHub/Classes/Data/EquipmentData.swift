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
    private static let bundledEquipmentFilename: String = "equipment.json"
    private static let bundledBaseWeightsFilename: String = "base_weights.json"

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
    
    private static func loadBaseWeightsForBundle() -> [UUID: BaseWeight] {
        return JSONFileManager.shared.loadBaseWeights(from: EquipmentData.bundledBaseWeightsFilename) ?? [:]
    }
    
    // MARK: saving logic
    private func persistUserEquipment() {
        let snapshot = userEquipment                  // value copy, thread-safe
        JSONFileManager.shared.save(snapshot, to: EquipmentData.userEquipmentFilename)
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
        ].map { $0.normalize()  }.reduce(into: []) { $0.insert($1) }

        let bodyKit:  Set<String> = [
            "Pull-Up Bar", "Dip Bar"
        ].map { $0.normalize()  }.reduce(into: []) { $0.insert($1) }

        switch option {
        case "All (Gym Membership)":
            return allEquipment

        case "Some (Home Gym)":
            return allEquipment.filter { homeKit.contains($0.name.normalize()) }

        case "None (Bodyweight Only)":
            return allEquipment.filter { bodyKit.contains($0.name.normalize()) }

        default:
            return []
        }
    }

    func filteredEquipment(searchText: String, category: EquipmentCategory? = nil) -> [GymEquipment] {
        // ── 0. Cached constants (mirror exercises) ───────────────────────────────
        let removingSet      = TextFormatter.searchStripSet
        let normalizedSearch = searchText.normalized(removing: removingSet)
        
        // ── 1. Filter pass ───────────────────────────────────────────────────────
        var results: [GymEquipment] = []
        results.reserveCapacity(allEquipment.count)
        
        for item in allEquipment {
            // a) Category gate
            if let category, category != item.equCategory { continue }
            
            // b) Search-text gate
            if !normalizedSearch.isEmpty {
                let nameKey   = item.name.normalized(removing: removingSet)
                let aliasHit  = (item.aliases ?? []).contains { $0.normalized(removing: removingSet).contains(normalizedSearch) }
                if !(nameKey.contains(normalizedSearch) || aliasHit) { continue }
            }
            
            results.append(item)
        }
        
        // ── 2. Sort: prefix matches first, then alphabetical ─────────────────────
        if !normalizedSearch.isEmpty {
            results.sort { a, b in
                let na = a.name.normalized(removing: removingSet)
                let nb = b.name.normalized(removing: removingSet)
                let aStarts = na.hasPrefix(normalizedSearch)
                let bStarts = nb.hasPrefix(normalizedSearch)
                if aStarts != bStarts { return aStarts } // true first
                return na < nb
            }
        } else {
            results.sort { $0.name < $1.name }
        }
        
        return results
    }

    // MARK: Simple look-ups
    func category(for equipName: String) -> EquipmentCategory? {
        allEquipment.first { $0.name.normalize() == equipName.normalize() }?.equCategory
    }

    func getEquipment(from names: [String]) -> [GymEquipment] {
        let want = names.map { $0.normalize() }
        return allEquipment.filter { want.contains($0.name.normalize()) }
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
                .map { $0.normalize() }
        )
    }
     
    func hasEquipmentAdjustments(for exercise: Exercise) -> Bool {
        getEquipment(from: exercise.equipmentRequired)
            .contains { $0.adjustments?.isEmpty == false }
    }
    
    func incrementForEquipment(names: [String], rounding p: RoundingPreference) -> Mass {
        let pref = (UnitSystem.current == .imperial) ? p.lb : p.kg

        // Find the one equipment that has a rounding category
        let cat = getEquipment(from: names)
            .lazy
            .compactMap(\.roundingCategory)
            .first

        return pref[cat ?? .plated] ?? Mass(kg: 0)
    }
    
    // MARK: Weight rounding with string names
    func roundWeight(_ weight: Mass, for equipmentNames: [String], rounding p: RoundingPreference) -> Mass {
        let increment = incrementForEquipment(names: equipmentNames, rounding: p)

        // Round in the chosen unit, then convert back to canonical kg
        // FIXME: sometimes causes a week to pass without incrementing caused by rounding issues
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


