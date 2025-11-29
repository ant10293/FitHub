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
        let (base, input, equip, baseCount, implementsCount, pegCount) = baseSpecForExercise()
        let spec = computePlateSpec(
            for: exercise,
            input: input,
            base: base,
            baseCount: baseCount,
            implementsCount: implementsCount,
            pegCount: pegCount
        )
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
            (Text("Total: ") + spec.displayTotal.formattedText().bold())
                .font(.largeTitle)
            
            Text("Equipment: \(equip.name)")
            
            Spacer()

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
            
            Spacer()
        }
        .padding()
        .overlay(alignment: .center) {
            if showBaseWeightEditor {
                BaseWeightEditor(
                    exercise: exercise,
                    gymEquip: equip,
                    onSave: { newValue in
                        KeyboardManager.dismissKeyboard()
                        var mutableEquip = equip
                        mutableEquip.baseWeight?.setWeight(newValue)
                        ctx.equipment.updateEquipment(equipment: mutableEquip)
                        showBaseWeightEditor = false
                    },
                    onExit: {
                        KeyboardManager.dismissKeyboard()
                        showBaseWeightEditor = false
                    }
                )
            }
        }
    }

    // MARK: - Base mass + count + kind from equipment
    private func baseSpecForExercise() -> (base: Mass, input: Mass, equip: GymEquipment, baseCount: Int, implementsCount: Int, pegCount: PegCountOption?) {
        let movement = exercise.limbMovementType ?? .bilateralDependent
        let gear = ctx.equipment.equipmentForExercise(exercise, inclusion: .dynamic, available: ctx.userData.evaluation.availableEquipment)

        var bestBase = Mass(kg: -1)
        var bestEquip: GymEquipment = .defaultEquipment
        var bestCount = 0
        var bestImplementsCount = 1
        var bestWeight = weight
        var bestMovementPegMultiplier: Double = 1.0
        
        for g in gear {
            guard let bw = g.baseWeight else { continue }
            guard let impl = g.implementation else { continue }

            let mass = bw.resolvedMass
            var movementCount = impl.getMovementCount(for: movement)
            
            // Override implementsUsed and baseWeightMultiplier if implementCount is specified
            // and this equipment is .individual
            if let implementCount = exercise.implementCount, g.implementation == .individual {
                movementCount = MovementCount(
                    implementsUsed: implementCount,
                    baseWeightMultiplier: implementCount,
                    pegMultiplier: movementCount.pegMultiplier
                )
            }            
            
            let weightMultiplier = movementCount.baseWeightMultiplier
            let totalBaseWeight = mass.inKg * Double(weightMultiplier)
            let totalWeight: Mass = .init(kg: weight.inKg * Double(weightMultiplier))

            if totalBaseWeight > bestBase.inKg {
                bestBase = mass
                bestEquip = g
                bestCount = weightMultiplier
                bestImplementsCount = movementCount.implementsUsed
                bestWeight = totalWeight
                bestMovementPegMultiplier = movementCount.pegMultiplier.count
            }
        }

        // now compute peg count for the WHOLE gear set, not just bestEquip
        let effectivePegCount = resolvedPegCountForGear(gear, movementPegMultiplier: bestMovementPegMultiplier)

        return (bestBase, bestWeight, bestEquip, bestCount, bestImplementsCount, effectivePegCount)
    }

    /// Looks at the entire set of equipment used for this exercise and
    /// resolves landmine-style `.uses` + “real pegs” combos.
    ///
    /// Rules:
    /// - if we have an item with `.uses` (-1) and another with positive pegs (e.g. barbell=2),
    ///   we combine: 2 + (-1) = 1
    /// - if we only have an item with pegs, use that
    /// - if multiple peg items exist, take the highest (then apply uses)
    /// - finally apply movement multiplier
    private func resolvedPegCountForGear(_ gear: [GymEquipment], movementPegMultiplier: Double) -> PegCountOption {
        // all gear peg counts as plain ints
        let pegCounts: [(name: String, count: Int)] = gear.map { ($0.name, $0.pegCount?.count ?? 0) }
        // detect if anything "uses" a peg (landmine)
        let hasUses = pegCounts.contains(where: { $0.count == PegCountOption.uses.count })
        // find the strongest host (max positive pegs)
        let host = pegCounts
            .filter { $0.count > 0 }
            .max(by: { $0.count < $1.count })

        var combined = 0
        if let host {
            combined = host.count
            if hasUses {
                combined += PegCountOption.uses.count   // add -1 → 2 + (-1) = 1
            }
        } else {
            // no host with pegs
            combined = hasUses ? 0 : 0
        }

        let final = Int(Double(combined) * movementPegMultiplier)
        return PegCountOption.getOption(for: final)
    }
    
    private func computePlateSpec(for exercise: Exercise, input: Mass, base: Mass, baseCount: Int, implementsCount: Int, pegCount: PegCountOption?) -> PlateSpec {
        let needsMultipleImplements = implementsCount > 1
        let replicates = needsMultipleImplements ? implementsCount : 1
        let totalTargetKg: Double = input.inKg
        let totalPlatesNeededKg = max(0, totalTargetKg - (base.inKg * Double(baseCount)))
   
        let perSideTargetKg: Double
        if let pegCount = pegCount {
            switch pegCount {
            case .both:
                perSideTargetKg = totalPlatesNeededKg / Double(2 * replicates)
            case .single:
                perSideTargetKg = totalPlatesNeededKg / Double(replicates)
            case .uses, .none:
                perSideTargetKg = 0
            }
        } else {
            perSideTargetKg = totalPlatesNeededKg / Double(2 * replicates)
        }
        
        let spec = PlateSpec(
            displayTotal: Mass(kg: totalTargetKg),
            perSideTarget: Mass(kg: perSideTargetKg),
            replicates: replicates
        )

        return spec
    }
        
    private func computePlan(perSideTarget: Mass, base: Mass, baseCount: Int, denominations: [Mass], replicates: Int, pegCount: PegCountOption?) -> Plan {
        let sideTargetKg = perSideTarget.inKg
        let denoms = WeightPlates.sortedPlates(denominations, ascending: false)

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
            case .uses, .none:
                achievedTotalKg = base.inKg * Double(baseCount)
                displayTotalKg = base.inKg * Double(baseCount)
            }
        } else {
            achievedTotalKg = (2.0 * Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
            displayTotalKg = (2.0 * Double(replicates) * perSideTarget.inKg) + (base.inKg * Double(baseCount))
        }

        let exact = abs(achievedTotalKg - displayTotalKg) <= 1e-6
        let plan = Plan(
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

        return plan
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
