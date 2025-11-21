//
//  Goal.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import Foundation


enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle = "Build Muscle"
    case loseWeight = "Lose Weight"
    case getStronger = "Get Stronger"
    case buildMuscleGetStronger = "Build Muscle & Get Stronger"
    case improveEndurance = "Improve Endurance"
    case generalFitness = "General Fitness"
    case athleticPerformance = "Athletic Performance"

    var shortDescription: String {
        switch self {
        case .buildMuscle: return "Hypertrophy focused"
        case .loseWeight: return "Weight loss focused"
        case .getStronger: return "Strength focused"
        case .buildMuscleGetStronger: return "Hybrid focus"
        case .improveEndurance: return "Cardio & stamina focused"
        case .generalFitness: return "Balanced health and mobility"
        case .athleticPerformance: return "Sport-specific training"
        }
    }
    
    var detailDescription: String {
        let rAndS = defaultRepsAndSets
        return String("Reps: \(Format.formatRange(range: rAndS.repRange)), Sets: \(Format.formatRange(range: rAndS.setRange)), Rest: \(Format.formatRange(range: rAndS.restRange))s")
    }
    
    static let primaryGoals: [FitnessGoal] = [.buildMuscle, .loseWeight, .getStronger]
}
extension FitnessGoal {
    var defaultRepsAndSets: RepsAndSets {
        RepsAndSets(reps: defaultReps, sets: defaultSets, rest: defaultRest, distribution: defaultDistribution)
    }
    
    var defaultRest: RestPeriods {
        switch self {
        case .buildMuscle:
            return RestPeriods(distribution: [.warmup: 60, .working: 90, .superset: 60])
        case .loseWeight:
            return RestPeriods(distribution: [.warmup: 45, .working: 60,  .superset: 45])
        case .getStronger:
            return RestPeriods(distribution: [.warmup: 90, .working: 180, .superset: 90])
        case .buildMuscleGetStronger:
            return RestPeriods(distribution: [.warmup: 60, .working: 120, .superset: 60])
        case .improveEndurance:
            return RestPeriods(distribution: [.warmup: 30, .working: 45,  .superset: 30])
        case .generalFitness:
            return RestPeriods(distribution: [.warmup: 45, .working: 75,  .superset: 45])
        case .athleticPerformance:
            return RestPeriods(distribution: [.warmup: 60, .working: 120, .superset: 60])
        }
    }
    
    var defaultSets: SetDistribution {
        switch self {
        case .buildMuscle:
            return SetDistribution(distribution: [
                .compound   : 4,  // main lifts get volume
                .isolation  : 3,  // hypertrophy accessories
                .plyometric : 1,  // not typical for hypertrophy
                .isometric  : 1   // bracing/holds
            ])
        case .loseWeight:
            return SetDistribution(distribution: [
                .compound   : 3,  // density-focused
                .isolation  : 2,
                .plyometric : 3,  // conditioning/power intervals
                .isometric  : 1
            ])
        case .getStronger:
            return SetDistribution(distribution: [
                .compound   : 5,  // strength = more sets per main lift
                .isolation  : 2,  // minimal accessories
                .plyometric : 1,  // light jump primers
                .isometric  : 1   // core/bracing
            ])
        case .buildMuscleGetStronger:
            return SetDistribution(distribution: [
                .compound   : 4,  // balanced
                .isolation  : 3,
                .plyometric : 1,  // optional primers
                .isometric  : 1
            ])
        case .improveEndurance:
            return SetDistribution(distribution: [
                .compound   : 3,  // lighter compounds
                .isolation  : 2,
                .plyometric : 4,  // more cadence/plyo work
                .isometric  : 1
            ])
        case .generalFitness:
            return SetDistribution(distribution: [
                .compound   : 3,
                .isolation  : 2,
                .plyometric : 2,
                .isometric  : 2
            ])
        case .athleticPerformance:
            return SetDistribution(distribution: [
                .compound   : 4,  // power + strength
                .isolation  : 2,
                .plyometric : 4,  // jumps/throws emphasis
                .isometric  : 1
            ])
        }
    }
    
    var defaultReps: RepDistribution {
        switch self {
        case .buildMuscle:
            return RepDistribution(distribution: [
                .compound: 6...10,
                .isolation: 8...12,
                .plyometric: 5...8
            ])
        case .loseWeight:
            return RepDistribution(distribution: [
                .compound: 10...15,
                .isolation: 12...20,
                .plyometric: 6...10
            ])
        case .getStronger:
            return RepDistribution(distribution: [
                .compound: 3...6,
                .isolation: 6...10,
                .plyometric: 3...6
            ])
        case .buildMuscleGetStronger:
            return RepDistribution(distribution: [
                .compound: 5...8,
                .isolation: 8...12,
                .plyometric: 4...7
            ])
        case .improveEndurance:
            return RepDistribution(distribution: [
                .compound: 12...20,
                .isolation: 15...25,
                .plyometric: 6...10
            ])
        case .generalFitness:
            return RepDistribution(distribution: [
                .compound: 6...12,
                .isolation: 8...15,
                .plyometric: 5...8
            ])
        case .athleticPerformance:
            return RepDistribution(distribution: [
                .compound: 3...6,
                .isolation: 6...12,
                .plyometric: 3...8
            ])
        }
    }
    
    var defaultDistribution: EffortDistribution {
        switch self {
        case .buildMuscle:
            return EffortDistribution(distribution: [
                .compound   : 0.6,   // big multi-joint lifts drive mechanical tension
                .isolation  : 0.4   // finishers for metabolic stress
            ])
        case .loseWeight: // Slightly more metabolic conditioning via plyometrics
            return EffortDistribution(distribution: [
                .compound   : 0.55,
                .isolation  : 0.30,
                .plyometric : 0.15
            ])
        case .getStronger:
            return EffortDistribution(distribution: [
                .compound   : 0.75,   // strength built around heavy compounds
                .isolation  : 0.25   // accessory work / weak-point training
            ])
        case .buildMuscleGetStronger:
            return EffortDistribution(distribution: [
                .compound   : 0.5,
                .isolation  : 0.5
            ])
        case .improveEndurance:
            return EffortDistribution(distribution: [
                .compound   : 0.50,
                .isolation  : 0.20,
                .plyometric : 0.20,
                .isometric  : 0.10
            ])
        case .generalFitness:
            return EffortDistribution(distribution: [
                .compound   : 0.55,
                .isolation  : 0.25,
                .plyometric : 0.10,
                .isometric  : 0.10
            ])
        case .athleticPerformance:
            return EffortDistribution(distribution: [
                .compound   : 0.40,
                .plyometric : 0.35,
                .isolation  : 0.20, // for injury reduction
                .isometric  : 0.05
            ])
        }
    }
    
    private var maintenanceMultiplier: ClosedRange<Double> {
        switch self {
        case .buildMuscle:            return 1.05...1.10   // modest surplus
        case .loseWeight:             return 0.80...0.90   // 10–20% deficit
        case .getStronger:            return 1.00...1.05   // maintenance → slight surplus
        case .buildMuscleGetStronger: return 1.02...1.07   // small surplus
        case .improveEndurance:       return 0.95...1.05   // depends on volume; near maintenance
        case .generalFitness:         return 0.95...1.05   // near maintenance
        case .athleticPerformance:    return 1.05...1.15   // surplus to support performance
        }
    }

    /// Handy midpoint if you just want a single number.
    var maintenanceMultiplierDefault: Double {
        let r = maintenanceMultiplier
        return (r.lowerBound + r.upperBound) / 2.0
    }
}
