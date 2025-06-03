//
//  EquipmentData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation


class EquipmentData: ObservableObject {
     var allEquipment: [GymEquipment] = []
    
    func selectEquipment(basedOn option: String) {
        for index in allEquipment.indices {
            allEquipment[index].isSelected = false
        }
        
        switch option {
        case "All (Gym Membership)":
            for index in allEquipment.indices {
                allEquipment[index].isSelected = true
            }
        case "Some (Home Gym)":
            let homeGymEquipment: [EquipmentName] = [.barbell, .dumbbells, .pullUpBar, .squatRack, .flatBench, .inclineBenchRack, .dipBar, .ezBar]
            for index in allEquipment.indices {
                if homeGymEquipment.contains(allEquipment[index].name) {
                    allEquipment[index].isSelected = true
                }
            }
        case "None (Bodyweight Only)":
            let bodyWeightEquipment: [EquipmentName] = [.pullUpBar, .dipBar] // trx, rings, etc
            for index in allEquipment.indices {
                if bodyWeightEquipment.contains(allEquipment[index].name) {
                    allEquipment[index].isSelected = true
                }
            }
        default:
            break
        }
    }
    
    init() {
        allEquipment = [
            // MARK: - Small Weights
            GymEquipment(name: .dumbbells, image: "dumbbells", isSelected: false, equCategory: .smallWeights, description: "A pair of free weights used for a wide variety of exercises. They allow for unilateral movements and provide a full range of motion for strength training, toning, and functional fitness."),
            GymEquipment(name: .kettlebells, image: "kettlebells", isSelected: false, equCategory: .smallWeights, description: "A versatile weight with a unique handle, ideal for dynamic exercises like swings, snatches, and Turkish get-ups. They challenge strength, endurance, and coordination."),
            GymEquipment(name: .medicineBall, image: "medicine_ball", isSelected: false, equCategory: .smallWeights, description: "A weighted ball used in explosive training, core stabilization exercises, and partner workouts. Common in functional training and rehabilitation."),
            
            // MARK: - Bars & Plates
            GymEquipment(name: .barbell, image: "barbells", isSelected: false, equCategory: .barsPlates, baseWeight: 45, description: "A long, sturdy bar designed to hold weight plates. Essential for compound movements like squats, deadlifts, and bench presses. Often used in powerlifting and Olympic lifting."),
            GymEquipment(name: .safetySquatBar, image: "safety_squat_bar", isSelected: false, equCategory: .barsPlates, baseWeight: 65, description: "A specialty bar with padded shoulder rests that reduces shoulder strain. Ideal for squats and variations, it shifts the weight slightly forward to improve posture."),
            GymEquipment(name: .ezBar, image: "ez_bar", isSelected: false, equCategory: .barsPlates, baseWeight: 20, description: "A shorter, zig-zag-shaped bar designed to reduce wrist strain during bicep curls, tricep extensions, and other arm-focused exercises."),
            GymEquipment(name: .landmine, image: "landmine", isSelected: false, equCategory: .barsPlates, baseWeight: 45, description: "A pivoting attachment for a barbell, enabling rotational and pressing movements. Commonly used for core and upper body training."),
            GymEquipment(name: .farmersWalkHandles, image: "farmers_walk_handles", isSelected: false, equCategory: .barsPlates, baseWeight: 35, description: "Handles used for loaded carries, emphasizing grip strength, core stabilization, and overall endurance."),
            GymEquipment(name: .trapBar, image: "trap_bar", isSelected: false, equCategory: .barsPlates, baseWeight: 45, description: "A hexagonal bar that allows the user to stand inside. Great for deadlifts and shrugs, reducing strain on the lower back."),

            // MARK: - Benches & Racks
            GymEquipment(name: .pullUpBar, image: "pull_up_bar", isSelected: false, equCategory: .benchesRacks, description: "A horizontal bar for pull-ups, chin-ups, and hanging exercises. Builds upper body strength and improves grip."),
            GymEquipment(name: .squatRack, image: "squat_rack", isSelected: false, equCategory: .benchesRacks, adjustments: [.rackHeight], description: "A sturdy frame for safely supporting barbells during squats, presses, and other heavy lifts. Adjustable to accommodate various exercises."),
            GymEquipment(name: .flatBench, alternativeEquipment: [.adjustableBench], image: "flat_bench", isSelected: false, equCategory: .benchesRacks, description: "A fixed, flat bench used for exercises like bench presses, dumbbell presses, and step-ups. A staple for chest and strength training."),
            GymEquipment(name: .adjustableBench, image: "adjustable_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.benchAngle], description: "A bench with adjustable angles for incline, decline, and flat positions. Increases versatility for pressing and core exercises."),
            GymEquipment(name: .flatBenchRack, alternativeEquipment: [.flatBench, .squatRack], image: "flat_bench_rack", isSelected: false, equCategory: .benchesRacks, description: "A bench combined with a barbell rack, designed for chest presses and other upper body lifts."),
            GymEquipment(name: .inclineBenchRack, alternativeEquipment: [.adjustableBench, .squatRack], image: "incline_bench", isSelected: false, equCategory: .benchesRacks, description: "A bench set at an incline, often with a rack for barbell exercises targeting the upper chest."),
            GymEquipment(name: .declineBenchRack, image: "decline_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.benchAngle, .footPlateHeight], description: "A bench angled downward, often with foot supports, for targeting the lower chest and core during presses and sit-ups."),
            GymEquipment(name: .verticalBench, alternativeEquipment: [.adjustableBench], image: "vertical_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.seatHeight], description: "A bench used for seated pressing movements, particularly shoulder exercises. Often includes adjustable back support."),
            GymEquipment(name: .reverseHyperextensionBench, image: "reverse_hyper_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.handlePosition], description: "A specialized bench for strengthening the lower back, glutes, and hamstrings. Common in rehabilitation and powerlifting."),
            GymEquipment(name: .preacherCurlBench, image: "preacher_curl_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.seatHeight], description: "A padded bench designed to isolate the biceps during curl exercises, reducing the involvement of other muscles."),
            GymEquipment(name: .backExtensionBench, image: "back_extension_bench", isSelected: false, equCategory: .benchesRacks, description: "A bench for hyperextensions and strengthening the lower back, glutes, and hamstrings."),
            GymEquipment(name: .gluteHamRaiseBench, image: "glute_ham_raise_bench", isSelected: false, equCategory: .benchesRacks, adjustments: [.footPlateHeight], description: "A bench that targets the glutes, hamstrings, and lower back. Often used in athletic training and rehabilitation."),
            GymEquipment(name: .dipBar, image: "dip_bar", isSelected: false, equCategory: .benchesRacks, description: "Parallel bars used for dips, which strengthen the chest, triceps, and shoulders."),
            
            // MARK: - Cable Machines
            GymEquipment(name: .cableCrossover, image: "crossover_cable", isSelected: false, equCategory: .cableMachines, adjustments: [.pulleyHeight, .handlePosition], description: "A machine with adjustable pulleys for performing chest flys, crossovers, and functional movements. Highly versatile for various angles."),
            GymEquipment(name: .cableLatPulldown, image: "lat_pulldown_cable", isSelected: false, equCategory: .cableMachines, adjustments: [.pulleyHeight, .handlePosition], description: "A cable machine with a bar attachment for pulling movements, focusing on the lats and upper back."),
            GymEquipment(name: .hiLoPulleyCable, image: "hi_lo_pulley_cable", isSelected: false, equCategory: .cableMachines, adjustments: [.pulleyHeight, .handlePosition], description: "A machine with adjustable pulleys for upper and lower body exercises. Ideal for targeting multiple muscle groups."),
            GymEquipment(name: .cableRow, image: "row_cable", isSelected: false, equCategory: .cableMachines, adjustments: [.pulleyHeight, .handlePosition], description: "A seated cable machine for back-focused pulling exercises, improving posture and strength."),
            
            // MARK: - Resistance Bands
            GymEquipment(name: .handleBands, image: "handle_bands", isSelected: false, equCategory: .resistanceBands, description: "Resistance bands with handles for strength, mobility, and rehabilitation exercises. Portable and easy to use."),
            GymEquipment(name: .miniLoopBands, image: "mini_loop_bands", isSelected: false, equCategory: .resistanceBands, description: "Small looped bands used for hip, glute, and core activation. Often used in warm-ups or physical therapy."),
            GymEquipment(name: .loopBands, image: "loop_bands", isSelected: false, equCategory: .resistanceBands, description: "Large looped bands for pull-up assistance, resistance training, and stretching. A versatile alternative to weights."),
            
            // MARK: - Plated Machines
            GymEquipment(name: .legPress, image: "leg_press", isSelected: false, equCategory: .platedMachines, adjustments: [.seatHeight, .footPlateHeight], baseWeight: 100, description: "A machine for heavy leg exercises, targeting the quads, hamstrings, and glutes. Provides support for the back."),
            GymEquipment(name: .smithMachine, image: "smith_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.rackHeight], baseWeight: 25, description: "A guided barbell system with vertical rails, allowing for controlled squats, presses, and other movements."),
            GymEquipment(name: .tBarRow, image: "t_bar", isSelected: false, equCategory: .platedMachines, adjustments: [.padHeight], baseWeight: 45, description: "A plate-loaded row machine targeting the back and rear deltoids. Often used for strength and hypertrophy training."),
            GymEquipment(name: .beltSquat, image: "belt_squat_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.sundialAdjustment], baseWeight: 60, description: "A machine for squats that unloads the spine, ideal for building leg strength without lower back strain."),
            GymEquipment(name: .hackSquat, image: "hack_squat_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.footPlateHeight, .padHeight], baseWeight: 75, description: "A machine for squat movements with back support, targeting the quads and glutes in a controlled range of motion."),
            GymEquipment(name: .shoulderShrug, image: "shoulder_shrug_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.padHeight], baseWeight: 25, description: "A machine for isolating the trapezius muscles during shrugs, enhancing upper back development."),
            GymEquipment(name: .seatedCalfRaise, image: "calf_raise_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.seatHeight, .padHeight], baseWeight: 60, description: "A machine for isolating the calf muscles during seated exercises. Allows for progressive overload."),
            GymEquipment(name: .standingCalfRaise, image: "standing_calf_raise_plate_loaded", isSelected: false, equCategory: .platedMachines, adjustments: [.padHeight], description: "A plate-loaded machine for standing calf exercises."),
            GymEquipment(name: .vikingPress, image: "viking_press_machine", isSelected: false, equCategory: .platedMachines, adjustments: [.handlePosition], description: "A machine for overhead pressing with handles, focusing on shoulder and tricep strength."),
            
            // MARK: - Weight Machines
            GymEquipment(name: .shoulderPressMachine, image: "shoulder_press_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for seated overhead presses, targeting the shoulders."),
            GymEquipment(name: .lyingLegCurlMachine, image: "leg_curl_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight], description: "A machine for isolating the hamstrings."),
            GymEquipment(name: .standingCalfRaiseMachine, image: "standing_calf_raise_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight], description: "A machine for standing calf exercises."),
            GymEquipment(name: .seatedLegCurlMachine, image: "seated_leg_curl_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .padHeight], description: "A machine for isolating the hamstrings while seated."),
            GymEquipment(name: .seatedRowMachine, image: "seated_row_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for back and bicep exercises with adjustable handles."),
            GymEquipment(name: .backExtensionBench, image: "back_extension_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight], description: "A machine for lower back strengthening."),
            GymEquipment(name: .abCrunchMachine, image: "ab_crunch_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight, .backPadDepth], description: "A machine for isolating the abdominal muscles during crunches."),
            GymEquipment(name: .preacherCurlMachine, image: "preacher_curl_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight], description: "A machine for isolating the biceps with adjustable pads."),
            GymEquipment(name: .bicepCurlMachine, image: "bicep_curl_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.handlePosition], description: "A machine for controlled bicep curls."),
            GymEquipment(name: .chestPressMachine, image: "bench_press_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for chest pressing exercises, targeting the pectorals."),
            GymEquipment(name: .flyMachine, image: "fly_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for chest flys and reverse flys."),
            GymEquipment(name: .hipAbductorMachine, image: "thigh_abductor_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .padHeight], description: "A machine for strengthening the outer thighs and hips."),
            GymEquipment(name: .hipAdductorMachine, image: "thigh_adductor_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .padHeight], description: "A machine for targeting the inner thighs."),
            GymEquipment(name: .legExtensionMachine, image: "leg_extension_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .padHeight], description: "A machine for isolating the quadriceps."),
            GymEquipment(name: .lateralRaiseMachine, image: "lateral_raise_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for isolating the shoulders during lateral raises."),
            GymEquipment(name: .tricepDipMachine, image: "tricep_dip_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for tricep dips with controlled motion."),
            GymEquipment(name: .tricepExtensionMachine, image: "tricep_extension_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A machine for isolating the triceps during extensions."),
            GymEquipment(name: .assistedWeightMachine, image: "assisted_weight_machine", isSelected: false, equCategory: .weightMachines, description: "A multi-purpose machine for assisted pull-ups or dips."),
            GymEquipment(name: .squatMachine, image: "squat_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .padHeight], description: "A machine for guided squats, reducing back strain."),
            GymEquipment(name: .gluteKickbackMachine, image: "glute_kickback_machine", isSelected: false, equCategory: .weightMachines, adjustments: [.padHeight], description: "A machine for isolating the glutes during kickbacks."),
            GymEquipment(name: .freemotionMachine, image: "freemotion", isSelected: false, equCategory: .weightMachines, adjustments: [.seatHeight, .handlePosition], description: "A versatile machine for dynamic, functional training."),
            
            // MARK: - Other
            GymEquipment(name: .abWheel, image: "ab_wheel", isSelected: false, equCategory: .other, description: "A wheel for rolling exercises, targeting the core and stabilizers."),
            GymEquipment(name: .plyometricBox, image: "plyo_box", isSelected: false, equCategory: .other, description: "A sturdy box for plyometric training and box jumps.")
            
            /*GymEquipment(name: "TRX", image: "trx", isSelected: false, equCategory: .other),
             GymEquipment(name: "Battle Ropes", image: "battle_ropes", isSelected: false, equCategory: .other),
             GymEquipment(name: "Rings", image: "rings", isSelected: false, equCategory: .other),
             GymEquipment(name: "Rope", image: "rope", isSelected: false, equCategory: .other)
             GymEquipment(name: "Ab Wheel", image: "ab_wheel", isSelected: false, equCategory: .other)*/
        ]
        
    }
    // Method to get the category for a given equipment name
    func category(for equipment: EquipmentName) -> EquipmentCategory? {
        return allEquipment.first(where: { $0.name == equipment })?.equCategory
    }
    
    // Function to get equipment for specified categories
    func equipmentForCategories(_ categories: [EquipmentCategory]) -> [GymEquipment] {
        return allEquipment.filter { categories.contains($0.equCategory) }
    }
    
    func hasEquipmentAdjustments(for exercise: Exercise) -> Bool {
        for equipmentName in exercise.equipmentRequired {
            if let gymEquipment = allEquipment.first(where: { $0.name == equipmentName }) {
                if gymEquipment.adjustments != nil && !gymEquipment.adjustments!.isEmpty {
                    return true
                }
            }
        }
        return false
    }
    
    func roundWeight(_ weight: Double, for equipment: [EquipmentName], roundingPreference: [EquipmentCategory: Double]) -> Double {
        print("rounding weight: \(weight)")
        // Determine the rounding increment based on the user's preference
        let roundIncrement: Double = equipment.contains { equipmentName in
            allEquipment.contains { $0.name == equipmentName && ($0.equCategory == .weightMachines || $0.equCategory == .cableMachines) }
        } ? roundingPreference[.weightMachines] ?? 2.5
        : equipment.contains { equipmentName in
            allEquipment.contains { $0.name == equipmentName && $0.equCategory == .smallWeights }
        } ? roundingPreference[.smallWeights] ?? 5
        : roundingPreference[.platedMachines] ?? 5
        
        let roundedWeight = round(weight / roundIncrement) * roundIncrement
        print("Rounded Weight: \(roundedWeight)")
        return roundedWeight
    }
}

