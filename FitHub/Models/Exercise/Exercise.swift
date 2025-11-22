//
//  Exercise.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/3/25.
//

import Foundation
import SwiftUI

 
struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let aliases: [String]?
    let image: String
    let muscles: [MuscleEngagement]
    let instructions: ExerciseInstructions
    let equipmentRequired: [String]
    let effort: EffortType
    let resistance: ResistanceType
    let csvKey: String?
    let difficulty: StrengthLevel
    let limbMovementType: LimbMovementType? // no longer optional
    let repsInstruction: RepsInstruction?
    let weightInstruction: WeightInstruction?
    let imageUrl: String?

    var draftMax: PeakMetric?
    var isSupersettedWith: String?  // UUID String

    var currentSet: Int = 1
    var isCompleted: Bool = false
    var timeSpent: Int = 0

    var warmUpDetails: [SetDetail] = []
    var setDetails: [SetDetail] = []
    var allSetDetails: [SetDetail] { warmUpDetails + setDetails }
    var warmUpSets: Int { warmUpDetails.count }
    var workingSets: Int { setDetails.count }
    var totalSets: Int { warmUpSets + workingSets }
    var isWarmUp: Bool { currentSet <= warmUpSets }
    var currentSetIndex: Int { currentSet - 1 }
        
    var isDeloading: Bool = false
    var weeksStagnated: Int = 0
    var overloadProgress: Int = 0
}
extension Exercise {
    init(from initEx: InitExercise) {
        self.id                   = initEx.id
        self.name                 = initEx.name
        self.aliases              = initEx.aliases
        self.image                = initEx.image
        self.muscles              = initEx.muscles
        self.instructions         = initEx.instructions
        self.equipmentRequired    = initEx.equipmentRequired
        self.effort               = initEx.effort
        self.resistance           = initEx.resistance
        self.csvKey               = initEx.csvKey
        self.difficulty           = initEx.difficulty
        self.limbMovementType     = initEx.limbMovementType
        self.repsInstruction      = initEx.repsInstruction
        self.weightInstruction    = initEx.weightInstruction
        self.imageUrl             = initEx.imageUrl
    }
}
extension Exercise {
    private var fullImagePath: String { return "Exercises/\(image)" }
    
    var fullImage: Image { getFullImage(image, fullImagePath) }
    
    func fullImageView(favState: FavoriteState) -> some View {
        fullImage
        .resizable()
        .scaledToFit()
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .bottomTrailing) {
            let (image, color) = favState.systemImageName
            if let image, let color {
                Image(systemName: image)
                    .imageScale(.small)
                    .foregroundStyle(color)
            }
        }
    }
    
    func getPeakMetric(metricValue: Double) -> PeakMetric {
        unitType.getPeakMetric(metricValue: metricValue)
    }

    func performanceTitle(includeInstruction: Bool) -> String {
        let base = getPeakMetric(metricValue: 0).performanceTitle
        guard includeInstruction, let performanceInstruction else { return base }
        return base + " (\(performanceInstruction))"
    }
    
    private var performanceInstruction: String? {
        let w = weightInstruction?.rawValue
        let r = repsInstruction?.rawValue

        // Decide which instruction to append
        let instruction: String? = {
            if !usesWeight {
                // Non-loaded
                return (limbMovementType == .unilateral) ? (r?.isEmpty == false ? r : nil) : nil
            } else {
                // Loaded
                if let w, !w.isEmpty { return w }
                // Fallback for unilateral entries that only specify reps
                if limbMovementType == .unilateral, let r, !r.isEmpty { return r }
                return nil
            }
        }()

        return instruction
    }
        
    var setsSubtitle: Text {
        let (label, range) = setMetricRangeLabeled
        return Text("Sets: ") + Text("\(workingSets), ").fontWeight(.light)
        + Text("\(label): ") + Text(range).fontWeight(.light)
    }
    
    private var setMetricRangeLabeled: (label: String, range: String) {
        let label: String = plannedMetric.label
        guard let first = setDetails.first else { return (label, "0") }
        switch first.planned {
        case .reps:
            // Reps range (e.g., "8-12")
            let reps = setDetails.compactMap { $0.planned.repsValue }
            guard let lo = reps.min(), let hi = reps.max() else { return (label, "0") }
            return (label, Format.formatRange(range: lo...hi))
        case .hold:
            // Time range (e.g., "0:30–1:00")
            let secs = setDetails.compactMap { $0.planned.holdTime?.inSeconds }
            guard let lo = secs.min(), let hi = secs.max() else { return (label, "0:00") }
            let loStr = TimeSpan(seconds: lo).displayStringCompact
            let hiStr = TimeSpan(seconds: hi).displayStringCompact
            return (label, lo == hi ? loStr : "\(loStr)-\(hiStr)")
        case .cardio:
            let secs = setDetails.compactMap { $0.planned.timeSpeed?.time.inSeconds }
            guard let lo = secs.min(), let hi = secs.max() else { return (label, "0:00") }
            let loStr = TimeSpan(seconds: lo).displayStringCompact
            let hiStr = TimeSpan(seconds: hi).displayStringCompact
            return (label, lo == hi ? loStr : "\(loStr)-\(hiStr)")
        }
    }
    
    var noSetsCompleted: Bool {
        setDetails.allSatisfy { $0.completed == nil }
    }
    
    var usesWeight: Bool {
        switch resistance {
        case .machine: return effort != .cardio ? true : false
        case .freeWeight: return true
        case .bodyweight: return false
        case .banded: return false
        // any other, weighted - Only used for sorting, not an option
        case .weighted: return true
        case .any: return false
        }
    }
    
    var usesReps: Bool { effort.usesReps }
        
    var unitType: ExerciseUnit {
        switch effort {
        case .cardio:
            return .distanceXtimeOrSpeed
        case .isometric:
            return usesWeight ? .weightXtime : .timeOnly
        // compound / isolation / plyometric (anything reps-driven)
        default:
            return usesWeight ? .weightXreps : .repsOnly
        }
    }
    
    var loadMetric: SetLoad {
        switch unitType {
        case .weightXreps, .weightXtime:
            return .weight(Mass(kg: 0))
        case .distanceXtimeOrSpeed:
            return .distance(Distance(km: 0))
        case .repsOnly, .timeOnly:
            return .none
        }
    }
    
    // FIXME: use value and pass distance
    var plannedMetric: SetMetric {
        switch unitType {
        case .weightXreps, .repsOnly:
            return .reps(0)
        case .timeOnly, .weightXtime:
            return .hold(TimeSpan(seconds: 0))
        case .distanceXtimeOrSpeed:
            return .cardio(TimeOrSpeed(time: TimeSpan(seconds: 0), distance: Distance(km: 0)))
        }
    }

    func getRestPeriod(isWarm: Bool, rest: RestPeriods) -> Int {
        if isWarm {
            return rest.rest(for: .warmup)
        } else if isSupersettedWith != nil {
            return rest.rest(for: .superset)
        } else {
            return rest.rest(for: .working)
        }
    }
    
    func usesPlates(equipmentData: EquipmentData) -> Bool {
        let equipmentList = equipmentData.equipmentForExercise(self, includeAlternatives: true)

        // If ANY equipment in the list is a weight machine → false
        if equipmentList.contains(where: { ($0.pegCount ?? .none).count > 0 }) {
            return true
        } else {
            return false
        }
    }
}

extension Exercise {
    @inline(__always)
    func resistanceOK(_ selectedType: ResistanceType) -> Bool {
        switch selectedType {
        case .any:        return true
        case .bodyweight: return !usesWeight // or resistance == .bodyweight
        case .weighted:   return usesWeight
        case .freeWeight: return resistance == .freeWeight
        case .machine:    return resistance == .machine
        case .banded:     return resistance == .banded
        }
    }
    
    func effortOK(_ rAndS: RepsAndSets) -> Bool {
        // Check if the effort type has sets configured
        let hasSets = rAndS.sets.sets(for: effort) > 0
            
        // Check if the effort type has a positive distribution percentage
        let hasDistribution = rAndS.distribution.percentage(for: effort) > 0
            
        return hasSets && hasDistribution
    }
    
    func difficultyOK(_ strengthValue: Int) -> Bool {
        return difficulty.strengthValue <= strengthValue
    }
    
    /// Returns `true` if *every* piece of required equipment can be satisfied
    /// either directly or via a declared alternative.    
    func canPerform(equipmentData: EquipmentData, equipmentSelected: [UUID]) -> Bool {
        // Retrieve GymEquipment objects from stored UUIDs
        let equipmentObjects = equipmentData.equipmentObjects(for: equipmentSelected)
        // 1️⃣ Gear the user explicitly owns
        let owned: Set<String> = Set(equipmentObjects.map { $0.name.normalize() })
        // 2️⃣ Alternatives provided BY the gear the user owns
        let altFromOwned: Set<String> = equipmentData.altFromOwned(equipmentObjects)
        let allowed = owned.union(altFromOwned)
        // 3️⃣  Build lookup of each *required* item → its own alternatives
        let neededGear = equipmentData.equipmentForExercise(self)  // [GymEquipment]
        let altForRequired: [String: Set<String>] = neededGear.reduce(into: [:]) { dict, gear in
            dict[gear.name.normalize()] = Set((gear.alternativeEquipment ?? []).map { $0.normalize() })
        }
        // 4️⃣  Check every requirement
        for raw in equipmentRequired {   // [String]
            let req = raw.normalize()
            if allowed.contains(req) { continue } // Own the exact item?
            // Own an acceptable alternative?
            if let altSet = altForRequired[req], !owned.isDisjoint(with: altSet) { continue }
            return false // Missing both required item and its alternatives
        }
        
        return true
    }
    
    func similarityPct(to other: Exercise) -> Double {
        muscles.similarityPct(to: other.muscles)
    }
}

extension Exercise {
    mutating func applyProgressiveOverload(
        equipmentData: EquipmentData,
        period: Int,
        style: ProgressiveOverloadStyle,
        rounding: RoundingPreference,
        overloadFactor: Double,
        oldExercise: Exercise? = nil
    ) -> Bool {
        // map old sets by setNumber for O(1) lookup
        let oldBySet: [Int: SetDetail] = Dictionary(
            uniqueKeysWithValues: (oldExercise?.setDetails ?? []).map { ($0.setNumber, $0) }
        )

        // strict equality: planned must equal or exceed completed
        func metPlan(_ prev: SetDetail) -> Bool {
            guard let completed = prev.completed else { return false }
            switch (prev.planned, completed) {
            case (.reps(let p), .reps(let c)): return c >= p
            case (.hold(let p), .hold(let c)): return c.inSeconds >= p.inSeconds
            default: return false
            }
        }
        
        let kg = equipmentData.incrementForEquipment(names: equipmentRequired, rounding: rounding).inKg
        let kgPerStep = kg * overloadFactor
        let secPerStep = SetDetail.secPerStep
        let halfway = max(1, period / 2)
        
        var overloadApplied: Bool = false
        setDetails = setDetails.map { setDetail in
            // decide eligibility: no old set => true, else require metPlan
            let eligible: Bool = {
                if let prev = oldBySet[setDetail.setNumber] {
                    let met = metPlan(prev)
                    if met { overloadApplied = true }
                    return met
                }
                return true // no old set -> always apply
            }()

            guard eligible else { return setDetail } // leave as-is if not eligible
            
            var updated = setDetail
            
            switch setDetail.load {
            case .weight(let weight):
                switch style {
                case .increaseWeight:
                    let newKg = weight.inKg + Double(overloadProgress) * kgPerStep
                    updated.load = .weight(equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding))
                    
                case .increaseReps:
                    updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
                    
                case .decreaseReps:
                    // Fewer reps/seconds but +weight
                    updated.bumpPlanned(by: -overloadProgress, secondsPerStep: secPerStep)
                    let newKg = weight.inKg + Double(overloadProgress) * kgPerStep
                    updated.load = .weight(equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding))

                case .dynamic:
                    if overloadProgress <= halfway {
                        updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
                    } else {
                        // Reset planned target to baseline, then increase weight
                        updated.planned = setDetail.planned
                        let adj = overloadProgress - halfway
                        let newKg = weight.inKg + Double(adj) * kgPerStep
                        updated.load = .weight(equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding))
                    }
                }
            // TODO: implement for distance
            case .distance:
                break
                
            case .none:
                // Bodyweight: bump planned target only
                updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
            }
            
            return updated
        }
        
        return overloadApplied
    }
    
    mutating func applyDeload(equipmentData: EquipmentData, deloadPct: Int, rounding: RoundingPreference) {
        let deloadFactor = Double(deloadPct) / 100.0
        
        setDetails = setDetails.map { setDetail in
            var updated = setDetail
            
            switch setDetail.load {
            case .weight(let weight):
                let scaledKg = weight.inKg * deloadFactor
                updated.load = .weight(equipmentData.roundWeight(Mass(kg: scaledKg), for: equipmentRequired, rounding: rounding))
            // TODO: implement for distance
            case .distance:
                break
            case .none:
                // Bodyweight: scale planned target
                updated.planned = setDetail.planned.scaling(by: deloadFactor)
            }
            
            return updated
        }
    }
    
    mutating func createSetDetails(repsAndSets: RepsAndSets, userData: UserData, equipmentData: EquipmentData) {
        guard let peak = self.draftMax else { return }
        
        var details: [SetDetail] = []
        let numSets      = repsAndSets.getSets(for: effort); guard numSets > 0 else { return }
        let range        = repsAndSets.repRange(for: effort)   // still used for rep-based
        let setStructure = userData.workoutPrefs.setStructure
        let rounding     = userData.settings.roundingPreference
        
        for n in 1...numSets {
            let load: SetLoad
            let planned: SetMetric

            switch peak {
                // ───────── holds: drive off saved TimeSpan ─────────
            // TODO: .maxHold and .maxReps logic is basically identical, use single source of truth
            case .maxHold(let ts):
                let maxSec = max(1, ts.inSeconds)
                let sec: Int
                switch setStructure {
                case .pyramid:
                    let minSec = max(1, Int(Double(maxSec) * 0.80)) // 80% → … → 100% across the sets
                    let step   = max(1, (maxSec - minSec) / max(1, numSets - 1))
                    sec = min(maxSec, minSec + step * (n - 1))

                case .reversePyramid:
                    let dec = max(1, Int(Double(maxSec) * 0.10)) // Start at 100%, drop ~10% per set
                    sec = max(1, maxSec - dec * (n - 1))

                case .fixed:
                    sec = min(maxSec, max(1, Int(Double(maxSec) * 0.95))) // ~95% of max, constant
                }
                load = .none // should change if we add weighted isometric
                planned = .hold(TimeSpan(seconds: sec))

            // ───────── bodyweight reps: drive off saved max reps ─────────
            case .maxReps(let maxReps):
                let reps: Int
                switch setStructure {
                case .pyramid:
                    if numSets == 1 || n == numSets {
                        reps = maxReps
                    } else {
                        let progress = Double(n - 1) / Double(numSets - 1) // 0.0 to 1.0
                        let targetPercentage = 0.8 + (0.2 * progress) // 80% to 100%
                        reps = Int(round(Double(maxReps) * targetPercentage))
                    }
                case .reversePyramid:
                    let dec = max(1, Int(0.10 * Double(maxReps))) // Start at 100%, drop ~10% per set
                    reps = max(1, maxReps - dec * (n - 1))
                case .fixed:
                    reps = max(1, Int(Double(maxReps) * 0.95)) // ~95% of max, constant
                }
                load = .none
                planned = .reps(reps)

            // ───────── weighted reps: compute target from 1RM ─────────
            case .oneRepMax(let oneRM):
                let reps: Int
                switch setStructure {
                case .pyramid:
                    reps = range.upperBound - (n - 1) * (range.upperBound - range.lowerBound) / max(1, (numSets - 1))
                case .reversePyramid:
                    reps = range.lowerBound + (n - 1) * (range.upperBound - range.lowerBound) / max(1, (numSets - 1))
                case .fixed:
                    reps = (range.lowerBound + range.upperBound) / 2
                }
                let target = SetDetail.calculateSetWeight(oneRm: oneRM, reps: reps)
                load = .weight(equipmentData.roundWeight(target, for: equipmentRequired, rounding: rounding))
                planned = .reps(max(1, reps))
                
            case .hold30sLoad(let l30):
                // Plan: constant 30s holds; vary load by structure %.
                let tRefSec = WeightedHoldFormula.canonical.inSeconds
                let pct: Double
                switch setStructure {
                case .pyramid:
                    // 80% → 100% across sets
                    let progress = (numSets > 1) ? Double(n - 1) / Double(numSets - 1) : 1.0
                    pct = 0.80 + 0.20 * progress
                case .reversePyramid:
                    // 100% then ~90% then ~80%...
                    pct = max(0.50, 1.00 - 0.10 * Double(n - 1))
                case .fixed:
                    // ~95% steady
                    pct = 0.95
                }
                let targetKg = max(0.0, l30.inKg * pct)
                let rounded = equipmentData.roundWeight(Mass(kg: targetKg), for: equipmentRequired, rounding: rounding)
                load = .weight(rounded)
                planned = .hold(TimeSpan(seconds: tRefSec))
            
            // TODO: implement for weighted hold and cardio exercises
            case .none:
                load = loadMetric
                planned = plannedMetric
            }
            
            details.append(SetDetail(setNumber: n, load: load, planned: planned))
        }

        setDetails = details
    }
    
    mutating func createWarmupDetails(equipmentData: EquipmentData, userData: UserData) {
        guard let baseline = setDetails.first else { return }

        let setStructure = userData.workoutPrefs.setStructure
        let rounding = userData.settings.roundingPreference
        
        let totalWarmUpSets: Int
        let reductionSteps: [Double]
        let repSteps: [Int] // reps or seconds, depending on metric
        switch setStructure {
        case .pyramid:
            totalWarmUpSets = 2
            reductionSteps = [0.50, 0.65]
            repSteps = [12, 10]
        case .reversePyramid, .fixed:
            totalWarmUpSets = 3
            reductionSteps = [0.50, 0.65, 0.80]
            repSteps = [10, 8, 6]
        }
        
        var details: [SetDetail] = []

        for i in 0..<totalWarmUpSets {
            let idx = i + 1
            
            // rep, and hold based exercises should not require a warmup.
            switch (baseline.load, baseline.planned) {
            case (.weight(let weight), .reps):
                let reps = repSteps[i]
                let baseKg = weight.inKg
                let targetKg = baseKg * reductionSteps[i]
                var warmW = Mass(kg: targetKg)
                warmW = equipmentData.roundWeight(warmW, for: equipmentRequired, rounding: rounding)
                details.append(
                    SetDetail(
                        setNumber: idx,
                        load: .weight(warmW),
                        planned: .reps(reps)
                    )
                )
                
            default:
                break
            }
        }

        warmUpDetails = details
    }
}

extension Exercise {
    var primaryMuscleEngagements: [MuscleEngagement] { muscles.primary }
    var secondaryMuscleEngagements: [MuscleEngagement] { muscles.secondary }
    
    var primaryMuscles: [Muscle]   { muscles.primaryMuscles }
    var secondaryMuscles: [Muscle] { muscles.secondaryMuscles }
    var allMuscles: [Muscle]       { muscles.allMuscles }
    
    var primarySubMuscles: [SubMuscles]?   { muscles.primary.allSubMuscles.nilIfEmpty }
    var secondarySubMuscles: [SubMuscles]? { muscles.secondary.allSubMuscles.nilIfEmpty }
    var allSubMuscles: [SubMuscles]?       { muscles.allSubMuscles.nilIfEmpty }
    
    /// Highest-engagement primary muscle (nil if none)
    var topPrimaryMuscle: Muscle? { muscles.topPrimaryMuscle }
    
    /// Auto-derived split category from dominant prime mover
    var splitCategory: SplitCategory? { topPrimaryMuscle?.splitCategory }
    
    /// Legacy no-arg property (uses non-generation mapping).
    var groupCategory: SplitCategory? {
        groupCategory(forGeneration: false)
    }
    /// Higher-level group category if you have that mapping
    func groupCategory(forGeneration: Bool = false) -> SplitCategory? {
        topPrimaryMuscle?.groupCategory(forGeneration: forGeneration)
    }
}

extension Exercise {
    /// Prefer groupCategory if available; otherwise fall back to splitCategory
    private var bucketCategory: SplitCategory { groupCategory ?? splitCategory ?? .all }

    var isUpperBody: Bool { SplitCategory.upperBody.contains(bucketCategory) }
    var isLowerBody: Bool { SplitCategory.lowerBody.contains(bucketCategory) }
    var isPush:      Bool { SplitCategory.push.contains(bucketCategory) }
    var isPull:      Bool { SplitCategory.pull.contains(bucketCategory) }
}

extension Exercise {
    // MARK: – Public computed properties
    var musclesTextFormatted: Text { formattedMuscles(from: primaryMuscleEngagements + secondaryMuscleEngagements) }
    var primaryMusclesFormatted: Text {
        formattedMuscles(from: primaryMuscleEngagements, showHeader: true, header: "Primary Muscles:")
    }

    var secondaryMusclesFormatted: Text {
        formattedMuscles(from: secondaryMuscleEngagements, showHeader: true, header: "Secondary Muscles:")
    }

    private func formattedMuscles(
        from engagements: [MuscleEngagement],
        showHeader: Bool = false,
        header: String = ""
    ) -> Text {
        // Build a bullet-point line for every engagement
        let lines: [Text] = engagements.map { e in
            let name = Text("• \(e.muscleWorked.rawValue): ").bold()

            let subs = e.allSubMuscles
                .map { $0.simpleName }
                .joined(separator: ", ")

            return subs.isEmpty ? name : name + Text(subs)
        }

        // no muscles
        guard let first = lines.first else {
            let body = Text("• None")
            return showHeader ? Text(header).bold() + Text("\n") + body : body
        }

        let body = lines.dropFirst().reduce(first) { $0 + Text("\n") + $1 }
            .font(.caption)
            .foregroundStyle(.secondary)

        if showHeader {
            return Text(header).bold() + Text("\n") + body
        } else {
            return body
        }
    }
}


