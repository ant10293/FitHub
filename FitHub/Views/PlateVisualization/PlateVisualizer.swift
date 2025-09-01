//
//  PlateVisualizer.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/23/25.
//

import SwiftUI


// MARK: - Main View
struct PlateVisualizer: View {
    @EnvironmentObject private var ctx: AppContext
    let weight: Mass
    let exercise: Exercise
    @State private var showBaseWeightEditor: Bool = false

    var body: some View {
        let (base, equip, baseCount, implementsCount, pegCount) = baseSpecForExercise()
        let spec = computePlateSpec(for: exercise, input: weight, base: base, baseCount: baseCount, implementsCount: implementsCount, pegCount: pegCount)
        let plan = computePlan(
            perSideTarget: spec.perSideTarget,
            base: base,
            baseCount: baseCount,
            denominations: ctx.userData.evaluation.availablePlates.resolvedPlates,
            replicates: spec.replicates,
            pegCount: pegCount
        )

        VStack(spacing: 12) {
            // Total system weight
            (Text("Total: ") + spec.displayTotal.formattedText())
                .font(.largeTitle.bold())

            // Implement visualization
            if implementsCount > 1 {
                // Multiple implements (e.g., dumbbells)
                ForEach(0..<implementsCount, id: \.self) { index in
                    ImplementRow(
                        title: "Implement \(index + 1)",
                        base: base,
                        plan: plan,
                        pegCount: pegCount,
                        showMultiplier: false,
                        showBaseWeightEditor: {
                            showBaseWeightEditor = true
                        }
                    )
                }
            } else {
                // Single implement (e.g., barbell, machine)
                ImplementRow(
                    title: "",
                    base: base,
                    plan: plan,
                    pegCount: pegCount,
                    showMultiplier: baseCount > 1,
                    showBaseWeightEditor: {
                        showBaseWeightEditor = true
                    }
                )
            }

            // Closest match info
            if !plan.exact {
                (Text("Closest: ") + plan.achievedTotal.formattedText())
                (Text("Δ ") + plan.delta.abs.formattedText())
                    .foregroundStyle(.orange)
                    .font(.footnote)
            }
        }
        .padding()
        .overlay(alignment: .center) {
            if showBaseWeightEditor, let equipment = equip {
                BaseWeightEditor(
                    exercise: exercise,
                    gymEquip: equipment,
                    onSave: { newValue in
                        var base = BaseWeight(lb: 0, kg: 0)
                        base.setWeight(newValue)
                        ctx.equipment.updateBaseWeight(equipment: equipment, new: base)
                        showBaseWeightEditor = false
                    },
                    onExit: {
                        showBaseWeightEditor = false
                    }
                )
            }
        }
    }

    // MARK: - Base mass + count + kind from equipment
    private func baseSpecForExercise() -> (base: Mass, equip: GymEquipment?, baseCount: Int, implementsCount: Int, pegCount: PegCountOption?) {
        let movement = exercise.limbMovementType ?? .bilateralDependent
        let gear = ctx.equipment.equipmentForExercise(exercise)

        var bestBase = Mass(kg: 0)
        var bestEquip: GymEquipment?
        var bestCount = 0
        var bestImplementsCount = 1
        var bestPegCount: PegCountOption? = nil

        for g in gear {
            guard let bw = g.baseWeight else { continue }
            let mass = bw.resolvedMass
            
            guard let implement = g.implementation else { continue }
            let movementCount = implement.movementCount(for: movement)
            
            let totalBaseWeight = mass.inKg * Double(movementCount.baseWeightMultiplier)
            
            if totalBaseWeight > bestBase.inKg {
                bestBase = mass
                bestEquip = g
                bestCount = movementCount.baseWeightMultiplier
                bestImplementsCount = movementCount.implementsUsed
                bestPegCount = g.pegCount
            }
        }
        return (bestBase, bestEquip, bestCount, bestImplementsCount, bestPegCount)
    }
    
    private func computePlateSpec(for exercise: Exercise, input: Mass, base: Mass, baseCount: Int, implementsCount: Int, pegCount: PegCountOption?) -> PlateSpec {
        let needsMultipleImplements = implementsCount > 1
        let replicates = needsMultipleImplements ? implementsCount : 1
        let totalTargetKg: Double = needsMultipleImplements ? (input.inKg * Double(implementsCount)) : input.inKg

        let totalPlatesNeededKg = max(0, totalTargetKg - (base.inKg * Double(baseCount)))

        let perSideTargetKg: Double
        if let pegCount = pegCount {
            switch pegCount {
            case .both:
                perSideTargetKg = totalPlatesNeededKg / Double(2 * replicates)
            case .single:
                perSideTargetKg = totalPlatesNeededKg / Double(replicates)
            case .none:
                perSideTargetKg = 0
            }
        } else {
            perSideTargetKg = totalPlatesNeededKg / Double(2 * replicates)
        }

        return PlateSpec(
            displayTotal: Mass(kg: totalTargetKg),
            perSideTarget: Mass(kg: perSideTargetKg),
            replicates: replicates
        )
    }

    private func computePlan(perSideTarget: Mass, base: Mass, baseCount: Int, denominations: [Mass], replicates: Int, pegCount: PegCountOption?) -> Plan {
        let sideTargetKg = perSideTarget.inKg
        let denoms = denominations
            .map { Mass(kg: $0.inKg) }
            .sorted { $0.inKg > $1.inKg }

        // Greedy fill for one side
        var remaining = sideTargetKg
        var sidePlates: [Mass] = []
        for d in denoms where d.inKg > 0 {
            let n = Int(floor((remaining + 1e-9) / d.inKg))
            if n > 0 {
                sidePlates.append(contentsOf: Array(repeating: d, count: n))
                remaining -= Double(n) * d.inKg
            }
        }

        let perSideAchievedKg = sidePlates.reduce(0) { $0 + $1.inKg }

        // Calculate system totals based on peg count
        let achievedTotalKg: Double
        let displayTotalKg: Double
        
        if let pegCount = pegCount {
            switch pegCount {
            case .both:
                achievedTotalKg = (2.0 * Double(replicates) * perSideAchievedKg) + (base.inKg * Double(baseCount))
                displayTotalKg = (2.0 * Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
            case .single:
                achievedTotalKg = (Double(replicates) * perSideAchievedKg) + (base.inKg * Double(baseCount))
                displayTotalKg = (Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
            case .none:
                achievedTotalKg = base.inKg * Double(baseCount)
                displayTotalKg = base.inKg * Double(baseCount)
            }
        } else {
            achievedTotalKg = (2.0 * Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
            displayTotalKg = (2.0 * Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
        }

        let exact = abs(achievedTotalKg - displayTotalKg) <= 1e-6

        return Plan(
            displayTotal: Mass(kg: displayTotalKg),
            base: base,
            perSideTarget: perSideTarget,
            perSideAchieved: Mass(kg: perSideAchievedKg),
            leftSide: sidePlates.reversed(),
            rightSide: sidePlates,
            exact: exact,
            achievedTotal: Mass(kg: achievedTotalKg),
            replicates: replicates,
            baseCount: baseCount
        )
    }
}


// MARK: - Planning Logic
struct PlateSpec {
    let displayTotal: Mass
    let perSideTarget: Mass
    let replicates: Int
}

struct Plan {
    let displayTotal: Mass
    let base: Mass
    let perSideTarget: Mass
    let perSideAchieved: Mass
    let leftSide: [Mass]
    let rightSide: [Mass]
    let exact: Bool
    let achievedTotal: Mass
    let replicates: Int
    let baseCount: Int
    var delta: Mass { Mass(kg: displayTotal.inKg - achievedTotal.inKg) }
}



