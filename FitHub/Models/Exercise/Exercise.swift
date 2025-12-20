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
    let implementCount: Int?
    let repsInstruction: RepsInstruction?
    let weightInstruction: WeightInstruction?
    let imageUrl: String?
    let unitType: ExerciseUnit
    let variationOf: String? // MARK: unused

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
        self.implementCount       = initEx.implementCount
        self.repsInstruction      = initEx.repsInstruction
        self.weightInstruction    = initEx.weightInstruction
        self.imageUrl             = initEx.imageUrl
        self.unitType             = initEx.unitType
        self.variationOf          = initEx.variationOf
    }
}
extension Exercise {
    private var fullImagePath: String { return "Exercises/\(image)" }

    var fullImage: Image { getFullImage(image, fullImagePath) }

    func fullImageView(favState: FavoriteState, detailIcon: Bool = false) -> some View {
        fullImage
        .resizable()
        .scaledToFit()
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .bottomLeading) {
            if detailIcon {
                Image(systemName: "info.circle")
                    .imageScale(.small)
                    .foregroundStyle(.blue)
            }
        }
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
        return (Text("Sets: ") + Text("\(workingSets), ").fontWeight(.light)
        + Text("\(label): ") + Text(range).fontWeight(.light))
            .foregroundStyle(Color.secondary)
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
        case .carry:
            // Distance range (e.g., "25m-50m")
            let distances = setDetails.compactMap { $0.planned.metersValue?.inM }
            guard let lo = distances.min(), let hi = distances.max() else { return (label, "0") }
            let loStr = "\(Int(lo))"
            let hiStr = "\(Int(hi))m"
            return (label, lo == hi ? hiStr : "\(loStr)-\(hiStr)")
        case .cardio:
            let secs = setDetails.compactMap { $0.planned.timeSpeed?.time.inSeconds }
            guard let lo = secs.min(), let hi = secs.max() else { return (label, "0:00") }
            let loStr = TimeSpan(seconds: lo).displayStringCompact
            let hiStr = TimeSpan(seconds: hi).displayStringCompact
            return (label, lo == hi ? loStr : "\(loStr)-\(hiStr)")
        }
    }

    var noSetsCompleted: Bool {
        allSetDetails.allSatisfy { $0.completed == nil }
    }

    var allowedWarmup: Bool {
        return usesWeight && usesReps
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

    var loadMetric: SetLoad {
        switch unitType {
        case .weightXreps, .weightXtime, .weightXdistance:
            return .weight(Mass(kg: 0))
        case .bandXreps:
            // Return band with unselected level to indicate selection needed
            return .band(ResistanceBandImplement(level: .unselected))
        case .distanceXtimeOrSpeed:
            return .distance(Distance(km: 0))
        case .repsOnly, .timeOnly:
            return .none
        }
    }

    var plannedMetric: SetMetric {
        switch unitType {
        case .weightXreps, .bandXreps, .repsOnly:
            return .reps(0)
        case .timeOnly, .weightXtime:
            return .hold(TimeSpan(seconds: 0))
        case .weightXdistance:
            return .carry(Meters(meters: 0))
        case .distanceXtimeOrSpeed:
            return .cardio(TimeOrSpeed())
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
        let equipmentList = equipmentData.equipmentForExercise(self, inclusion: .both)

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
    func canPerform(equipmentData: EquipmentData, available: Set<GymEquipment.ID>) -> Bool {
        // Ask: if we try to build the equipment set dynamically,
        // what would we end up using?
        let chosen = equipmentData.equipmentForExercise(
            self,
            inclusion: .dynamic,
            available: available
        )

        // If any chosen item is NOT actually available, then we had to
        // "fall back" to something the user doesn't own => can't perform
        return chosen.allSatisfy { available.contains($0.id) }
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
            case (.carry(let p), .carry(let c)): return c.inM >= p.inM
            default: return false
            }
        }

        let kg = equipmentData.incrementForEquipment(names: equipmentRequired, rounding: rounding).inKg
        let kgPerStep = kg * overloadFactor
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
                    updated.bumpPlanned(by: overloadProgress)

                case .decreaseReps:
                    // Fewer reps/seconds but +weight
                    updated.bumpPlanned(by: -overloadProgress)
                    let newKg = weight.inKg + Double(overloadProgress) * kgPerStep
                    updated.load = .weight(equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding))

                case .dynamic:
                    if overloadProgress <= halfway {
                        updated.bumpPlanned(by: overloadProgress)
                    } else {
                        // Reset planned target to baseline, then increase weight
                        updated.planned = setDetail.planned
                        let adj = overloadProgress - halfway
                        let newKg = weight.inKg + Double(adj) * kgPerStep
                        updated.load = .weight(equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding))
                    }
                }
                
            case .band(let currentBandImpl):
                // Bands: calculate new target weight and find matching band level
                let currentBandWeight = currentBandImpl.weight.resolvedMass.inKg
                
                var targetKg: Double? = nil
                switch style {
                case .increaseWeight:
                    targetKg = currentBandWeight + Double(overloadProgress) * kgPerStep
                case .increaseReps:
                    // For increaseReps, keep same band, just increase reps
                    updated.bumpPlanned(by: overloadProgress)
                case .decreaseReps:
                    updated.bumpPlanned(by: -overloadProgress)
                    targetKg = currentBandWeight + Double(overloadProgress) * kgPerStep
                case .dynamic:
                    if overloadProgress <= halfway {
                        updated.bumpPlanned(by: overloadProgress)
                    } else {
                        updated.planned = setDetail.planned
                        let adj = overloadProgress - halfway
                        targetKg = currentBandWeight + Double(adj) * kgPerStep
                    }
                }
                
                if let target = targetKg, let bestBandImpl = findBestBandImplement(for: target, equipmentData: equipmentData) {
                    updated.load = .band(bestBandImpl)
                }
                
            // TODO: implement for distance
            case .distance:
                break

            case .none:
                // Bodyweight: bump planned target only
                updated.bumpPlanned(by: overloadProgress)
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
                
            case .band(let currentBandImpl):
                // Bands: calculate scaled weight and find matching band level
                let currentBandWeight = currentBandImpl.weight.resolvedMass.inKg
                let scaledKg = currentBandWeight * deloadFactor
                
                if let bestBandImpl = findBestBandImplement(for: scaledKg, equipmentData: equipmentData) {
                    updated.load = .band(bestBandImpl)
                }
                
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
        let rounding     = userData.workoutPrefs.roundingPreference

        // Extract intensity settings
        let minIntensityPct = Double(userData.workoutPrefs.setIntensity.minIntensity) / 100.0
        let maxIntensityPct = Double(userData.workoutPrefs.setIntensity.maxIntensity) / 100.0
        let fixedIntensityPct = Double(userData.workoutPrefs.setIntensity.fixedIntensity) / 100.0
        let topSet = userData.workoutPrefs.setIntensity.topSet

        // Helper function to calculate intensity percentage for a given set
        func intensityPercentage(for setNumber: Int, totalSets: Int) -> Double {
            // If topSet is .allSets or setStructure is .fixed, use fixed intensity
            if topSet == .allSets || setStructure == .fixed {
                return fixedIntensityPct
            }

            // For single set, use max intensity
            guard totalSets > 1 else { return maxIntensityPct }

            switch topSet {
            case .firstSet:
                // First set = max, last set = min, interpolate in between
                if setNumber == 1 {
                    return maxIntensityPct
                } else if setNumber == totalSets {
                    return minIntensityPct
                } else {
                    let progress = Double(setNumber - 1) / Double(totalSets - 1)
                    return maxIntensityPct - (maxIntensityPct - minIntensityPct) * progress
                }
            case .lastSet:
                // First set = min, last set = max, interpolate in between
                if setNumber == 1 {
                    return minIntensityPct
                } else if setNumber == totalSets {
                    return maxIntensityPct
                } else {
                    let progress = Double(setNumber - 1) / Double(totalSets - 1)
                    return minIntensityPct + (maxIntensityPct - minIntensityPct) * progress
                }
            case .allSets:
                return fixedIntensityPct
            }
        }

        for n in 1...numSets {
            let load: SetLoad
            let planned: SetMetric
            let intensityPct = min(1.0, max(0.0, intensityPercentage(for: n, totalSets: numSets)))

            switch peak {
                // ───────── holds: drive off saved TimeSpan ─────────
            // TODO: .maxHold and .maxReps logic is basically identical, use single source of truth
            case .maxHold(let ts):
                let maxSec = max(1, ts.inSeconds)
                let sec: Int

                // Combine set structure with intensity settings
                switch setStructure {
                case .pyramid:
                    // Pyramid: start at min intensity, progress to max intensity
                    // Map intensity percentage (min to max) to seconds (minSec to maxSec)
                    let minSec = max(1, Int(round(Double(maxSec) * minIntensityPct)))
                    let progress = (intensityPct - minIntensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    sec = max(1, min(maxSec, minSec + Int(round(Double(maxSec - minSec) * progress))))

                case .reversePyramid:
                    // Reverse pyramid: start at max intensity, decrease to min intensity
                    let maxSecAtIntensity = max(1, Int(round(Double(maxSec) * maxIntensityPct)))
                    let minSecAtIntensity = max(1, Int(round(Double(maxSec) * minIntensityPct)))
                    let progress = (maxIntensityPct - intensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    sec = max(1, min(maxSec, maxSecAtIntensity - Int(round(Double(maxSecAtIntensity - minSecAtIntensity) * progress))))

                case .fixed:
                    // Fixed: use fixed intensity
                    sec = max(1, Int(round(Double(maxSec) * fixedIntensityPct)))
                }

                load = .none // should change if we add weighted isometric
                planned = .hold(TimeSpan(seconds: sec))

            // ───────── bodyweight reps: drive off saved max reps ─────────
            case .maxReps(let maxReps):
                let reps: Int

                // Combine set structure with intensity settings
                switch setStructure {
                case .pyramid:
                    // Pyramid: start at min intensity, progress to max intensity
                    let minReps = max(1, Int(round(Double(maxReps) * minIntensityPct)))
                    let maxRepsAtIntensity = max(1, Int(round(Double(maxReps) * maxIntensityPct)))
                    let progress = (intensityPct - minIntensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    reps = max(1, min(maxReps, minReps + Int(round(Double(maxRepsAtIntensity - minReps) * progress))))

                case .reversePyramid:
                    // Reverse pyramid: start at max intensity, decrease to min intensity
                    let maxRepsAtIntensity = max(1, Int(round(Double(maxReps) * maxIntensityPct)))
                    let minReps = max(1, Int(round(Double(maxReps) * minIntensityPct)))
                    let progress = (maxIntensityPct - intensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    reps = max(1, min(maxReps, maxRepsAtIntensity - Int(round(Double(maxRepsAtIntensity - minReps) * progress))))

                case .fixed:
                    // Fixed: use fixed intensity
                    reps = max(1, Int(round(Double(maxReps) * fixedIntensityPct)))
                }

                load = .none
                planned = .reps(reps)

            // ───────── weighted reps: compute target from 1RM ─────────
            case .oneRepMax(let oneRM):
                // Calculate target 1RM based on intensity percentage
                let target1RM = oneRM.inKg * intensityPct

                // Determine reps based on set structure (pyramid/reverse pyramid/fixed)
                let reps: Int
                switch setStructure {
                case .pyramid:
                    reps = range.upperBound - (n - 1) * (range.upperBound - range.lowerBound) / max(1, (numSets - 1))
                case .reversePyramid:
                    reps = range.lowerBound + (n - 1) * (range.upperBound - range.lowerBound) / max(1, (numSets - 1))
                case .fixed:
                    reps = (range.lowerBound + range.upperBound) / 2
                }

                // Calculate weight such that weight × reps estimates to target1RM
                // Formula: 1RM = weight / percent(at: reps)  =>  weight = 1RM * percent(at: reps)
                let formula = OneRMFormula.canonical
                let percentAtReps = formula.percent(at: reps)
                let targetWeight = Mass(kg: target1RM * percentAtReps)
                
                // For bandXreps, find the band level that matches the target weight
                if unitType == .bandXreps {
                    let targetKg = targetWeight.inKg
                    let bestBandImpl = findBestBandImplement(for: targetKg, equipmentData: equipmentData) ?? 
                        ResistanceBandImplement(level: .extraLight, color: nil, weight: BaseWeight(weight: 0))
                    load = .band(bestBandImpl)
                } else {
                    // Standard weight-based
                    let roundedWeight = equipmentData.roundWeight(targetWeight, for: equipmentRequired, rounding: rounding)
                    load = .weight(roundedWeight)
                }
                
                planned = .reps(max(1, reps))

            // TODO: .hold30sLoad and carry50mLoad logic is basically identical, use single source of truth
            case .hold30sLoad(let l30):
                // Plan: constant 30s holds; vary load by set structure and intensity.
                let tRefSec = WeightedHoldFormula.canonical.inSeconds
                let targetKg: Double

                // Combine set structure with intensity settings
                switch setStructure {
                case .pyramid:
                    // Pyramid: start at min intensity, progress to max intensity
                    let minKg = max(0.0, l30.inKg * minIntensityPct)
                    let maxKgAtIntensity = max(0.0, l30.inKg * maxIntensityPct)
                    let progress = (intensityPct - minIntensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    targetKg = minKg + (maxKgAtIntensity - minKg) * progress

                case .reversePyramid:
                    // Reverse pyramid: start at max intensity, decrease to min intensity
                    let maxKgAtIntensity = max(0.0, l30.inKg * maxIntensityPct)
                    let minKg = max(0.0, l30.inKg * minIntensityPct)
                    let progress = (maxIntensityPct - intensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    targetKg = maxKgAtIntensity - (maxKgAtIntensity - minKg) * progress

                case .fixed:
                    // Fixed: use fixed intensity
                    targetKg = max(0.0, l30.inKg * fixedIntensityPct)
                }

                let rounded = equipmentData.roundWeight(Mass(kg: targetKg), for: equipmentRequired, rounding: rounding)
                load = .weight(rounded)
                planned = .hold(TimeSpan(seconds: tRefSec))

            case .carry50mLoad(let l50):
                // Plan: constant 50m carries; vary load by set structure and intensity.
                let dRefMeters = WeightedCarryFormula.canonical
                let targetKg: Double

                // Combine set structure with intensity settings
                switch setStructure {
                case .pyramid:
                    // Pyramid: start at min intensity, progress to max intensity
                    let minKg = max(0.0, l50.inKg * minIntensityPct)
                    let maxKgAtIntensity = max(0.0, l50.inKg * maxIntensityPct)
                    let progress = (intensityPct - minIntensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    targetKg = minKg + (maxKgAtIntensity - minKg) * progress

                case .reversePyramid:
                    // Reverse pyramid: start at max intensity, decrease to min intensity
                    let maxKgAtIntensity = max(0.0, l50.inKg * maxIntensityPct)
                    let minKg = max(0.0, l50.inKg * minIntensityPct)
                    let progress = (maxIntensityPct - intensityPct) / max(0.01, maxIntensityPct - minIntensityPct)
                    targetKg = maxKgAtIntensity - (maxKgAtIntensity - minKg) * progress

                case .fixed:
                    // Fixed: use fixed intensity
                    targetKg = max(0.0, l50.inKg * fixedIntensityPct)
                }

                let rounded = equipmentData.roundWeight(Mass(kg: targetKg), for: equipmentRequired, rounding: rounding)
                load = .weight(rounded)
                planned = .carry(dRefMeters)

            // TODO: implement for cardio exercises
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

        // Only create warmup sets for weight × reps exercises
        guard case (.weight(let firstSetWeight), .reps(let firstSetReps)) = (baseline.load, baseline.planned) else {
            return
        }

        let warmupSettings = userData.workoutPrefs.warmupSettings
        guard warmupSettings.exerciseSelection.isCompatible(exercise: self) else { return }

        let rounding = userData.workoutPrefs.roundingPreference

        // Calculate warmup set count based on working set count
        let workingSets = setDetails.count
        let totalWarmUpSets = warmupSettings.setCountModifier.warmupSetCount(for: workingSets)
        guard totalWarmUpSets > 0 else { return }

        // Extract intensity settings
        let minIntensityPct = Double(warmupSettings.minIntensity) / 100.0
        let maxIntensityPct = Double(warmupSettings.maxIntensity) / 100.0

        // Helper function to calculate intensity percentage for a given warmup set
        func intensityPercentage(for setNumber: Int, totalSets: Int) -> Double {
            // For single warmup set, use min intensity
            guard totalSets > 1 else { return minIntensityPct }

            // Interpolate from min (first set) to max (last set)
            if setNumber == 1 {
                return minIntensityPct
            } else if setNumber == totalSets {
                return maxIntensityPct
            } else {
                let progress = Double(setNumber - 1) / Double(totalSets - 1)
                return minIntensityPct + (maxIntensityPct - minIntensityPct) * progress
            }
        }

        var details: [SetDetail] = []
        let baseKg = firstSetWeight.inKg

        for i in 0..<totalWarmUpSets {
            let idx = i + 1
            let intensityPct = intensityPercentage(for: idx, totalSets: totalWarmUpSets)

            // Apply intensity to first working set's weight
            let targetKg = baseKg * intensityPct
            let roundedWeight = equipmentData.roundWeight(Mass(kg: targetKg), for: equipmentRequired, rounding: rounding)

            details.append(
                SetDetail(
                    setNumber: idx,
                    load: .weight(roundedWeight),
                    planned: .reps(firstSetReps) // Keep reps the same as first working set
                )
            )
        }

        warmUpDetails = details
    }
}

extension Exercise {
    mutating func seedDraftMax(
        exerciseData: ExerciseData,
        userData: UserData,
        maxUpdated: @escaping (PerformanceUpdate) -> Void = { _ in }
    ) {
        if let max = exerciseData.peakMetric(for: self.id).valid {
            draftMax = max
        } else if let estMax = exerciseData.estimatedPeakMetric(for: self.id).valid {
            draftMax = estMax
        } else if let calcMax = CSVLoader.calculateMaxValue(for: self, userData: userData).valid {
            draftMax = calcMax
            maxUpdated(PerformanceUpdate(exerciseId: self.id, value: calcMax))
        }
    }
    
    /// Finds the best matching resistance band implement for a given target weight (in kg).
    /// Returns nil if no bands are available, otherwise returns the band implement closest to the target weight.
    private func findBestBandImplement(for targetKg: Double, equipmentData: EquipmentData) -> ResistanceBandImplement? {
        let available = equipmentData.implementsForExercise(self)
        guard let bands = available?.resistanceBands else { return nil }
        return bands.bestBand(for: targetKg)
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
    var primaryMusclesFormatted: some View {
        formattedMusclesView(from: primaryMuscleEngagements, showHeader: true, header: "Primary Muscles")
    }
    
    var secondaryMusclesFormatted: some View {
        formattedMusclesView(from: secondaryMuscleEngagements, showHeader: true, header: "Secondary Muscles")
    }
    
    @ViewBuilder
    private func formattedMusclesView(
        from engagements: [MuscleEngagement],
        showHeader: Bool = false,
        header: String = ""
    ) -> some View {

        let items: [String] = engagements
            .map { e in
                let subs = e.allSubMuscles.map(\.simpleName).joined(separator: ", ")
                let base = e.muscleWorked.rawValue
                return subs.isEmpty ? base : "\(base): \(subs)"
            }

        let displayItems = items.isEmpty ? ["None"] : items

        let body = NumberedListView(items: displayItems, numberingStyle: .bullet, spacing: 2)
            .font(.caption)

        if showHeader {
            VStack(alignment: .leading, spacing: 4) {
                Text(header).bold()
                body
            }
        } else {
            body
        }
    }
}
