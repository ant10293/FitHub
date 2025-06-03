//
//  ExerciseData.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation


class ExerciseData: ObservableObject {
     var allExercises: [Exercise] = []
     var allExercisePerformance: [String: ExercisePerformance] = [:]
    
    init() {
        loadPerformanceData(from: "performance.json");
        allExercises = [
            // Sub-muscles’ percentages sum to ~100% of that muscle group’s portion. For instance, if deltoids are 70% overall, frontDelt and sideDelt can be split within that 70%.

            // MARK: -------------------------------------------------------------------------------------------------- Chest ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Bench Press", aliases: ["Barbell Bench Press", "Flat Bench Press"], image: "bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100),
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 10)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Targets the chest with secondary emphasis on the triceps and front deltoids.", equipmentRequired: [.flatBenchRack, .barbell], exDistinction: .compound, url: "bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Decline Bench Press", aliases: ["Decline Barbell Press", "Decline Chest Press"], image: "decline_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 65, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .costalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Targets the lower chest and triceps more intensely due to the decline angle.", equipmentRequired: [.declineBenchRack, .barbell], exDistinction: .compound, url: "decline-bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Chest Fly", aliases: ["Dumbbell Flyes", "Dumbbell Pec Fly"], image: "dumbbell_chest_fly", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Isolates the chest muscles by moving dumbbells in an arc, focusing on chest width.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .isolation, url: "dumbbell-fly", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Dumbbell Bench Press", aliases: ["Dumbbell Chest Press"], image: "dumbbell_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60), SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Works the chest, triceps, and deltoids, offering a greater range of motion than the barbell.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .compound, url: "dumbbell-bench-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Dumbbell Decline Bench Press", aliases: ["Decline Dumbbell Press"], image: "dumbbell_decline_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 65, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .costalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Focuses on the lower part of the chest and triceps, performed on a decline bench.", equipmentRequired: [.dumbbells, .declineBenchRack], exDistinction: .compound, url: "decline-dumbbell-bench-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Dumbbell Floor Press", aliases: ["Floor Dumbbell Press"], image: "dumbbell_floor_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)])
            ], exDesc: "Limits shoulder strain and increases triceps activation by stopping at floor level.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-floor-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Dumbbell Pullover", aliases: ["Dumbbell Chest Pullover", "Dumbbell Lats Pullover"], image: "dumbbell_pullover", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .serratusAnterior, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperLats, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lowerLats, engagementPercentage: 50)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 10, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)])
            ], exDesc: "Works the chest and back, particularly targeting the serratus anterior and lats.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .compound, url: "dumbbell-pullover", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Floor Press", aliases: ["Barbell Floor Press"], image: "floor_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)])
            ], exDesc: "Emphasizes the lockout phase of the bench press, reducing shoulder engagement.", equipmentRequired: [.barbell], exDistinction: .compound, url: "floor-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Incline Bench Press", aliases: ["Incline Barbell Press", "Incline Chest Press"], image: "incline_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Targets the upper chest, shoulders, and triceps, performed on an incline bench.", equipmentRequired: [.barbell, .inclineBenchRack], exDistinction: .compound, url: "incline-bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Incline Dumbbell Bench Press", aliases: ["Incline Dumbbell Press"], image: "incline_dumbbell_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Focuses on the upper chest with a greater range of motion, also engaging shoulders and triceps.", equipmentRequired: [.dumbbells, .inclineBenchRack], exDistinction: .compound, url: "incline-dumbbell-bench-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Incline Push-Up", aliases: ["Elevated Push-Up", "Incline Chest Push-Up"], image: "incline_push_up", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Elevates the hands to target the upper chest and reduce lower back strain.", equipmentRequired: [], exDistinction: .compound, url: "incline-push-up", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Machine Chest Fly", aliases: ["Pec Deck", "Butterfly Machine"], image: "machine_chest_fly", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)])
            ], exDesc: "Isolates chest muscles with controlled movement on a machine.", equipmentRequired: [.flyMachine], exDistinction: .isolation, url: "machine-chest-fly", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Machine Chest Press", aliases: ["Seated Chest Press", "Chest Press Machine"], image: "chest_press_machine", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Simulates the bench press movement in a controlled machine setup, focusing on the chest.", equipmentRequired: [.chestPressMachine], exDistinction: .compound, url: "chest-press", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Push-Up", aliases: ["Standard Push-Up", "Chest Push-Up"], image: "push_up", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "A fundamental bodyweight exercise targeting the chest, triceps, and shoulders.", equipmentRequired: [], exDistinction: .compound, url: "push-ups", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Smith Machine Bench Press", aliases: ["Smith Machine Chest Press"], image: "smith_machine_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Provides a guided path for the bench press, focusing on the chest with less stability demand.", equipmentRequired: [.smithMachine], exDistinction: .compound, url: "smith-machine-bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Cable Chest Fly", aliases: ["Cable Pec Fly", "Cable Crossover Fly"], image: "cable_chest_fly", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)])
            ], exDesc: "Targets the middle chest with constant tension from cable machines, perfect for isolating and sculpting the pectorals.", equipmentRequired: [.cableCrossover], exDistinction: .isolation, url: "cable-fly", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per stack"),
            
            Exercise(name: "Paused Bench Press", aliases: ["Pause Press", "Isometric Bench Press"], image: "paused_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Enhances chest muscle activation by incorporating a pause at the bottom of the lift.", equipmentRequired: [.flatBench, .barbell], exDistinction: .compound, url: "paused-bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Reverse Grip Bench Press", aliases: ["Underhand Bench Press", "Reverse Chest Press"], image: "reverse_grip_bench_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 10, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Switches the traditional grip to target the upper chest and shoulders more intensely, while still engaging triceps and front deltoids.", equipmentRequired: [.flatBench, .barbell], exDistinction: .compound, url: "reverse-grip-bench-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Bench Pin Press", aliases: ["Pin Press", "Rack Bench Press"], image: "bench_pin_press", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 35, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Focuses on the top half of the bench press motion, enhancing lockout strength.", equipmentRequired: [.flatBench, .barbell], exDistinction: .compound, url: "bench-pin-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Decline Push-Up", aliases: ["Feet Elevated Push-Up"], image: "decline_push_up", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .clavicularHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "An intense bodyweight variant that increases upper chest and shoulder involvement.", equipmentRequired: [], exDistinction: .compound, url: "decline-push-up", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Diamond Push-Up", aliases: ["Close-Hand Push-Up", "Triceps Push-Up"], image: "diamond_push_up", splitCategory: .chest, muscles: [
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 45, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 5, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)])
            ], exDesc: "Targets the inner chest and triceps more effectively by positioning the hands close together in a diamond shape.", equipmentRequired: [], exDistinction: .compound, url: "diamond-push-ups", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            
            // no data or needs review
            // Exercise(name: "Low to High Cable Chest Fly", image: "cable_chest_fly", primaryMuscle: .pectorals, primaryMuscles: [.clavicularHead], secondaryMuscles: [], exDesc: "Targets the upper chest by moving from a low position upward, enhancing upper chest development and definition.", equipmentRequired: [.cableCrossover], exDistinction: .isolation, url: "low-to-high-cable-chest-fly", usesWeight: true),
            // Exercise(name: "High to Low Cable Chest Fly", image: "cable_chest_fly", primaryMuscle: .pectorals, primaryMuscles: [.costalHead], secondaryMuscles: [], exDesc: "Focuses on the lower chest by moving from a high position downward, perfect for emphasizing the lower pectorals.", equipmentRequired: [.cableCrossover], exDistinction: .isolation, url: "high-to-low-cable-chest-fly", usesWeight: true),
            // Exercise(name: "Standing Resistance Band Chest Fly", image: "standing_resistance_band_chest_fly", primaryMuscle: .pectorals, primaryMuscles: [.pectorals], secondaryMuscles: [], exDesc: "Mimics the cable fly movement with resistance bands, allowing for flexibility in setup.", equipmentRequired: ["Resistance Bands"]),
            // Exercise(name: "Kneeling Incline Push-Up", image: "kneeling_incline_push_up", primaryMuscle: .pectorals, primaryMuscles: [.clavicularHead], secondaryMuscles: [.frontDelt], exDesc: "A modified push-up for targeting the upper chest with reduced difficulty.", equipmentRequired: []),
            // Exercise(name: "Kneeling Push-Up", image: "kneeling_push_up", primaryMuscle: .pectorals, primaryMuscles: [.pectorals], secondaryMuscles: [.triceps, .frontDelt], exDesc: "A beginner-friendly version of the push-up, reducing weight on the arms and chest.", equipmentRequired: []),
            // Exercise(name: "Close-Grip Feet-Up Bench Press", image: "close_grip_feet_up_bench_press", primaryMuscle: .pectorals, primaryMuscles: [.triceps], secondaryMuscles: [.pectorals], exDesc: "Emphasizes triceps and minimizes leg drive, with chest as a secondary target.", equipmentRequired: [.flatBench, .barbell]),
            // Exercise(name: "Feet-Up Bench Press", image: "feet_up_bench_press", primaryMuscle: .pectorals, primaryMuscles: [.pectorals], secondaryMuscles: [.triceps, .frontDelt], exDesc: "Increases core engagement by lifting feet, focusing on chest and arm muscles.", equipmentRequired: [.barbell, .flatBench]),
            //Exercise(name: "Smith Machine Incline Bench Press", image: "smith_machine_incline_bench_press", primaryMuscle: .pectorals, primaryMuscles: [.clavicularHead], secondaryMuscles: [.triceps, .frontDelt], exDesc: "Targets the upper chest with the stability of the Smith machine, reducing the need for balance.", equipmentRequired: [.smithMachine, .inclineBench], exDistinction: .compound, url: "smith-machine-incline-bench-press", usesWeight: true),
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Shoulders ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Arnold Press", aliases: ["Rotational Shoulder Press"], image: "arnold_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "A fundamental compound movement targeting the shoulders and triceps.", equipmentRequired: [.dumbbells, .verticalBench], exDistinction: .compound, url: "arnold-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Barbell Front Raise", aliases: ["Front Barbell Raise"], image: "barbell_front_raise", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates the anterior deltoids by lifting a barbell in front of you.", equipmentRequired: [.barbell], exDistinction: .isolation, url: "barbell-front-raise", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Barbell Upright Row", aliases: ["Barbell High Pull"], image: "barbell_upright_row", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the deltoids and trapezius by rowing a barbell upwards close to the body.", equipmentRequired: [.barbell], exDistinction: .compound, url: "upright-row", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Dumbbell Upright Row", aliases: ["Dumbbell High Pull"], image: "dumbbell_upright_row", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the deltoids and trapezius by rowing dumbbells upwards close to the body.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-upright-row", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Behind the Neck Press", aliases: ["Behind Head Shoulder Press"], image: "behind_the_neck_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 50)
                ])
            ], exDesc: "Engages the side and rear deltoids by pressing a barbell from behind the neck overhead.", equipmentRequired: [.barbell], exDistinction: .compound, url: "behind-the-neck-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Lateral Raise", aliases: ["Side Cable Raise"], image: "cable_lateral_raise", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates side deltoids with constant tension by raising arms to the side against cable resistance.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-lateral-raise", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "Dumbbell Front Raise", aliases: ["Dumbbell Anterior Raise"], image: "dumbbell_front_raise", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Strengthens the anterior deltoids by lifting dumbbells in front of you.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-front-raise", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Dumbbell Lateral Raise", aliases: ["Side Dumbbell Raise"], image: "dumbbell_lateral_raise", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the lateral part of the deltoid muscle by raising dumbbells to the side.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-lateral-raise", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Dumbbell Shoulder Press", aliases: ["Overhead Dumbbell Press"], image: "dumbbell_shoulder_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Works the entire deltoid region and triceps by pressing dumbbells overhead.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-shoulder-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Face Pull", aliases: ["Rope Face Pull"], image: "face_pull", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 50)
                ])
            ], exDesc: "Improves posture and shoulder health by pulling a rope towards the face with a cable machine.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .compound, url: "face-pull", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Machine Lateral Raise", aliases: ["Side Raise Machine"], image: "machine_lateral_raise", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates the side deltoids using a specific machine designed for lateral raises.", equipmentRequired: [.lateralRaiseMachine], exDistinction: .isolation, url: "machine-lateral-raise", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Machine Shoulder Press", aliases: ["Seated Machine Press"], image: "machine_shoulder_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the deltoids and triceps in a seated position with controlled motion.", equipmentRequired: [.shoulderPressMachine], exDistinction: .compound, url: "machine-shoulder-press", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Shoulder Press", aliases: ["Overhead Press"], image: "overhead_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "A fundamental compound movement involving pressing a barbell overhead targeting the shoulders and triceps.", equipmentRequired: [.barbell], exDistinction: .compound, url: "shoulder-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Push Press", aliases: ["Overhead Push Press"], image: "push_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Combines a moderate dip and leg drive to press overhead, working shoulders and triceps.", equipmentRequired: [.barbell], exDistinction: .compound, url: "push-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Reverse Fly", aliases: ["Reverse Cable Crossover"], image: "reverse_cable_flyes", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the rear deltoids and upper back by pulling cables outward in a reverse fly motion.", equipmentRequired: [.cableCrossover], exDistinction: .compound, url: "cable-reverse-fly", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per stack"),

            Exercise(name: "Reverse Dumbbell Fly", aliases: ["Bent-Over Dumbbell Reverse Fly"], image: "reverse_dumbbell_flyes", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ])
            ], exDesc: "Strengthens the rear shoulders and upper back by performing a reverse fly motion with dumbbells.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-reverse-fly", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Machine Reverse Fly", aliases: ["Rear Delt Machine Fly"], image: "reverse_machine_fly", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ])
            ], exDesc: "Isolates the rear deltoids using a machine designed for reverse fly movements.", equipmentRequired: [.flyMachine], exDistinction: .isolation, url: "machine-reverse-fly", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Seated Dumbbell Shoulder Press", aliases: ["Seated Overhead Dumbbell Press"], image: "seated_dumbbell_shoulder_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 50)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Performs an overhead press while seated, targeting the shoulder muscles and triceps.", equipmentRequired: [.dumbbells, .verticalBench], exDistinction: .compound, url: "seated-dumbbell-shoulder-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Seated Shoulder Press", aliases: ["Seated Barbell Overhead Press"], image: "seated_barbell_overhead_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the shoulders and triceps by pressing a barbell overhead from a seated position.", equipmentRequired: [.barbell, .verticalBench], exDistinction: .compound, url: "seated-shoulder-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Landmine Press", aliases: ["Angled Barbell Press"], image: "landmine_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Incorporates a landmine setup to perform a dynamic pressing movement, enhancing upper body strength and stability.", equipmentRequired: [.landmine], exDistinction: .compound, url: "landmine-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "One Arm Landmine Press", aliases: ["Single Arm Landmine Press"], image: "one_arm_landmine_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Utilizes a single-arm press with a landmine, allowing for focused unilateral upper body development.", equipmentRequired: [.landmine], exDistinction: .compound, url: "one-arm-landmine-press", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "Viking Press", aliases: ["Standing Overhead Press Machine"], image: "viking_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Employs a specialized viking press machine for a robust shoulder workout, combining strength and endurance.", equipmentRequired: [.vikingPress], exDistinction: .compound, url: "viking-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Shoulder Pin Press", aliases: ["Rack Overhead Press"], image: "shoulder_pin_press", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets precise strength development using a squat rack to set a specific range for overhead pressing.", equipmentRequired: [.squatRack, .barbell], exDistinction: .compound, url: "shoulder-pin-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Handstand Push-Up", aliases: ["Inverted Push-Up"], image: "handstand_push_up", splitCategory: .shoulders, muscles: [
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .sideDelt, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Challenges the upper body with an inverted position, requiring no equipment and offering intense bodyweight training.", equipmentRequired: [], exDistinction: .compound, url: "handstand-push-ups", usesWeight: false, difficulty: .advanced, limbMovementType: .bilateralDependent),

            
            
            // no data or needs review
            // Exercise(name: "Front Hold", image: "front_hold", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt], secondaryMuscles: [], exDesc: "Challenges the anterior deltoids by holding weights in front of the body at shoulder height.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "front-hold", usesWeight: true),
            // Exercise(name: "Log Press", image: "log_press", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt, .sideDelt], secondaryMuscles: [.triceps], exDesc: "A fundamental compound movement targeting the shoulders and triceps.", equipmentRequired: [], exDistinction: .compound, url: "log-press", usesWeight: true),
            // Exercise(name: "Dumbbell Rear Delt Row", image: "dumbbell_rear_delt_row", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [.upperBack], exDesc: "Focuses on the rear deltoids and upper back by performing a rowing motion with dumbbells.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-rear-delt-row", usesWeight: true),
            // Exercise(name: "Barbell Rear Delt Row", image: "barbell_rear_delt_row", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [.middleBack], exDesc: "Focuses on the rear deltoids and the middle back muscles.", equipmentRequired: [.barbell]),
            // Exercise(name: "Band External Shoulder Rotation", image: "band_external_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [], exDesc: "Improves shoulder stability by externally rotating the shoulder joint.", equipmentRequired: ["Handle Bands", "Mini Loop Bands", "Loop Bands"]),
            // Exercise(name: "Band Internal Shoulder Rotation", image: "band_internal_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt], secondaryMuscles: [], exDesc: "Strengthens the internal rotators of the shoulder for better joint stability.", equipmentRequired: ["Handle Bands", "Mini Loop Bands", "Loop Bands"]),
            // Exercise(name: "Band Pull-Apart", image: "band_pull_apart", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [.upperBack], exDesc: "Targets the rear deltoids and improves posture by pulling a band apart at chest level.", equipmentRequired: ["Handle Bands", "Mini Loop Bands", "Loop Bands"]),
            // Exercise(name: "Cable Rear Delt Row", image: "cable_rear_delt_row", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [.upperBack], exDesc: "Targets the rear deltoids and upper back by rowing handles towards the chest with cables.", equipmentRequired: ["Crossover Cable", "Cable Lat Pulldown", .hiLoPulleyCable, "Cable", "Rope Cable"]),
            // Exercise(name: "Dumbbell Horizontal Internal Shoulder Rotation", image: "dumbbell_horizontal_internal_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt], secondaryMuscles: [], exDesc: "Strengthens the internal rotation of the shoulder using dumbbells.", equipmentRequired: [.dumbbells]),
            // Exercise(name: "Dumbbell Horizontal External Shoulder Rotation", image: "dumbbell_horizontal_external_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [], exDesc: "Enhances shoulder stability and mobility by externally rotating the shoulder with dumbbells.", equipmentRequired: [.dumbbells]),
            // Exercise(name: "Barbell Front Hold", image: "front_hold", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt], secondaryMuscles: [], exDesc: "Challenges the anterior deltoids by holding weights in front of the body at shoulder height.", equipmentRequired: [.barbell]), // note fix
            // Exercise(name: "Lying Dumbbell External Shoulder Rotation", image: "lying_dumbbell_external_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.rearDelt], secondaryMuscles: [], exDesc: "Strengthens the external rotators of the shoulders in a lying position.", equipmentRequired: [.dumbbells]),
            // Exercise(name: "Lying Dumbbell Internal Shoulder Rotation", image: "lying_dumbbell_internal_shoulder_rotation", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt], secondaryMuscles: [], exDesc: "Focuses on the internal rotation of the shoulder muscles while lying down.", equipmentRequired: [.dumbbells]),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Biceps ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Barbell Curl", aliases: ["Barbell Bicep Curl"], image: "barbell_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "A fundamental exercise for biceps growth, involving curling a barbell towards the chest.", equipmentRequired: [.barbell], exDistinction: .isolation, url: "barbell-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Preacher Curl", aliases: ["EZ Bar Preacher Curl"], image: "barbell_preacher_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Isolates the biceps by preventing momentum usage, performed on a preacher bench.", equipmentRequired: [.ezBar, .preacherCurlBench], exDistinction: .isolation, url: "preacher-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Curl With Bar", aliases: ["Straight Bar Cable Curl"], image: "cable_curl_with_bar", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Utilizes a cable machine for consistent resistance throughout the curl motion.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-bicep-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Dumbbell Concentration Curl", aliases: ["Concentration Curl"], image: "dumbbell_concentration_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Focuses on peak biceps contraction and minimizes momentum by sitting with elbow on the thigh.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-concentration-curl", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "Dumbbell Curl", aliases: ["Bicep Dumbbell Curl"], image: "dumbbell_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "A versatile biceps exercise that can be performed with various grips to target different parts.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-curl", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm", weightInstruction: "per dumbbell"),

            Exercise(name: "EZ Bar Curl", aliases: ["EZ Bar Bicep Curl"], image: "ez_bar_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "A fundamental exercise for biceps growth, involving curling a barbell towards the chest.", equipmentRequired: [.barbell], exDistinction: .isolation, url: "ez-bar-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Hammer Curl", aliases: ["Neutral Grip Curl"], image: "hammer_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the biceps and forearms with a neutral grip, emphasizing the brachialis muscle.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "hammer-curl", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm", weightInstruction: "per dumbbell"),

            Exercise(name: "Incline Dumbbell Curl", aliases: ["Incline Bicep Curl"], image: "incline_dumbbell_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Increases the stretch on the biceps by performing curls on an incline bench.", equipmentRequired: [.dumbbells, .inclineBenchRack], exDistinction: .isolation, url: "incline-dumbbell-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Machine Bicep Curl", aliases: ["Bicep Curl Machine"], image: "machine_bicep_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Allows for strict movement pattern and constant tension throughout the curl.", equipmentRequired: [.bicepCurlMachine], exDistinction: .isolation, url: "machine-bicep-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Spider Curl", aliases: ["Incline Bench Spider Curl"], image: "spider_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Performed on a spider bench to prevent momentum usage, focusing on the biceps peak.", equipmentRequired: [.barbell, .inclineBenchRack], exDistinction: .isolation, url: "spider-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Strict Curl", aliases: ["Barbell Strict Curl"], image: "strict_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Executed with strict form to enhance bicep engagement, minimizing momentum for focused intensity.", equipmentRequired: [.ezBar], exDistinction: .isolation, url: "strict-curl", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "One Arm Cable Bicep Curl", aliases: ["Single Arm Cable Curl"], image: "one_arm_bicep_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Provides continuous tension using a cable system, ensuring a full range of motion for precise bicep conditioning.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "one-arm-cable-bicep-curl", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "One Arm Dumbbell Preacher Curl", aliases: ["Single Arm Preacher Curl"], image: "one_arm_dumbbell_preacher_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Involves a preacher bench to support the arm and isolate the bicep curl, enhancing focus and form.", equipmentRequired: [.dumbbells, .preacherCurlBench], exDistinction: .isolation, url: "one-arm-dumbbell-preacher-curl", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "Incline Hammer Curl", aliases: ["Incline Neutral Grip Curl"], image: "incline_hammer_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Performed on an incline bench to increase the range of motion and intensify the bicep workout.", equipmentRequired: [.dumbbells, .inclineBenchRack], exDistinction: .isolation, url: "incline-hammer-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Zottman Curl", aliases: ["Reverse Dumbbell Curl"], image: "zottman_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 50, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Combines traditional and reverse curls to challenge the biceps and forearms, enhancing grip and forearm strength.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "zottman-curl", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Seated Dumbbell Curl", aliases: ["Seated Bicep Curl"], image: "seated_dumbbell_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Allows for a stable seated position to focus on controlled bicep curls, minimizing body movement for better isolation.", equipmentRequired: [.dumbbells, .verticalBench], exDistinction: .isolation, url: "seated-dumbbell-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),

            Exercise(name: "Cheat Curl", aliases: ["Momentum Bicep Curl"], image: "cheat_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Incorporates slight body momentum to enable lifting heavier weights, intensifying bicep engagement.", equipmentRequired: [.ezBar], exDistinction: .isolation, url: "cheat-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Hammer Curl", aliases: ["Neutral Grip Cable Curl"], image: "cable_hammer_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Utilizes a cable setup to maintain resistance, focusing on the biceps and enhancing forearm involvement.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-hammer-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Overhead Cable Curl", aliases: ["High Cable Bicep Curl"], image: "overhead_cable_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the biceps through a unique overhead cable setup, increasing the difficulty and effectiveness of the curl.", equipmentRequired: [.cableCrossover], exDistinction: .isolation, url: "overhead-cable-curl", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Incline Cable Curl", aliases: ["Incline Cable Bicep Curl"], image: "incline_cable_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Performed on an incline using a cable to ensure continuous tension throughout the motion, targeting the biceps efficiently.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "incline-cable-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Lying Cable Curl", aliases: ["Supine Cable Curl"], image: "lying_cable_curl", groupCategory: .arms, splitCategory: .biceps, muscles: [
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Involves lying down to perform curls with a cable, maximizing the resistance curve and minimizing momentum.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "lying-cable-curl", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            // no data or needs review
            // Exercise(name: "Cable Curl With Rope", image: "cable_curl_with_rope", primaryMuscle: .biceps, primaryMuscles: [.bicepsLongHead, .bicepsShortHead], secondaryMuscles: [.forearmFlexors], exDesc: "Adds variation to biceps curls with a focus on the peak contraction using a rope attachment.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-curl-with-rope", usesWeight: true),
            // Exercise(name: "Concentration Curl", image: "concentration_curl", primaryMuscle: .biceps, primaryMuscles: [.bicepsLongHead, .bicepsShortHead], secondaryMuscles: [], exDesc: "Focuses on peak biceps contraction and minimizes momentum by sitting with elbow on the thigh.", equipmentRequired: ["Dumbbell"], exDistinction: .isolation, url: "concentration-curl", usesWeight: true),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Triceps ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Close-Grip Bench Press", aliases: ["Narrow-Grip Bench Press"], image: "close_grip_bench_press", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .sternocostalHead, engagementPercentage: 100)])
            ], exDesc: "Focuses on triceps strength with secondary chest engagement.", equipmentRequired: [.flatBench, .barbell], exDistinction: .compound, url: "close-grip-bench-press", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dips", aliases: ["Chest Dips", "Tricep Dips"], image: "bar_dip", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .costalHead, engagementPercentage: 100)])
            ], exDesc: "Primarily targets the lower chest and triceps when leaned forward.", equipmentRequired: [.dipBar], exDistinction: .compound, url: "dips", usesWeight: false, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Barbell Lying Triceps Extension", aliases: ["Skull Crushers", "Lying Tricep Barbell Extension"], image: "barbell_lying_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 100)
                ])
            ], exDesc: "Also known as skull crushers, this exercise targets the triceps by extending the arms from a lying position.", equipmentRequired: [.barbell, .flatBench], exDistinction: .isolation, url: "lying-tricep-extension", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Bench Dips", aliases: ["Tricep Bench Dips"], image: "bench_dip", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Uses body weight to work the triceps, with hands placed on a bench behind the body.", equipmentRequired: [.flatBench], exDistinction: .isolation, url: "bench-dips", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Close-Grip Push-Up", aliases: ["Narrow Push-Up"], image: "close_grip_push_up", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .costalHead, engagementPercentage: 100)
                ])
            ], exDesc: "Emphasizes triceps engagement by performing push-ups with a narrow hand position.", equipmentRequired: [], exDistinction: .isolation, url: "close-grip-push-up", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Lying Dumbbell Triceps Extension", aliases: ["Dumbbell Skull Crushers"], image: "dumbbell_lying_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the triceps by extending dumbbells overhead while lying on a bench.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .isolation, url: "lying-dumbbell-tricep-extension", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Standing Dumbbell Triceps Extension", aliases: ["Overhead Dumbbell Tricep Extension"], image: "dumbbell_standing_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the triceps by extending a dumbbell overhead with both hands.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-tricep-extension", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Overhead Triceps Extension", aliases: ["Overhead Rope Tricep Extension"], image: "overhead_cable_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Utilizes a cable machine to extend the arms overhead, isolating the triceps.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-overhead-tricep-extension", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Dumbbell Tricep Kickback", aliases: ["Tricep Kickback"], image: "dumbbell_tricep_kickback", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 100)
                ])
            ], exDesc: "Involves a hinged motion at the elbow to extend the dumbbell backward, maximizing tricep engagement in a bent-over position.", equipmentRequired: [.flatBench, .dumbbells], exDistinction: .isolation, url: "dumbbell-tricep-kickback", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),

            Exercise(name: "Standing Barbell Triceps Extension", aliases: ["Overhead Barbell Triceps Extension"], image: "barbell_standing_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Involves lifting a barbell overhead and extending the arms to work the triceps in a standing position.", equipmentRequired: [.barbell], exDistinction: .isolation, url: "tricep-extension", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Machine Seated Dip", aliases: ["Seated Dip Machine"], image: "machine_seated_dip", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 34),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 33),
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 33)
                ]),
                MuscleEngagement(muscleWorked: .pectorals, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .costalHead, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 15, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .frontDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Mimics the dipping motion on a specialized machine, focusing on tricep activation without the need for body weight support.", equipmentRequired: [.seatedDipMachine], exDistinction: .compound, url: "seated-dip-machine", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Machine Tricep Extension", aliases: ["Tricep Extension Machine"], image: "machine_tricep_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 30)
                ])
            ], exDesc: "Facilitates tricep extensions on a machine, allowing for precise control and isolation of the tricep muscles.", equipmentRequired: [.tricepExtensionMachine], exDistinction: .isolation, url: "machine-tricep-extension", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Seated Dumbbell Triceps Extension", aliases: ["Seated Overhead Dumbbell Extension"], image: "seated_dumbbell_triceps_extension", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Performed seated with a dumbbell extended overhead, this exercise focuses on controlled tricep engagement.", equipmentRequired: [.flatBench, .dumbbells], exDistinction: .isolation, url: "seated-dumbbell-tricep-extension", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Tricep Pushdown With Bar", aliases: ["Straight Bar Pushdown"], image: "tricep_pushdown_with_bar", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 50)
                ])
            ], exDesc: "Utilizes a bar attachment on a cable machine for a downward tricep pushdown, emphasizing consistent resistance throughout the motion.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "tricep-pushdown", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Reverse Grip Tricep Pushdown", aliases: ["Reverse Cable Pushdown"], image: "reverse_grip_tricep_pushdown", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 100)
                ])
            ], exDesc: "Involves a reverse grip on a cable machine to vary the tricep pushdown, targeting different aspects of the triceps.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "reverse-grip-tricep-pushdown", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Tricep Rope Pushdown", aliases: ["Cable Rope Pushdown"], image: "tricep_rope_pushdown", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsMedialHead, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 50)
                ])
            ], exDesc: "Features a rope attachment for tricep pushdowns on a cable machine, enhancing the peak contraction phase of the exercise.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "tricep-rope-pushdown", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "JM Press", aliases: ["Tricep Bench Press"], image: "jm_press", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 100)
                ])
            ], exDesc: "Blends elements of a close-grip bench press and a tricep extension to create a unique and effective tricep exercise.", equipmentRequired: [.flatBench, .barbell], exDistinction: .isolation, url: "jm-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),

            Exercise(name: "Tate Press", aliases: ["Dumbbell Tate Press"], image: "tate_press", groupCategory: .arms, splitCategory: .triceps, muscles: [
                MuscleEngagement(muscleWorked: .triceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .tricepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .tricepsLateralHead, engagementPercentage: 40)
                ])
            ], exDesc: "Executed by lifting dumbbells from a supine position on a flat bench, directly engaging the triceps with each press.", equipmentRequired: [.flatBench, .dumbbells], exDistinction: .isolation, url: "tate-press", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            //Exercise(name: "Ring Dips", image: "ring_dips", primaryMuscle: .triceps, primaryMuscles: [.tricepsLongHead], secondaryMuscles: [.tricepsMedialHead, .tricepsLateralHead], exDesc: "Engages the triceps by extending a dumbbell overhead with both hands.", equipmentRequired: [.rings], exDistinction: .isolation, url: "ring-dips", usesWeight: false),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Legs ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Bodyweight Squat", aliases: ["Air Squat"], image: "bodyweight_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)])
            ], exDesc: "A foundational exercise that targets the quadriceps, hamstrings, and glutes using body weight.", equipmentRequired: [], exDistinction: .compound, url: "bodyweight-squat", usesWeight: false, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Barbell Hack Squat", aliases: ["Behind the Back Squat"], image: "barbell_hack_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Performs a squat holding a barbell behind the legs, emphasizing the quadriceps and glutes.", equipmentRequired: [.barbell], exDistinction: .compound, url: "barbell-hack-squat", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Machine Hack Squat", aliases: ["Hack Squat"], image: "hack_squat_machine1", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Utilizes a machine to perform a squat motion, focusing on the quadriceps with less lower back strain.", equipmentRequired: [.hackSquat], exDistinction: .compound, url: "hack-squat", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Box Squat", aliases: ["Box Assisted Squat"], image: "box_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)])
            ], exDesc: "Enhances squat depth and form by squatting to a box, focusing on the quadriceps and glutes.", equipmentRequired: [.barbell, .squatRack, .plyometricBox], exDistinction: .compound, url: "box-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Squat", aliases: ["Weighted Squat"], image: "dumbbell_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)])
            ], exDesc: "A squat variation using dumbbells to add resistance, targeting the quadriceps and glutes.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-squat", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Leg Press", aliases: ["Sled Press"], image: "leg_press1", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)])
            ], exDesc: "Targets the lower body by pressing weight away using the legs, focusing on the quadriceps.", equipmentRequired: [.legPress], exDistinction: .compound, url: "sled-leg-press", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Pause Squat", aliases: ["Paused Back Squat"], image: "pause_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Increases time under tension by pausing at the bottom of the squat, focusing on leg strength.", equipmentRequired: [.barbell, .squatRack], exDistinction: .compound, url: "pause-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Smith Machine Squat", aliases: ["Guided Squat"], image: "smith_machine_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Performs squats within the guided path of a Smith machine, focusing on leg muscles.", equipmentRequired: [.smithMachine], exDistinction: .compound, url: "smith-machine-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Back Squat", aliases: ["Barbell Squat", "High-Bar Squat"], image: "squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "A fundamental lower-body exercise that targets the quadriceps, hamstrings, and glutes.", equipmentRequired: [.barbell, .squatRack], exDistinction: .compound, url: "squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Zercher Squat", aliases: ["Front Elbow Squat"], image: "zercher_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "This squat variation involves cradling the barbell in the crook of the elbows, enhancing engagement of the quads and upper back while improving core stability.", equipmentRequired: [.barbell], exDistinction: .compound, url: "zercher-squat", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Vertical Leg Press", aliases: ["Vertical Sled Press"], image: "vertical_leg_press", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Utilizes a vertical press machine to intensify focus on the quads, glutes, and hamstrings, maximizing resistance while lying back.", equipmentRequired: [.verticalLegPress], exDistinction: .compound, url: "vertical-leg-press", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Horizontal Leg Press", aliases: ["Seated Leg Press"], image: "horizontal_leg_press", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Features a horizontal pressing motion to engage the quads, glutes, and hamstrings, offering a comfortable seated position for effective load handling.", equipmentRequired: [.horizontalLegPress], exDistinction: .compound, url: "horizontal-leg-press", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Pistol Squat", aliases: ["Single-Leg Squat"], image: "pistol_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 40, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .gluteusMedius, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Challenges strength and balance through a single-legged squat to full depth, effectively targeting the quads, hamstrings, and glutes with bodyweight alone.", equipmentRequired: [], exDistinction: .compound, url: "pistol-squat", usesWeight: false, difficulty: .advanced, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Reverse Lunge", aliases: ["Step-Back Lunge"], image: "reverse_lunge", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "Involves stepping backward into a lunge to emphasize lower body strength and stability, engaging quads and glutes without additional equipment.", equipmentRequired: [], exDistinction: .compound, url: "reverse-lunge", usesWeight: false, difficulty: .beginner, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Side Lunge", aliases: ["Lateral Lunge"], image: "side_lunges_bodyweight", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the quadriceps, glutes, and inner thigh muscles by stepping out to the side.", equipmentRequired: [], exDistinction: .compound, url: "side-lunge", usesWeight: false, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Lunge", aliases: ["Forward Lunge"], image: "body_weight_lunge", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "A versatile exercise targeting the quads and glutes, performed without any equipment.", equipmentRequired: [], exDistinction: .compound, url: "lunge", usesWeight: false, difficulty: .beginner, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Barbell Lunge", aliases: ["Weighted Lunge"], image: "barbell_lunge", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "A dynamic exercise that targets the legs and glutes, performed with a barbell for added resistance.", equipmentRequired: [.barbell], exDistinction: .compound, url: "barbell-lunge", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Barbell Walking Lunge", aliases: ["Walking Weighted Lunge"], image: "barbell_walking_lunge", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "Involves lunging forward in a walking motion, greatly engaging the quadriceps and glutes.", equipmentRequired: [.barbell], exDistinction: .compound, url: "walking-lunge", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Dumbbell Lunge", aliases: ["Weighted Dumbbell Lunge"], image: "dumbbell_lunge", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the quadriceps, hamstrings, and glutes, performed with dumbbells for resistance.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-lunge", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg", weightInstruction: "per dumbbell"),
            
            
            
            // no data or needs review
            // Exercise(name: "Chair Squat", image: "chair_squat", primaryMuscle: .legs, primaryMuscles: [.quadriceps], secondaryMuscles: [.gluteusMaximus, .hamstrings], exDesc: "Targets the lower body by squatting down to a chair, emphasizing control and depth.", equipmentRequired: []),
            // Exercise(name: "Step Up", image: "step_up", primaryMuscle: .legs, primaryMuscles: [.quadriceps, .gluteusMaximus], secondaryMuscles: [.hamstrings], exDesc: "Strengthens the legs and glutes by stepping up onto a platform or bench.", equipmentRequired: [.flatBench]),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Quads ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Belt Squat", aliases: ["Hip Belt Squat"], image: "belt_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Focuses on the lower body, particularly the quadriceps, without loading the spine.", equipmentRequired: [.beltSquat], exDistinction: .compound, url: "belt-squat", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Safety Bar Squat", aliases: ["SSB Squat"], image: "safety_bar_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "A squat variation using a safety bar, allowing for a more comfortable position on the shoulders.", equipmentRequired: [.safetySquatBar, .squatRack], exDistinction: .compound, url: "safety-bar-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Front Squat", aliases: ["Clean Squat"], image: "front_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Emphasizes the quadriceps and upper back by holding a barbell in front of the body.", equipmentRequired: [.barbell, .squatRack], exDistinction: .compound, url: "front-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Goblet Squat", aliases: ["Dumbbell Front Squat"], image: "goblet_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "A squat variation holding a dumbbell or kettlebell in front of the chest, targeting the quads.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "goblet-squat", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Landmine Squat", aliases: ["Lever Squat"], image: "landmine_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "A squat variation using a landmine setup to add anterior load, focusing on quadriceps.", equipmentRequired: [.landmine], exDistinction: .compound, url: "landmine-squat", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Barbell Bulgarian Split Squat", aliases: ["Rear Foot Elevated Squat"], image: "bulgarian_split_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .gluteusMedius, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Elevates one leg on a bench for a split squat, increasing load with a barbell to significantly boost quad and glute strength.", equipmentRequired: [.flatBench, .barbell], exDistinction: .compound, url: "bulgarian-split-squat", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),

            Exercise(name: "Dumbbell Bulgarian Split Squat", aliases: ["Dumbbell Rear Foot Elevated Squat"], image: "dumbbell_bulgarian_split_squat", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .gluteusMedius, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Incorporates dumbbells to enhance the split squat, providing a versatile and intense workout for the quads, glutes, and hamstrings.", equipmentRequired: [.flatBench, .dumbbells], exDistinction: .compound, url: "dumbbell-bulgarian-split-squat", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg", weightInstruction: "per dumbbell"),

            Exercise(name: "Leg Extension", aliases: ["Quad Extension"], image: "leg_extension", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 40)
                ])
            ], exDesc: "Isolates the quadriceps by extending the legs against resistance in a seated position.", equipmentRequired: [.legExtensionMachine], exDistinction: .isolation, url: "leg-extension", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Cable Leg Extension", aliases: ["Cable Quad Extension"], image: "cable_leg_extension", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ])
            ], exDesc: "Performed with a cable machine, this exercise isolates the quadriceps by extending the legs against resistance from a seated position, ensuring targeted muscle activation.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-leg-extension", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),

            Exercise(name: "Machine Hip Adduction", aliases: ["Adductor Machine"], image: "hip_adduction_machine", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .adductors, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the inner thigh muscles by bringing the legs together against resistance.", equipmentRequired: [.hipAdductorMachine], exDistinction: .isolation, url: "hip-adduction", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Trap Bar Deadlift", aliases: ["Hex Bar Deadlift"], image: "trap_bar_deadlift", groupCategory: .legs, splitCategory: .quads, muscles: [
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Utilizes a trap bar to perform deadlifts, reducing strain on the lower back and engaging the legs.", equipmentRequired: [.trapBar], exDistinction: .compound, url: "hex-bar-deadlift", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            
            // review exercises working erector spinae
            // MARK: -------------------------------------------------------------------------------------------------- Hamstrings ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Standing Leg Curl", aliases: ["Single Leg Curl"], image: "standing_leg_curl", groupCategory: .legs, splitCategory: .hamstrings, muscles: [
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 50)])
            ], exDesc: "Executed on a machine that targets the hamstrings through dynamic leg curling, focusing on muscle contraction while standing.", equipmentRequired: [.standingLegCurlMachine], exDistinction: .isolation, url: "standing-leg-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Seated Leg Curl", aliases: ["Hamstring Curl"], image: "seated_leg_curl", groupCategory: .legs, splitCategory: .hamstrings, muscles: [
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Targets the hamstrings by curling the legs towards the body in a seated position.", equipmentRequired: [.seatedLegCurlMachine], exDistinction: .isolation, url: "seated-leg-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Romanian Deadlift", aliases: ["RDL"], image: "romanian_deadlift", groupCategory: .legs, splitCategory: .hamstrings, muscles: [
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 50, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)]),
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 20, isPrimary: false, submusclesWorked: [])
            ], exDesc: "Strengthens the posterior chain, including the hamstrings and glutes, by hinging at the hips.", equipmentRequired: [.barbell], exDistinction: .compound, url: "romanian-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Lying Leg Curl", aliases: ["Prone Leg Curl"], image: "lying_leg_curl", groupCategory: .legs, splitCategory: .hamstrings, muscles: [
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)])
            ], exDesc: "Isolates the hamstrings by curling the legs towards the body in a prone position.", equipmentRequired: [.lyingLegCurlMachine], exDistinction: .isolation, url: "lying-leg-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Good Morning", aliases: ["Barbell Good Morning"], image: "good_morning", groupCategory: .legs, splitCategory: .hamstrings, muscles: [
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)]),
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 40, isPrimary: false, submusclesWorked: [])
            ], exDesc: "Strengthens the lower back and hamstrings by hinging at the waist with a barbell on the shoulders.", equipmentRequired: [.barbell, .squatRack], exDistinction: .compound, url: "good-morning", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Calves ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Seated Calf Raise", aliases: ["Soleus Raise"], image: "seated_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 100)])
            ], exDesc: "Targets the soleus muscle of the calves by lifting weight from a seated position.", equipmentRequired: [.seatedCalfRaise], exDistinction: .isolation, url: "seated-calf-raise", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Standing Calf Raise", aliases: ["Machine Calf Raise"], image: "machine_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesGastrocnemius, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 30)])
            ], exDesc: "Strengthens the gastrocnemius and soleus muscles by raising the heels off the ground.", equipmentRequired: [.standingCalfRaise], exDistinction: .compound, url: "machine-calf-raise", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Barbell Calf Raise", aliases: ["Barbell Standing Calf Raise"], image: "barbell_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesGastrocnemius, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 30)])
            ], exDesc: "Strengthens the gastrocnemius and soleus muscles by raising the heels off the ground.", equipmentRequired: [.barbell], exDistinction: .compound, url: "barbell-calf-raise", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Dumbbell Calf Raise", aliases: ["Dumbbell Standing Calf Raise"], image: "dumbbell_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesGastrocnemius, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 30)])
            ], exDesc: "Strengthens the gastrocnemius and soleus muscles by raising the heels off the ground.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-calf-raise", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Bodyweight Calf Raise", aliases: ["Calf Raise"], image: "bodyweight_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesGastrocnemius, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 30)])
            ], exDesc: "A simple yet effective movement using body weight to elevate the heels, enhancing calf strength and flexibility. Can be performed anywhere, requiring minimal space.", equipmentRequired: [], exDistinction: .compound, url: "bodyweight-calf-raise", usesWeight: false, difficulty: .beginner, limbMovementType: .bilateralDependent),

            Exercise(name: "Leg Press Calf Raise", aliases: ["Sled Calf Raise"], image: "sled_press_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesGastrocnemius, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 30)])
            ], exDesc: "Utilizes a leg press machine to isolate and strengthen the calves, providing resistance through the leg press motion specifically targeting the heel raise.", equipmentRequired: [.legPress], exDistinction: .compound, url: "sled-press-calf-raise", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),

            Exercise(name: "Single Leg Seated Calf Raise", aliases: ["Unilateral Calf Raise"], image: "single_leg_seated_calf_raise", groupCategory: .legs, splitCategory: .calves, muscles: [
                MuscleEngagement(muscleWorked: .calves, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .calvesSoleus, engagementPercentage: 100)])
            ], exDesc: "Focuses on the soleus muscle with controlled resistance in a seated position, enhancing lower calf development and unilateral strength by working one leg at a time.", equipmentRequired: [.seatedCalfRaise], exDistinction: .isolation, url: "single-leg-seated-calf-raise", usesWeight: true, difficulty: .beginner, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Glutes ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Cable Pull Through", aliases: ["Cable Hip Hinge"], image: "cable_pull_through", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Strengthens the glutes and hamstrings by pulling a cable through the legs to hip extension.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .compound, url: "cable-pull-through", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Romanian Deadlift", aliases: ["Dumbbell RDL"], image: "dumbbell_romanian_deadlift", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Focuses on the glutes and hamstrings by bending at the hips with dumbbells in hand.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-romanian-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Single Leg Romanian Deadlift", aliases: ["Unilateral RDL"], image: "single_leg_romanian_deadlift", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 70),
                    SubMuscleEngagement(submuscleWorked: .gluteusMedius, engagementPercentage: 30)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Challenges balance and targets the glutes and hamstrings by lifting one leg and bending at the hip with weight.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "single-leg-romanian-deadlift", usesWeight: true, difficulty: .intermediate, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            Exercise(name: "Glute Bridge", aliases: ["Bodyweight Bridge"], image: "glute_bridge", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 70, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the glutes by lifting the hips towards the ceiling while lying on the back.", equipmentRequired: [], exDistinction: .compound, url: "glute-bridge", usesWeight: false, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Machine Hip Abduction", aliases: ["Outer Thigh Machine"], image: "hip_abduction_machine", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .adductors, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .gluteusMedius, engagementPercentage: 50)
                ])
            ], exDesc: "Isolates the outer glutes by pushing out against the resistance of a machine.", equipmentRequired: [.hipAbductorMachine], exDistinction: .isolation, url: "hip-abduction", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Hip Thrust", aliases: ["Barbell Hip Thrust"], image: "hip_thrust", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 60, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Maximizes glute engagement by thrusting the hips upwards with weight across the pelvis.", equipmentRequired: [.barbell, .flatBench], exDistinction: .compound, url: "hip-thrust", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Cable Glute Kickbacks", aliases: ["Cable Kickbacks"], image: "cable_glute_kickbacks", groupCategory: .legs, splitCategory: .glutes, muscles: [
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates the glutes by performing kickbacks against the pull of a cable machine.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-kickback", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per leg"),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Back ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Back Extension", aliases: ["Hyperextension"], image: "back_extension", splitCategory: .back, muscles: [MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 100, isPrimary: true, submusclesWorked: [])], exDesc: "Strengthens the lower back muscles by extending the spine against gravity.", equipmentRequired: [.backExtensionBench], exDistinction: .isolation, url: "back-extension", usesWeight: true, difficulty: .novice),
            
            Exercise(name: "Machine Back Extension", aliases: ["Back Extension Machine"], image: "machine_back_extension", splitCategory: .back, muscles: [MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 100, isPrimary: true, submusclesWorked: [])], exDesc: "Strengthens the lower back muscles by extending the spine against gravity.", equipmentRequired: [.backExtensionMachine], exDistinction: .isolation, url: "machine-back-extension", usesWeight: true, difficulty: .beginner),
            
            Exercise(name: "Deadlift", aliases: ["Conventional Deadlift"], image: "deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ])
            ], exDesc: "A fundamental strength exercise that targets the lower back, hamstrings, and quads.", equipmentRequired: [.barbell], exDistinction: .compound, url: "deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Deficit Deadlift", aliases: ["Elevated Deadlift"], image: "deficit_deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ])
            ], exDesc: "Increases the range of motion of the standard deadlift, enhancing leg and lower back activation.", equipmentRequired: [.barbell], exDistinction: .compound, url: "deficit-deadlift", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Deadlift", aliases: ["DB Deadlift"], image: "dumbbell_deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ])
            ], exDesc: "A variation of the deadlift using dumbbells to target the lower back, hamstrings, and quads.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Pause Deadlift", aliases: ["Mid-Pull Deadlift"], image: "pause_deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .quadriceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rectusFemoris, engagementPercentage: 40),
                    SubMuscleEngagement(submuscleWorked: .vastusLateralis, engagementPercentage: 30),
                    SubMuscleEngagement(submuscleWorked: .vastusMedialis, engagementPercentage: 30)
                ])
            ], exDesc: "Enhances tension in the lower back by pausing midway during the deadlift.", equipmentRequired: [.barbell], exDistinction: .compound, url: "pause-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Rack Pull", aliases: ["Partial Deadlift"], image: "rack_pull", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "A deadlift variation that focuses on the top half of the movement, emphasizing lower back strength.", equipmentRequired: [.squatRack, .barbell], exDistinction: .compound, url: "rack-pull", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Stiff-Legged Deadlift", aliases: ["Straight-Leg Deadlift"], image: "stiff_legged_deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 60, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the hamstrings and lower back by keeping the legs straight while bending at the waist.", equipmentRequired: [.barbell], exDistinction: .compound, url: "stiff-leg-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Sumo Deadlift", aliases: ["Wide-Stance Deadlift"], image: "sumo_deadlift", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .erectorSpinae, engagementPercentage: 40, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .hamstrings, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .medialHamstring, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lateralHamstring, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .gluteus, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .gluteusMaximus, engagementPercentage: 100)
                ])
            ], exDesc: "A deadlift variation with a wide stance, targeting the lower back, glutes, and inner thighs.", equipmentRequired: [.barbell], exDistinction: .compound, url: "sumo-deadlift", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            
            
            // no data or needs review
            // Exercise(name: "Machine Glute Kickbacks", image: "machine_glute_kickbacks", primaryMuscle: .gluteus, primaryMuscles: [.gluteusMaximus], secondaryMuscles: [], exDesc: "Targets the glutes by kicking back against the resistance of a machine.", equipmentRequired: [.gluteKickbackMachine], exDistinction: .isolation, url: "machine-glute-kickbacks", usesWeight: true),
            // Exercise(name: "Banded Side Kicks", image: "banded_side_kicks", primaryMuscle: .gluteus, primaryMuscles: [.gluteusMedius], secondaryMuscles: [], exDesc: "Targets the gluteus medius by performing side kicks against the resistance of a band.", equipmentRequired: ["Resistance Band"]),
            // Exercise(name: "Hip Abduction Against Band", image: "hip_abduction_against_band", primaryMuscle: .gluteus, primaryMuscles: [.gluteusMedius], secondaryMuscles: [], exDesc: "Works the gluteus medius by moving the legs apart against a resistance band.", equipmentRequired: ["Resistance Band"]),
            // Exercise(name: "Hip Thrust Machine", image: "hip_thrust_machine", primaryMuscle: .gluteus, primaryMuscles: [.gluteusMaximus], secondaryMuscles: [.hamstrings, .quadriceps], exDesc: "Provides a stable platform for performing hip thrusts with adjustable resistance.", equipmentRequired: ["Hip Thrust Machine"]),
            // Exercise(name: "Lateral Walk With Band", image: "lateral_walk_with_band", primaryMuscle: .gluteus, primaryMuscles: [.gluteusMedius], secondaryMuscles: [.gluteusMinimus], exDesc: "Strengthens the side glutes and enhances hip stability by walking sideways with a band around the legs.", equipmentRequired: ["Resistance Band"]),
            
            
            
            
            // no data or needs review
            //Exercise(name: "Snatch Grip Deadlift", image: "snatch_grip_deadlift", primaryMuscle: .back, primaryMuscles: [.lowerBack], secondaryMuscles: [.hamstrings, .upperBack], exDesc: "A deadlift variation with a wider grip, increasing the range of motion and targeting the back more intensively.", equipmentRequired: [.barbell], exDistinction: .compound, url: "snatch-grip-deadlift", usesWeight: true),
            // Exercise(name: "Jefferson Curl", image: "jefferson_curl", primaryMuscle: .back, primaryMuscles: [.lowerBack], secondaryMuscles: [.hamstrings], exDesc: "Increases spinal mobility and strength by curling the body downwards with a weight.", equipmentRequired: [.barbell, .dumbbells]),
            // Exercise(name: "Kettlebell Swing", image: "kettlebell_swing", primaryMuscle: .back, primaryMuscles: [.lowerBack], secondaryMuscles: [.hamstrings, .gluteus], exDesc: "A dynamic exercise that strengthens the lower back, hamstrings, and glutes through a swinging motion.", equipmentRequired: [.kettlebells]),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Lats ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Barbell Row", aliases: ["Bent-Over Row"], image: "barbell_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the upper and middle back muscles, including the lats and rhomboids, by rowing a barbell.", equipmentRequired: [.barbell], exDistinction: .compound, url: "bent-over-row", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Chin-Up", aliases: ["Underhand Pull-Up"], image: "chin_up", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 50, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Strengthens the upper back and biceps by pulling the body up until the chin clears the bar.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "chin-ups", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Pull-Up", aliases: ["Overhand Pull-Up"], image: "pull_up", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 60, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "A fundamental upper body exercise that targets the upper back and biceps by pulling the body up to a bar.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "pull-ups", usesWeight: false, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Neutral Grip Pull-Up", aliases: ["Parallel Grip Pull-Up"], image: "neutral_grip_pull_up", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 50, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Involves pulling up with palms facing each other, which allows for a natural grip and helps engage both the upper back and biceps more effectively.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "neutral-grip-pull-ups", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Muscle-Up", aliases: ["Bar Muscle-Up"], image: "muscle_up", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 60, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 40, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Combines a pull-up with a dip to transition from below to above the bar, challenging the upper back, biceps, and shoulders in a dynamic, powerful movement.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "muscle-ups", usesWeight: false, difficulty: .advanced, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Seated Cable Row", aliases: ["Cable Row"], image: "seated_cable_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 40, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 15, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ])
            ], exDesc: "Engages the middle back muscles and secondary arm muscles by rowing a cable towards the torso.", equipmentRequired: [.cableRow], exDistinction: .compound, url: "seated-cable-row", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Seated Machine Row", aliases: ["Row Machine"], image: "seated_machine_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 40, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 25, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 15, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the middle back muscles with a stable and controlled rowing motion.", equipmentRequired: [.seatedRowMachine], exDistinction: .compound, url: "machine-row", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Row", aliases: ["Single-Arm Row"], image: "dumbbell_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Engages the upper and middle back muscles by rowing a dumbbell with one arm.", equipmentRequired: [.dumbbells], exDistinction: .compound, url: "dumbbell-row", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per arm"),
            
            Exercise(name: "Inverted Row", aliases: ["Bodyweight Row"], image: "inverted_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Strengthens the back and biceps by rowing the body upwards towards a bar.", equipmentRequired: [.smithMachine], exDistinction: .compound, url: "inverted-row", usesWeight: false, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "T-Bar Row", aliases: ["Landmine Row"], image: "t_bar_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the back muscles by rowing a T-bar loaded with weights towards the torso.", equipmentRequired: [.tBarRow], exDistinction: .compound, url: "t-bar-row", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Pendlay Row", aliases: ["Strict Row"], image: "pendlay_row", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerTraps, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "A strict rowing motion from the floor, targeting the upper and middle back with minimal momentum.", equipmentRequired: [.barbell], exDistinction: .compound, url: "pendlay-row", usesWeight: true, difficulty: .intermediate, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Lat Pulldown", aliases: ["Wide-Grip Pulldown"], image: "lat_pulldown", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 10, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 10, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Targets the latissimus dorsi and biceps by pulling a bar down in front of the body.", equipmentRequired: [.cableLatPulldown], exDistinction: .compound, url: "lat-pulldown", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Reverse Grip Lat Pulldown", aliases: ["Underhand Pulldown"], image: "reverse_grip_lat_pulldown", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 50, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ])
            ], exDesc: "Engages the lats and biceps with a reverse grip, altering the pull angle for varied muscle activation.", equipmentRequired: [.cableLatPulldown], exDistinction: .compound, url: "reverse-grip-lat-pulldown", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "One-Arm Lat Pulldown", aliases: ["Unilateral Pulldown"], image: "one_arm_lat_pulldown", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 60, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 10, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 30, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .bicepsLongHead, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .bicepsShortHead, engagementPercentage: 40)
                ])
            ], exDesc: "Focuses on unilateral lat development by pulling down a cable with one arm.", equipmentRequired: [.cableLatPulldown], exDistinction: .compound, url: "one-arm-lat-pulldown", usesWeight: true, difficulty: .beginner, limbMovementType: .unilateral, repsInstruction: "per arm"),
            
            Exercise(name: "Straight Arm Lat Pulldown", aliases: ["Lat Isolator Pulldown"], image: "straight_arm_lat_pulldown", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .latissimusDorsi, engagementPercentage: 80, isPrimary: true, submusclesWorked: []),
                MuscleEngagement(muscleWorked: .deltoids, engagementPercentage: 20, isPrimary: false, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .rearDelt, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates the lats by pulling a bar down with straight arms, focusing on lat width.", equipmentRequired: [.cableLatPulldown], exDistinction: .compound, url: "straight-arm-pulldown", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Traps ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Smith Machine Shrug", aliases: ["Guided Shrug"], image: "smith_machine_shrug", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the upper back, specifically the trapezius muscles, by lifting and lowering the shoulders using the guided stability of a Smith machine.", equipmentRequired: [.smithMachine], exDistinction: .isolation, url: "smith-machine-shrug", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Shrug", aliases: ["Free-Weight Shrug"], image: "dumbbell_shrug", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the traps by elevating the shoulders while holding dumbbells.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-shrug", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Barbell Shrug", aliases: ["Trap Shrug"], image: "barbell_shrug", splitCategory: .back, muscles: [
                MuscleEngagement(muscleWorked: .trapezius, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperTraps, engagementPercentage: 100)
                ])
            ], exDesc: "Focuses on the trapezius muscles by shrugging the shoulders while holding a barbell.", equipmentRequired: [.barbell], exDistinction: .compound, url: "barbell-shrug", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            //Exercise(name: "Cable Shrug", aliases: ["Shrug with Cables"], image: "cable_shrug", primaryMuscle: .trapezius, muscleCategories: [.trapezius: [.upperTraps]], exDesc: "Engages the trapezius muscles using constant resistance from a cable machine.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .isolation, url: "cable-shrug", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            //Exercise(name: "Trap Bar Shrug", aliases: ["Hex Bar Shrug"], image: "trap_bar_shrug", primaryMuscle: .trapezius, muscleCategories: [.trapezius: [.upperTraps]], exDesc: "Targets the upper traps by shrugging with a neutral grip using a trap bar.", equipmentRequired: [.trapBar], exDistinction: .compound, url: "trap-bar-shrug", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Abs ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Ab Wheel Roll-Out", aliases: ["Kneeling Ab Rollout", "Wheel Rollout"], image: "kneeling_ab_wheel_roll_out", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 50)
                ])
            ], exDesc: "Strengthens the entire abdominal region through extension and contraction with an ab wheel.", equipmentRequired: [.abWheel], exDistinction: .compound, url: "ab-wheel-rollout", usesWeight: false, difficulty: .novice),
            
            Exercise(name: "Crunch", aliases: ["Abdominal Crunch", "Basic Crunch"], image: "crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 80),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 20)
                ])
            ], exDesc: "A fundamental exercise focusing on the upper abdominals with potential engagement of the lower abs.", equipmentRequired: [], exDistinction: .compound, url: "crunches", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Hanging Leg Raise", aliases: ["Leg Lift", "Bar Hanging Raise"], image: "hanging_leg_raise", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Strengthens the lower abdominals by raising the legs to parallel while hanging from a bar.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "hanging-leg-raise", usesWeight: false, difficulty: .novice),
            
            Exercise(name: "Hanging Knee Raise", aliases: ["Knee Tuck", "Hanging Knee Lift"], image: "hanging_knee_raise", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Focuses on the lower abs by raising the knees towards the chest in a hanging position.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "hanging-knee-raise", usesWeight: false, difficulty: .novice),
            
            Exercise(name: "Cable Wood Chop", aliases: ["Rotational Chop", "Oblique Woodchopper"], image: "cable_woodchop", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .obliques, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the obliques and abs by moving the cable horizontally across the body.", equipmentRequired: [.cableCrossover], exDistinction: .compound, url: "cable-woodchopper", usesWeight: true, difficulty: .novice, limbMovementType: .unilateral, repsInstruction: "per side"),
            
            Exercise(name: "Lying Leg Raise", aliases: ["Supine Leg Lift", "Leg Raises"], image: "lying_leg_raise", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Isolates the lower abdominals by raising the legs while lying on the back.", equipmentRequired: [], exDistinction: .isolation, url: "lying-leg-raise", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Machine Seated Crunch", aliases: ["Seated Ab Crunch", "Machine Ab Crunch"], image: "machine_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 40)
                ])
            ], exDesc: "Allows for targeted abdominal exercises with adjustable resistance.", equipmentRequired: [.abCrunchMachine], exDistinction: .compound, url: "machine-seated-crunch", usesWeight: true, difficulty: .beginner),
            
            Exercise(name: "Mountain Climbers", aliases: ["Climbers", "Dynamic Mountain Climb"], image: "mountain_climbers", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [])
            ], exDesc: "A dynamic exercise that combines cardio with core strengthening.", equipmentRequired: [], exDistinction: .compound, url: "mountain-climbers", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Russian Twist", aliases: ["Oblique Twist", "Side-To-Side Twist"], image: "oblique_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .obliques, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the side abdominal muscles by performing a crunch with a twist.", equipmentRequired: [], exDistinction: .compound, url: "russian-twist", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Scissor Kicks", aliases: ["Flutter Kicks", "Alternating Leg Raise"], image: "scissor_kicks", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Strengthens the lower abs through alternating leg movements while lying on the back.", equipmentRequired: [], exDistinction: .compound, url: "scissor-kicks", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Sit-Up", aliases: ["Full Sit-Up", "Basic Sit-Up"], image: "sit_up", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 40)
                ])
            ], exDesc: "A classic abdominal exercise targeting the entire abs region through a full range of motion.", equipmentRequired: [], exDistinction: .compound, url: "sit-ups", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Standing Cable Crunch", aliases: ["Cable Ab Pulldown", "Standing Crunch"], image: "standing_cable_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Engages the core by crunching downward using cable resistance while standing, providing an intense focus on the upper abdominals.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .compound, url: "standing-cable-crunch", usesWeight: true, difficulty: .novice),
            
            Exercise(name: "High Pulley Crunch", aliases: ["Overhead Cable Crunch", "Kneeling Cable Crunch"], image: "high_pulley_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Executed by pulling down on a cable from a standing position, this crunch intensely works the upper abs with full core engagement.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .compound, url: "high-pulley-crunch", usesWeight: true, difficulty: .novice),
            
            Exercise(name: "Decline Crunch", aliases: ["Decline Ab Crunch", "Inclined Crunch"], image: "decline_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 50)
                ])
            ], exDesc: "Performed on a decline bench, this exercise maximizes abdominal muscle contraction through an increased range of motion, targeting both upper and lower abs.", equipmentRequired: [], exDistinction: .compound, url: "decline-crunch", usesWeight: false, difficulty: .novice),
            
            Exercise(name: "Toes to Bar", aliases: ["Hanging Toe Touch", "Bar Toe Raise"], image: "toes_to_bar", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Challenges the core by hanging from a bar and lifting toes to meet the bar, engaging primarily the lower abs and improving grip and upper body strength.", equipmentRequired: [.pullUpBar], exDistinction: .compound, url: "toes-to-bar", usesWeight: false, difficulty: .intermediate),
            
            Exercise(name: "Flutter Kicks", aliases: ["Kicking Motion", "Leg Flutter"], image: "flutter_kicks", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 100)
                ])
            ], exDesc: "Involves lying flat and alternating leg movements to strengthen the lower abs and increase core endurance.", equipmentRequired: [], exDistinction: .compound, url: "flutter-kicks", usesWeight: false, difficulty: .beginner),
            
            Exercise(name: "Decline Sit-Up", aliases: ["Incline Sit-Up", "Advanced Sit-Up"], image: "decline_sit_up", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 40)
                ])
            ], exDesc: "Utilizes a decline bench to increase the intensity of the sit-up, engaging the full abdominal region for comprehensive core strength.", equipmentRequired: [], exDistinction: .compound, url: "decline-sit-up", usesWeight: false, difficulty: .novice),
            
            Exercise(name: "Cable Crunch", aliases: ["Kneeling Cable Crunch", "Weighted Ab Pulldown"], image: "cable_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .upperAbs, engagementPercentage: 50),
                    SubMuscleEngagement(submuscleWorked: .lowerAbs, engagementPercentage: 50)
                ])
            ], exDesc: "Involves kneeling and crunching down against a cable for concentrated abdominal resistance, targeting the entire core for optimal strength and conditioning.", equipmentRequired: [.hiLoPulleyCable], exDistinction: .compound, url: "cable-crunch", usesWeight: true, difficulty: .novice),
            
            Exercise(name: "Side Crunch", aliases: ["Oblique Side Crunch", "Lateral Crunch"], image: "side_crunch", splitCategory: .abs, muscles: [
                MuscleEngagement(muscleWorked: .abdominals, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .obliques, engagementPercentage: 100)
                ])
            ], exDesc: "Focuses on oblique muscles by performing lateral crunches, enhancing side core strength and flexibility, suitable for floor execution.", equipmentRequired: [], exDistinction: .compound, url: "side-crunch", usesWeight: false, difficulty: .beginner),
            
            
            // no data or needs review
            // Exercise(name: "Side Plank", image: "side_plank", primaryMuscle: .abdominals, primaryMuscles: [.obliques], secondaryMuscles: [], exDesc: "Engages the obliques and improves core stability by holding a side position.", equipmentRequired: ["Mat"]),
            // Exercise(name: "Kneeling Plank", image: "kneeling_plank", primaryMuscle: .abdominals, primaryMuscles: [.upperAbs, .lowerAbs, .obliques], secondaryMuscles: [], exDesc: "A modified plank for beginners, focusing on core stabilization and strength.", equipmentRequired: ["Mat"]),
            // Exercise(name: "Kneeling Side Plank", image: "kneeling_side_plank", primaryMuscle: .abdominals, primaryMuscles: [.obliques], secondaryMuscles: [], exDesc: "Targets the obliques in a more accessible side plank variation for beginners.", equipmentRequired: ["Mat"]),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Forearms ------------------------------------------------------------------------------------------------------------------------------
            Exercise(name: "Barbell Wrist Curl", aliases: ["Wrist Curl", "Barbell Flexor Curl"], image: "barbell_wrist_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Strengthens the forearm flexors by curling a barbell towards the forearm.", equipmentRequired: [.barbell, .flatBench], exDistinction: .isolation, url: "wrist-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Wrist Curl", aliases: ["Wrist Flexion Curl", "Dumbbell Forearm Curl"], image: "dumbbell_wrist_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Targets the wrist flexors with individual dumbbells for balanced muscle development.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .isolation, url: "dumbbell-wrist-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Reverse Wrist Curl", aliases: ["Wrist Extensor Curl", "Barbell Wrist Extension"], image: "reverse_wrist_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 100)
                ])
            ], exDesc: "Focuses on strengthening the forearm extensors by curling the wrists upwards.", equipmentRequired: [.barbell, .flatBench], exDistinction: .isolation, url: "reverse-wrist-curl", usesWeight: true, difficulty: .beginner, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Barbell Reverse Curl", aliases: ["Reverse Curl", "Overhand Barbell Curl"], image: "reverse_barbell_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 80, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ]),
                MuscleEngagement(muscleWorked: .biceps, engagementPercentage: 20, isPrimary: false, submusclesWorked: [])
            ], exDesc: "Engages the forearm extensors by reversing the grip on a barbell, enhancing wrist stability and upper arm strength.", equipmentRequired: [.barbell], exDistinction: .isolation, url: "reverse-barbell-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralDependent),
            
            Exercise(name: "Dumbbell Reverse Curl", aliases: ["Reverse Dumbbell Curl", "Overhand Dumbbell Curl"], image: "dumbbell_reverse_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .brachioradialis, engagementPercentage: 60),
                    SubMuscleEngagement(submuscleWorked: .forearmExtensors, engagementPercentage: 40)
                ])
            ], exDesc: "Utilizes dumbbells with a reverse grip to focus on the forearm extensors, promoting balanced muscle growth and enhanced forearm strength.", equipmentRequired: [.dumbbells], exDistinction: .isolation, url: "dumbbell-reverse-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            Exercise(name: "Dumbbell Reverse Wrist Curl", aliases: ["Reverse Wrist Flexion", "Dumbbell Wrist Extension"], image: "dumbbell_reverse_wrist_curl", groupCategory: .arms, splitCategory: .forearms, muscles: [
                MuscleEngagement(muscleWorked: .forearms, engagementPercentage: 100, isPrimary: true, submusclesWorked: [
                    SubMuscleEngagement(submuscleWorked: .forearmFlexors, engagementPercentage: 100)
                ])
            ], exDesc: "Performed seated with a dumbbell in each hand, this exercise isolates the wrist flexors, improving grip strength and wrist mobility.", equipmentRequired: [.dumbbells, .flatBench], exDistinction: .isolation, url: "dumbbell-reverse-wrist-curl", usesWeight: true, difficulty: .novice, limbMovementType: .bilateralIndependent, weightInstruction: "per dumbbell"),
            
            
            
            // MARK: -------------------------------------------------------------------------------------------------- Olympic Lifts ------------------------------------------------------------------------------------------------------------------------------
            /*
             Exercise(name: "Split Jerk", image: "split_jerk", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt, .sideDelt], secondaryMuscles: [.triceps, .legs], exDesc: "Involves splitting the legs while jerking the bar overhead to build explosive shoulder power.", equipmentRequired: [.barbell], exDistinction: .compound, url: "split-jerk", usesWeight: true),
             Exercise(name: "Power Clean", image: "power_clean", primaryMuscle: .back, primaryMuscles: [.upperBack, .lowerBack], secondaryMuscles: [.hamstrings, .quadriceps], exDesc: "A compound lift that improves explosive power and strength throughout the back.", equipmentRequired: [.barbell], exDistinction: .compound, url: "power-clean", usesWeight: true),
             Exercise(name: "Power Snatch", image: "power_snatch", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "Develops power and muscle coordination by lifting a barbell overhead in one fluid motion.", equipmentRequired: [.barbell], exDistinction: .compound, url: "power-snatch", usesWeight: true),
             Exercise(name: "Snatch", image: "snatch", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "An Olympic lift that works the entire back by lifting a barbell from the floor to overhead in one motion.", equipmentRequired: [.barbell], exDistinction: .compound, url: "snatch", usesWeight: true),
             Exercise(name: "Clean", image: "clean", primaryMuscle: .back, primaryMuscles: [.upperBack, .lowerBack], secondaryMuscles: [.hamstrings, .quadriceps], exDesc: "A powerlifting move that works the entire back and lower body by lifting a barbell from the floor to the shoulders.", equipmentRequired: [.barbell], exDistinction: .compound, url: "clean", usesWeight: true),
             Exercise(name: "Clean and Jerk", image: "clean_and_jerk", primaryMuscle: .back, primaryMuscles: [.upperBack, .lowerBack], secondaryMuscles: [.hamstrings, .quadriceps, .deltoids], exDesc: "Combines a clean with a jerk, engaging the back, legs, and shoulders.", equipmentRequired: [.barbell], exDistinction: .compound, url: "clean-and-jerk", usesWeight: true),
             Exercise(name: "Clean and Press", image: "clean_and_press", primaryMuscle: .back, primaryMuscles: [.upperBack, .lowerBack], secondaryMuscles: [.hamstrings, .quadriceps, .deltoids], exDesc: "Combines a clean with an overhead press, engaging the back, legs, and shoulders.", equipmentRequired: [.barbell], exDistinction: .compound, url: "clean-and-press", usesWeight: true),
             Exercise(name: "Hang Clean", image: "hang_clean", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "A variation of the clean lift performed from the 'hang' position, targeting the back and hamstrings.", equipmentRequired: [.barbell], exDistinction: .compound, url: "hang-clean", usesWeight: true),
             Exercise(name: "Hang Power Clean", image: "hang_power_clean", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "Involves lifting the barbell from the hang position to the shoulders, engaging the back muscles.", equipmentRequired: [.barbell], exDistinction: .compound, url: "hang-power-clean", usesWeight: true),
             Exercise(name: "Hang Power Snatch", image: "hang_power_snatch", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "Executes a snatch from the hang position, improving power and back muscle engagement.", equipmentRequired: [.barbell]),
             Exercise(name: "Hang Snatch", image: "hang_snatch", primaryMuscle: .back, primaryMuscles: [.upperBack], secondaryMuscles: [.lowerBack, .hamstrings], exDesc: "A snatch variation starting from the hang position, focusing on explosive power in the back.", equipmentRequired: [.barbell], exDistinction: .compound, url: "hang-snatch", usesWeight: true),
             Exercise(name: "Power Jerk", image: "power_jerk", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt, .sideDelt], secondaryMuscles: [.triceps, .legs], exDesc: "Explosively drives the bar overhead, engaging the shoulders, triceps, and legs.", equipmentRequired: [.barbell], exDistinction: .compound, url: "power-jerk", usesWeight: true),
             Exercise(name: "Squat Jerk", image: "squat_jerk", primaryMuscle: .deltoids, primaryMuscles: [.frontDelt, .sideDelt], secondaryMuscles: [.triceps, .legs], exDesc: "An advanced movement where the bar is jerked overhead and caught in a squat position.", equipmentRequired: [.barbell], exDistinction: .compound, url: "squat-jerk", usesWeight: true),*/
            
            
            /*
             // MARK: -------------------------------------------------------------------------------------------------- Forearms ------------------------------------------------------------------------------------------------------------------------------
             Exercise(name: "Farmers Walk", image: "farmers_walk", primaryMuscle: .forearms, primaryMuscles: [.forearmFlexors, .forearmExtensors], secondaryMuscles: [], exDesc: "Improves grip strength and endurance by carrying heavy weights over a distance.", equipmentRequired: [.dumbbells, "Kettlebells"]),
             Exercise(name: "One-Handed Bar Hang", image: "one_handed_bar_hang", primaryMuscle: .forearms, primaryMuscles: [.forearmFlexors], secondaryMuscles: [], exDesc: "Enhances grip strength by hanging from a bar with one hand at a time.", equipmentRequired: ["Pull-Up Bar"]),
             Exercise(name: "Plate Pinch", image: "plate_pinch", primaryMuscle: .forearms, primaryMuscles: [.forearmFlexors], secondaryMuscles: [], exDesc: "Develops grip strength by pinching and holding weight plates for time.", equipmentRequired: []),
             Exercise(name: "Plate Wrist Curl", image: "plate_wrist_curl", primaryMuscle: .forearms, primaryMuscles: [.forearmFlexors], secondaryMuscles: [], exDesc: "Isolates the forearm flexors by curling weight plates with the wrists.", equipmentRequired: []),
             Exercise(name: "Towel Pull-Up", image: "towel_pull_up", primaryMuscle: .forearms, primaryMuscles: [.forearmFlexors], secondaryMuscles: [.upperBack], exDesc: "Strengthens the grip and forearms by performing pull-ups with a towel.", equipmentRequired: ["Pull-Up Bar"]),
             
             
             // MARK: -------------------------------------------------------------------------------------------------- Cardio ------------------------------------------------------------------------------------------------------------------------------
             Exercise(name: "Rowing Machine", image: "rowing_machine", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Stationary Bike", image: "stationary_bike", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Treadmill", image: "treadmill", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Elliptical Machine", image: "elliptical_machine", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Stair Climber", image: "stair_climber", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Jump Rope", image: "jump_rope", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Outdoor Running", image: "outdoor_running", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Cycling", image: "cycling", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Swimming", image: "swimming", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "High-Intensity Interval Training (HIIT)", image: "hiit", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Zumba", image: "zumba", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Kickboxing", image: "kickboxing", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Rowing", image: "rowing_cardio", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: []),
             Exercise(name: "Sprint Intervals", image: "sprint_intervals", primaryMuscle: .cardio, primaryMuscles: [], secondaryMuscles: [], exDesc: "", equipmentRequired: [])*/
        ]
    }
    
    func filteredExercises(searchText: String, selectedCategory: CategorySelections, templateCategories: [SplitCategory]? = nil, favoritesOnly: Bool, favoriteList: [String]) -> [Exercise] {
        // 1) Normalize the search string once
        let normalizedSearch = searchText.removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).lowercased()

        // 2) Decide whether an exercise “matches” this categorySelection
        func matchesCategory(_ ex: Exercise) -> Bool {
            switch selectedCategory {
                
            case .split(let splitCat):
                // 1) Are we in “template” mode?
                if let templates = templateCategories {
                    // A) “All” within templates → anything in the template list
                    if splitCat == .all {
                        return templates.contains(ex.splitCategory)
                    }
                    if splitCat == .arms {
                        return SplitCategory.armsGroup.contains(ex.splitCategory)
                    }
                    if splitCat == .legs {
                        return SplitCategory.lowerBody.contains(ex.splitCategory)
                    }
                    // B) Specific split within templates → exact match
                    return ex.splitCategory == splitCat
                }

                // 2) Not template mode?  Then your old logic:
                if splitCat == .all {
                    return true
                }
                if splitCat == .arms {
                    return SplitCategory.armsGroup.contains(ex.splitCategory)
                }
                if splitCat == .legs {
                    return SplitCategory.lowerBody.contains(ex.splitCategory)
                }
                return ex.splitCategory == splitCat

            case .muscle(let m):
                if m == .all {
                    return true
                } else {
                    return ex.primaryMuscles.contains(m)
                }
                
            case .upperLower(let ul):
                switch ul {
                case .upperBody:  return ex.isUpperBody
                case .lowerBody:  return ex.isLowerBody
                }
                
            case .pushPull(let pp):
                switch pp {
                case .push: return ex.isPush
                case .pull: return ex.isPull
                case .legs: return ex.isLowerBody
                }
            }
        }

        // 3) Filter based on search text, favorites, and category
        var results = allExercises.filter { ex in
            // Normalize name + aliases
            let nameNorm   = ex.name
              .removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
              .lowercased()
            let aliasNorms = ex.aliases?
              .map { $0
                .removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                .lowercased()
              } ?? []
            
            let textMatch  = normalizedSearch.isEmpty
                          || nameNorm.contains(normalizedSearch)
                          || aliasNorms.contains(where: { $0.contains(normalizedSearch) })
            let favMatch   = !favoritesOnly || favoriteList.contains(ex.name)
            let catMatch   = matchesCategory(ex)
            
            return textMatch && favMatch && catMatch
        }

        // 4) Sort so items starting with the query bubble to the top
        results.sort { a, b in
            let na = a.name
              .removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
              .lowercased()
            let nb = b.name
              .removingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
              .lowercased()
            
            if na.starts(with: normalizedSearch) && !nb.starts(with: normalizedSearch) {
                return true
            }
            if !na.starts(with: normalizedSearch) && nb.starts(with: normalizedSearch) {
                return false
            }
            return na < nb
        }

        return results
    }
    
    func exercise(named name: String) -> Exercise? {
        return allExercises.first { $0.name == name }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func loadPerformanceData(from fileName: String) {
        let filename = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: filename)
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601
            let performanceData = try jsonDecoder.decode([ExercisePerformance].self, from: data)
            allExercisePerformance = Dictionary(uniqueKeysWithValues: performanceData.map { ($0.id, $0) })
        } catch {
            print("Could not load performance data: \(error.localizedDescription)")
        }
    }
    
    func savePerformanceData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    print("Instance was deinitialized before the operation could complete.")
                }
                return
            }
            
            let filename = self.getDocumentsDirectory().appendingPathComponent("performance.json")
            let performanceArray = Array(self.allExercisePerformance.values)
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .iso8601
                let data = try jsonEncoder.encode(performanceArray)
                try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
                DispatchQueue.main.async {
                    print("Successfully saved performance data to \(filename.path)")
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to save performance data: \(error.localizedDescription)")
                }
            }
        }
    }
    
   /* func createTestMaxes(csvLoader: CSVLoader, userData: UserData) {
        // Set up the date range: from one year ago until today.
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .weekday, value: -1, to: Date()) else { return }
        let endDate = Date()
        
        for exercise in allExercises {
            var maxVal: Double = 0
            if let max = getMax(for: exercise.name) {
                if max > 0 {
                    let incrementedMax = max + (max * 0.05)
                    maxVal = incrementedMax
                }
            } else {
                if exercise.usesWeight {
                    maxVal = csvLoader.calculateFinal1RM(userData: userData, exercise: exercise.url)
                } else {
                    maxVal = Double(csvLoader.calculateFinalReps(userData: userData, exercise: exercise.url))
                }
            }
            
            // For each day from one year ago until today, update the performance record.
           
            updateExercisePerformance(for: exercise.name, newValue: maxVal, csvEstimate: false, date: startDate)
            
        }
        savePerformanceData()
    }*/
    
    func updateExercisePerformance(for exerciseName: String, newValue: Double, reps: Int? = nil, weight: Double? = nil, csvEstimate: Bool, date: Date? = nil) {
        let now = date ?? Date()
        let calendar = Calendar.current
        let roundedDate = calendar.startOfDay(for: now)
        
        var repsXweight: RepsXWeight?
        
        if let reps = reps, let weight = weight {
            repsXweight = RepsXWeight(reps: reps, weight: weight)
        }
        
        if var existingPerformance = allExercisePerformance[exerciseName] {
            if csvEstimate {
                existingPerformance.estimatedValue = newValue
            } else {
                // only update if new max is greater than current max
                if let currentMax = existingPerformance.maxValue, newValue > currentMax,
                   let date = existingPerformance.currentMaxDate {
                    
                    let record = MaxRecord(value: currentMax, repsXweight: existingPerformance.repsXweight, date: date)
                    if existingPerformance.pastMaxes != nil {
                        existingPerformance.pastMaxes!.append(record)
                    } else {
                        existingPerformance.pastMaxes = [record]
                    }
                    print("Updated past max for \(exerciseName): \(currentMax) saved with date \(String(describing: existingPerformance.currentMaxDate))")
                }
                
                existingPerformance.maxValue = newValue
                existingPerformance.currentMaxDate = roundedDate
                if let repsWeight = repsXweight {
                    existingPerformance.repsXweight = repsWeight
                    print("New max for \(exerciseName): \(newValue) (\(repsWeight.weight) x \(repsWeight.reps))")
                } else {
                    print("New max for \(exerciseName): \(newValue)")
                }
                existingPerformance.estimatedValue = nil // no need for estimated value is true max value was added
            }
            // Save the updated performance data
            allExercisePerformance[exerciseName] = existingPerformance
            //savePerformanceData()
            print("Performance data for \(exerciseName) saved.")
            
        } else {
            // Create new performance entry if none exists
            var newPerformance = ExercisePerformance(name: exerciseName)
            if csvEstimate {
                newPerformance.estimatedValue = newValue
            } else {
                newPerformance.maxValue = newValue
                newPerformance.currentMaxDate = roundedDate
                if let repsWeight = repsXweight {
                    newPerformance.repsXweight = repsWeight
                    print("New max for \(exerciseName): \(newValue) (\(repsWeight.weight) x \(repsWeight.reps))")
                }
                newPerformance.estimatedValue = nil // no need for estimated value is true max value was added
            }
            print("New performance entry created for \(exerciseName) with date \(roundedDate)")
            
            allExercisePerformance[exerciseName] = newPerformance
            //savePerformanceData()
            print("New performance data for \(exerciseName) saved.")
        }
    }
    
    func getMax(for exerciseName: String) -> Double? {
        return allExercisePerformance[exerciseName]?.maxValue
    }
    
    func getPastMaxes(for exerciseName: String) -> [MaxRecord] {
        return allExercisePerformance[exerciseName]?.pastMaxes ?? []
    }
    
    func getDateForMax(for exerciseName: String) -> Date? {
        return allExercisePerformance[exerciseName]?.currentMaxDate
    }
    
    func distributeExercisesEvenly(_ exercises: [Exercise]) -> [Exercise] {
        var distributedExercises: [Exercise] = []
        // Tracks unique combinations of primary and secondary muscle groups.
        var muscleCombinationsUsed: [(primary: Set<SubMuscles>, secondary: Set<SubMuscles>)] = []
        
        // Check if the combination of primary and secondary muscles is unique
        func isUniqueCombination(_ exercise: Exercise) -> Bool {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            for combo in muscleCombinationsUsed {
                if combo.primary == primarySet && combo.secondary == secondarySet {
                    //print("Combination already used: Primary: \(combo.primary), Secondary: \(combo.secondary)")
                    return false
                }
            }
            //print("Combination is unique")
            return true
        }
        
        // Add the combination to the tracking set
        func addCombination(_ exercise: Exercise) {
            let primarySet = Set(exercise.primarySubMuscles ?? [])
            let secondarySet = Set(exercise.secondarySubMuscles ?? [])
            
            muscleCombinationsUsed.append((primary: primarySet, secondary: secondarySet))
            //print("Added combination: Primary: \(primarySet), Secondary: \(secondarySet)")
        }
        
        // Attempt to distribute compound exercises first
        exercises.filter({ $0.exDistinction == .compound }).forEach { exercise in
            //print("Processing compound exercise: \(exercise.name)")
            if isUniqueCombination(exercise) {
                distributedExercises.append(exercise)
                addCombination(exercise)
            }
        }
        
        // Follow with isolation exercises, ensuring no overlap in muscle combinations
        exercises.filter({ $0.exDistinction == .isolation }).forEach { exercise in
            //print("Processing isolation exercise: \(exercise.name)")
            if isUniqueCombination(exercise) {
                distributedExercises.append(exercise)
                addCombination(exercise)
            }
        }
        
        //print("Distributed exercises: \(distributedExercises.map { $0.name })")
        return distributedExercises
    }
}
