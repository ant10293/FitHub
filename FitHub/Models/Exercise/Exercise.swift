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
    let description: String // TODO: remove or change to 'note: String?'
   // let instructions: ExerciseInstructions
    let equipmentRequired: [String]
    let effort: EffortType
    let resistance: ResistanceType
    let url: String?
    let difficulty: StrengthLevel
    let equipmentAdjustments: ExerciseEquipmentAdjustments?
    let limbMovementType: LimbMovementType? // no longer optional
    let repsInstruction: RepsInstruction?
    let weightInstruction: WeightInstruction?
    
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
        
    var currentWeekAvgRPE: RPEentry?
    var previousWeeksAvgRPE: RPEentries?
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
        self.description          = initEx.description
        //self.instructions         = initEx.instructions
        self.equipmentRequired    = initEx.equipmentRequired
        self.effort               = initEx.effort
        self.resistance           = initEx.resistance
        self.url                  = initEx.url
        self.equipmentAdjustments = initEx.equipmentAdjustments
        self.difficulty           = initEx.difficulty
        self.limbMovementType     = initEx.limbMovementType
        self.repsInstruction      = initEx.repsInstruction
        self.weightInstruction    = initEx.weightInstruction
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
            .overlay(alignment: .bottomTrailing, content: {
                if favState == .favorite {
                    Image(systemName: "heart.fill")
                        .imageScale(.small)
                        .foregroundStyle(.red)
                } else if favState == .disliked {
                    Image(systemName: "hand.thumbsdown.fill")
                        .imageScale(.small)
                        .foregroundStyle(.blue)
                }
            })
    }
    
    var performanceTitle: String { resistance.usesWeight ? "One Rep Max" : (effort.usesReps ? "Max Reps" : "Max Hold") }
    
    var peformanceUnit: String { resistance.usesWeight ? UnitSystem.current.weightUnit : (effort.usesReps ? "reps" : "sec") }
    
    var fieldLabel: String { resistance.usesWeight ? "weight" : (effort.usesReps ? "reps" : "time") }
    
    var setsSubtitle: Text {
        let (label, range) = setMetricRangeLabeled
        return Text("Sets: ") + Text("\(workingSets), ").fontWeight(.light)
             + Text("\(label): ") + Text(range).fontWeight(.light)
    }
    
    private var setMetricRangeLabeled: (label: String, range: String) {
        guard let first = setDetails.first else { return (getPlannedMetric(value: 0).label, "0") }
        
        switch first.planned {
        case .reps:
            // Reps range (e.g., "8-12")
            let reps = setDetails.compactMap { $0.planned.repsValue }
            guard let lo = reps.min(), let hi = reps.max() else { return ("Reps", "0") }
            return ("Reps", lo == hi ? "\(lo)" : "\(lo)-\(hi)")
        case .hold:
            // Time range (e.g., "0:30–1:00")
            let secs = setDetails.compactMap { $0.planned.holdTime?.inSeconds }
            guard let lo = secs.min(), let hi = secs.max() else { return ("Hold", "0:00") }
            let loStr = TimeSpan(seconds: lo).displayStringCompact
            let hiStr = TimeSpan(seconds: hi).displayStringCompact
            return ("Hold", lo == hi ? loStr : "\(loStr)-\(hiStr)")
        }
    }
        
    func metricDouble(from value: Double) -> Double {
        if resistance.usesWeight {
            return UnitSystem.current == .imperial ? UnitSystem.LBtoKG(value) : value
        } else {
            return Double(value)
        }
    }
    
    func getPeakMetric(metricValue: Double) -> PeakMetric {
        if resistance.usesWeight {
            .oneRepMax(Mass(kg: metricValue))
        } else {
            if effort.usesReps {
                .maxReps(Int(metricValue))
            } else {
                .maxHold(TimeSpan.init(seconds: Int(metricValue)))
            }
        }
    }
    
    func getLoadMetric(metricValue: Double) -> SetLoad {
        let peak = getPeakMetric(metricValue: metricValue)
        switch peak {
        case .oneRepMax(let m): return .weight(m)
        case .maxReps, .maxHold: return .none
        // TODO: add for cardio
        }
    }
    
    func getPlannedMetric(value: Int) -> SetMetric {
        if effort.usesReps {
            .reps(value)
        } else {
            .hold(TimeSpan.init(seconds: value))
        }
    }
    
    func calculateCSVMax(userData: UserData) -> PeakMetric? {
        guard let url = self.url else { return nil }
        
        let peak = getPeakMetric(metricValue: 0)
        switch peak {
        case .oneRepMax:
            return CSVLoader.calculateFinal1RM(userData: userData, exercise: url)
        case .maxReps:
            return CSVLoader.calculateFinalReps(userData: userData, exercise: url)
        default:
            return nil
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
    var primaryMuscleEngagements: [MuscleEngagement] { muscles.primary }
    var secondaryMuscleEngagements: [MuscleEngagement] { muscles.secondary }
    
    var primaryMuscles: [Muscle]   { muscles.primaryMuscles }
    var secondaryMuscles: [Muscle] { muscles.secondaryMuscles }
    var allMuscles: [Muscle]       { muscles.allMuscles }
    
    var primarySubMuscles: [SubMuscles]?   { muscles.primary.allSubMuscles.nilIfEmpty }
    var secondarySubMuscles: [SubMuscles]? { muscles.secondary.allSubMuscles.nilIfEmpty }
    var allSubMuscles: [SubMuscles]?       { muscles.allSubMuscles.nilIfEmpty }
    
    /// Highest-engagement primary muscle (nil if none)
    private var topPrimaryMuscle: Muscle? { muscles.topPrimaryMuscle }
    
    /// Auto-derived split category from dominant prime mover
    var splitCategory: SplitCategory { topPrimaryMuscle?.splitCategory ?? .all }
    
    /// Higher-level group category if you have that mapping
    var groupCategory: SplitCategory? { topPrimaryMuscle?.groupCategory }
}

extension Exercise {
    @inline(__always)
    func resistanceOK(_ selectedType: ResistanceType) -> Bool {
        switch selectedType {
        case .any:        return true
        case .bodyweight: return !resistance.usesWeight
        case .weighted:   return resistance.usesWeight
        case .freeWeight: return resistance == .freeWeight
        case .machine:    return resistance == .machine
        case .banded:     return resistance == .banded
        case .other:      return resistance == .other
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
        let owned: Set<String> = Set(equipmentObjects.map { normalize($0.name) })

        // 2️⃣ Alternatives provided BY the gear the user owns
        let altFromOwned: Set<String> = equipmentData.altFromOwned(equipmentObjects)
        
        let allowed = owned.union(altFromOwned)
        
        // 3️⃣  Build lookup of each *required* item → its own alternatives
        let neededGear = equipmentData.equipmentForExercise(self)     // [GymEquipment]
        let altForRequired: [String: Set<String>] = neededGear.reduce(into: [:]) { dict, gear in
            dict[normalize(gear.name)] = Set((gear.alternativeEquipment ?? []).map(normalize))
        }
        
        // 4️⃣  Check every requirement
        for raw in equipmentRequired {          // [String]
            let req = normalize(raw)
            
            // Own the exact item?
            if allowed.contains(req) { continue }
            
            // Own an acceptable alternative?
            if let altSet = altForRequired[req], !owned.isDisjoint(with: altSet) { continue }
            
            // Missing both required item and its alternatives
            return false
        }
        
        return true
    }
    
    mutating func resetState() {
        currentSet = 1
        timeSpent = 0
        isCompleted = false
        
        // Reset repsCompleted & rpe for each setDetail in the exercise
        for setIndex in setDetails.indices { setDetails[setIndex].resetState() }
        
        // Reset repsCompleted & rpe for each warmup set in the exercise
        for setIndex in warmUpDetails.indices { warmUpDetails[setIndex].resetState() }
    }
    
    mutating func setRPE(hadNewPR: Bool, startDate: Date) {
        if hadNewPR {
            //print("new pr set this week. resetting rpe.")
            currentWeekAvgRPE = nil
            previousWeeksAvgRPE = nil
            return
        }
        
        let (avgPeakMetric, avgRPE) = avgPeakAndRPE
        guard let avgRPE = avgRPE else { return }
        let new = RPEentry(id: startDate, rpe: avgRPE, completion: avgPeakMetric)
        
        if let current = currentWeekAvgRPE, current.id != startDate {
            //print("existing rpe found. Setting \(current) as last week rpe.")
            if previousWeeksAvgRPE == nil { previousWeeksAvgRPE = RPEentries(entries: []) }
            previousWeeksAvgRPE?.entries.removeAll { $0.id == current.id } // avoid duplicates, overwrite with newest
            previousWeeksAvgRPE?.entries.append(current)
            //if let prevList = previousWeeksAvgRPE { print("previous weeks rpes: \(prevList)") }
        }
        
        // Ensure no same-week entry lives in 'previous'
        previousWeeksAvgRPE?.entries.removeAll { $0.id == startDate }
        
        // Set/overwrite current week
        currentWeekAvgRPE = new
    }
    
    private var avgPeakAndRPE: (peak: PeakMetric, rpe: Double?) {
        let zero = getPeakMetric(metricValue: 0)
        let acc = setDetails.reduce(into: (pSum: 0.0, pCnt: 0, rSum: 0.0, rCnt: 0)) { a, s in
            if let pm = s.completedPeakMetric(peak: zero) {
                a.pSum += pm.actualValue          // adjust if your value prop differs
                a.pCnt += 1
            }
            if let r = s.rpe {                    // Int? or Double? -> cast to Double
                a.rSum += Double(r)
                a.rCnt += 1
            }
        }

        let peak = acc.pCnt > 0 ? getPeakMetric(metricValue: acc.pSum / Double(acc.pCnt)) : zero
        let rpe  = acc.rCnt > 0 ? acc.rSum / Double(acc.rCnt) : nil
        return (peak, rpe)
    }
}

extension Exercise {
    /// Prefer groupCategory if available; otherwise fall back to splitCategory
    private var bucketCategory: SplitCategory { groupCategory ?? splitCategory }

    var isUpperBody: Bool { SplitCategory.upperBody.contains(bucketCategory) }
    var isLowerBody: Bool { SplitCategory.lowerBody.contains(bucketCategory) }
    var isPush:      Bool { SplitCategory.push.contains(bucketCategory) }
    var isPull:      Bool { SplitCategory.pull.contains(bucketCategory) }
}


extension Exercise {
    /*
     TODO: utilize oldExercise to ensure that overloading remains smooth and does not progress too slowly or quickly
     also ensure that overloadFactor is implemented
    */
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
            
            /*
            if !resistance.usesWeight {
                // Bodyweight: bump planned target only
                updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
            } else {
                switch style {
                case .increaseWeight:
                    let newKg = setDetail.weight.inKg + Double(overloadProgress) * kgPerStep
                    updated.weight = equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding)
                    
                case .increaseReps:
                    updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
                    
                case .decreaseReps:
                    // Fewer reps/seconds but +weight
                    updated.bumpPlanned(by: -overloadProgress, secondsPerStep: secPerStep)
                    let newKg = setDetail.weight.inKg + Double(overloadProgress) * kgPerStep
                    updated.weight = equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding)
                    
                case .dynamic:
                    if overloadProgress <= halfway {
                        updated.bumpPlanned(by: overloadProgress, secondsPerStep: secPerStep)
                    } else {
                        // Reset planned target to baseline, then increase weight
                        updated.planned = setDetail.planned
                        let adj = overloadProgress - halfway
                        let newKg = setDetail.weight.inKg + Double(adj) * kgPerStep
                        updated.weight = equipmentData.roundWeight(Mass(kg: newKg), for: equipmentRequired, rounding: rounding)
                    }
                }
            }
            */
            
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
            case .distance(let distance):
                // TODO: implement for distance
                break
            case .none:
                break
                
            }
            
            return updated
        }
        
        return overloadApplied
    }
    
    mutating func applyDeload(equipmentData: EquipmentData, deloadPct: Int, rounding: RoundingPreference) {
        let deloadFactor = Double(deloadPct) / 100.0
        
        setDetails = setDetails.map { setDetail in
            var updated = setDetail
            
            /*
            if resistance.usesWeight {
                // Weighted: scale load
                let scaledKg = setDetail.weight.inKg * deloadFactor
                updated.weight = equipmentData.roundWeight(Mass(kg: scaledKg), for: equipmentRequired, rounding: rounding)
            } else {
                // Bodyweight: scale planned target
                updated.planned = setDetail.planned.scaling(by: deloadFactor)
            }
            */
            
            switch setDetail.load {
            case .weight(let weight):
                let scaledKg = weight.inKg * deloadFactor
                updated.load = .weight(equipmentData.roundWeight(Mass(kg: scaledKg), for: equipmentRequired, rounding: rounding))
            case .distance(let distance):
                // TODO: implement for distance
                break
            case .none:
                break
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
            //var weight = Mass(kg: 0)
            let load: SetLoad
            let planned: SetMetric

            switch peak {
                // ───────── holds: drive off saved TimeSpan ─────────
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
                planned = .hold(.fromSeconds(sec))

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
            }
            
            details.append(SetDetail(setNumber: n, load: load, planned: planned))
        }

        setDetails = details
    }
    
    mutating func createWarmupDetails(equipmentData: EquipmentData, userData: UserData) {
        guard let baseline = setDetails.first else { return }

        let setStructure = userData.workoutPrefs.setStructure
        let rounding = userData.settings.roundingPreference
        
        var details: [SetDetail] = []
        var totalWarmUpSets = 0
        var reductionSteps: [Double] = []
        var repSteps: [Int] = [] // reps or seconds, depending on metric

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

        for i in 0..<totalWarmUpSets {
            let idx = i + 1
            
            /*
            switch baseline.planned {
            case .reps:
                let reps = repSteps[i]
                if resistance.usesWeight {
                    // percent of working weight, modest reps
                    let baseKg   = baseline.weight.inKg
                    let targetKg = baseKg * reductionSteps[i]
                    var warmW    = Mass(kg: targetKg)
                    warmW = equipmentData.roundWeight(warmW, for: equipmentRequired, rounding: rounding)
                    details.append(SetDetail(
                        setNumber: idx,
                        weight: warmW,
                        planned: .reps(reps)
                    ))
                } else {
                    // bodyweight reps warmups: just use the step reps
                    details.append(SetDetail(
                        setNumber: idx,
                        weight: Mass(kg: 0),
                        planned: .reps(reps)
                    ))
                }
            case .hold:
                // isometric warmups: shorter holds (seconds), weight stays as baseline (usually 0)
                let baseSec = baseline.planned.holdTime?.inSeconds ?? 30
                let factor  = reductionSteps[i]
                let target  = Int((Double(baseSec) * factor).rounded())

                details.append(SetDetail(
                    setNumber: idx,
                    weight: resistance.usesWeight ? baseline.weight : Mass(kg: 0),
                    planned: .hold(.fromSeconds(target))
                ))
            }
            */
            
            switch (baseline.load, baseline.planned) {
            case (.weight(let weight), .reps):
                let reps = repSteps[i]
                let baseKg = weight.inKg
                let targetKg = baseKg * reductionSteps[i]
                var warmW = Mass(kg: targetKg)
                warmW = equipmentData.roundWeight(warmW, for: equipmentRequired, rounding: rounding)
                details.append(SetDetail(
                    setNumber: idx,
                    load: .weight(warmW),
                    planned: .reps(reps)
                ))
                
            case (.none, .reps):
                let reps = repSteps[i]
                details.append(SetDetail(
                    setNumber: idx,
                    load: .none,
                    planned: .reps(reps)
                ))
                
            case (.none, .hold(let ts)):
                let baseSec = ts.inSeconds
                let factor = reductionSteps[i]
                let target = Int((Double(baseSec) * factor).rounded())
                details.append(SetDetail(
                    setNumber: idx,
                    load: .none,
                    planned: .hold(.fromSeconds(target))
                ))
                
                
            case (.distance(let distance), .hold(let ts)):
                // Handle distance-based loads if needed
                break
                
            default:
                break
            }
        }

        warmUpDetails = details
    }
}

extension Exercise {
    // MARK: – Public computed properties
    var musclesTextFormatted: Text { formattedMuscles(from: primaryMuscleEngagements + secondaryMuscleEngagements) }
    var primaryMusclesFormatted: Text { formattedMuscles(from: primaryMuscleEngagements) }
    var secondaryMusclesFormatted: Text { formattedMuscles(from: secondaryMuscleEngagements) }
    
    // MARK: – Shared formatter
    
    private func formattedMuscles(from engagements: [MuscleEngagement]) -> Text {
        // Build a bullet-point line for every engagement
        let lines: [Text] = engagements.map { e in
            let name = Text("• \(e.muscleWorked.rawValue): ").bold()

            let subs = e.allSubMuscles
                .map { $0.simpleName }
                .joined(separator: ", ")

            return subs.isEmpty ? name : name + Text(subs)
        }

        guard let first = lines.first else { return Text("• None") }
        return lines.dropFirst().reduce(first) { $0 + Text("\n") + $1 }
    }
}

/*
enum SetUnit: Codable {
    case weightReps
    case time
    case weightTime
    case reps
}
*/
