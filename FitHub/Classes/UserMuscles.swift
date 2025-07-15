//
//  UserMuscles.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/13/25.
//

import Foundation
import Combine

/*
struct UserMuscle: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let name: Muscle
    var restPct: Double = 100
    var subMuscleRestPcts: [SubMuscles: Double]
}


final class UserMuscles: ObservableObject {
    // ───────── Dependencies ─────────
    private let userData: UserData        // ← where workouts + settings live
    private var cancellables = Set<AnyCancellable>()

    // ───────── Model ─────────
    @Published var userMuscles: [UserMuscle]

    // MARK: - Init
    init(userData: UserData) {
         self.userData = userData
         self.userMuscles = UserMuscles.initialMuscleArray

         let durationChanges = userData.$settings
            .map(\.muscleRestDuration)         // extract the Int
            .removeDuplicates()                // only fire if it actually changed
            .map { _ in () }                   // normalize to Void
            .eraseToAnyPublisher()

        let workoutChanges = userData.$workoutPlans
            .map(\.completedWorkouts)          // extract the [Workout]
            .removeDuplicates()                // only fire if it actually changed
            .map { _ in () }
            .eraseToAnyPublisher()

        Publishers.Merge(durationChanges, workoutChanges)
            .sink { [weak self] in
                self?.recalculateAllRestPercentages()
            }
            .store(in: &cancellables)

         // initial calculation
         recalculateAllRestPercentages()
     }
    
    /// Dictionary lookup: `restPercentages[.pectorals] == 73`
    var restPercentages: [Muscle: Int] {
        Dictionary(
           uniqueKeysWithValues:
               userMuscles.map { ($0.name, Int($0.restPct.rounded())) }
        )
    }
    
    private func recalculateAllRestPercentages() {
        print("calculating rest percentages...")
        let now = Date()
        let windowHours = Double(userData.settings.muscleRestDuration)

        // 1️⃣ Filter recent workouts once
        let recentWorkouts = userData.workoutPlans.completedWorkouts.filter {
            now.timeIntervalSince($0.date) / 3600 <= windowHours
        }

        // 2️⃣ Build lookup tables
        var muscleRecords = [Muscle: [(hoursSince: Double, weight: Double, sets: Int)]]()
        var subMuscleRecords = [SubMuscles: [(hoursSince: Double, weight: Double, sets: Int)]]()

        for workout in recentWorkouts {
            let hoursSince = now.timeIntervalSince(workout.date) / 3600

            for exercise in workout.template.exercises {
                // how many sets actually done?
                let doneSets = exercise.setDetails.filter { $0.repsCompleted != nil }.count
                guard doneSets > 0 else { continue }

                // ── Top-level muscles
                for engagement in exercise.muscles {
                    let normEng = engagement.engagementPercentage / 100
                    let psFactor = engagement.isPrimary ? 1.0 : 0.5
                    let weight = normEng * psFactor

                    muscleRecords[engagement.muscleWorked, default: []]
                        .append((hoursSince, weight, doneSets))

                    // ── Sub-muscles of that muscle
                    if let subs = engagement.submusclesWorked {
                        for subEng in subs {
                            let normSub = subEng.engagementPercentage / 100
                            // reuse primary/secondary from parent muscle
                            let subWeight = normSub * psFactor

                            subMuscleRecords[subEng.submuscleWorked, default: []]
                                .append((hoursSince, subWeight, doneSets))
                        }
                    }
                }
            }
        }

        // 3️⃣ Compute final rest% for each UserMuscle
        var updated = userMuscles  // copy-on-write
        for i in updated.indices {
            let muscle = updated[i].name

            // muscle-level
            let entries = muscleRecords[muscle] ?? []
            updated[i].restPct = computeWeightedRest(from: entries, windowHours: windowHours)

            // sub-muscle-level
            var newSubs = updated[i].subMuscleRestPcts
            for sub in newSubs.keys {
                let subEntries = subMuscleRecords[sub] ?? []
                newSubs[sub] = computeWeightedRest(from: subEntries, windowHours: windowHours)
            }
            updated[i].subMuscleRestPcts = newSubs
        }

        userMuscles = updated
    }

    /// Given a list of (hoursSince, weight, sets), produce a 0–100 rest%
    private func computeWeightedRest(
        from records: [(hoursSince: Double, weight: Double, sets: Int)],
        windowHours: Double
    ) -> Double {
        var totalWeight = 0.0
        var totalRest   = 0.0

        for (hoursSince, weight, sets) in records {
            // linear percent: 0h→0% rest, windowHours→100% rest
            let rawPct   = min(1, hoursSince / windowHours) * 100
            let contrib  = weight * Double(sets)
            totalWeight += contrib
            totalRest   += contrib * rawPct
        }

        return totalWeight > 0
            ? (totalRest / totalWeight)
            : 100  // fully rested if no records
    }
}

extension UserMuscles {
    /// Whole starting array with every muscle at 100 % rest.
    private static var initialMuscleArray: [UserMuscle] = [
        // MARK: - Independent
        UserMuscle(name: .abdominals, subMuscleRestPcts: [.upperAbs: 100, .lowerAbs: 100, .obliques: 100, .externalObliques: 100]),
        UserMuscle(name: .pectorals, subMuscleRestPcts: [.clavicularHead: 100, .sternocostalHead: 100, .costalHead: 100]),
        UserMuscle(name: .deltoids, subMuscleRestPcts: [.frontDelt: 100, .sideDelt: 100, .rearDelt: 100]),
        
        // MARK: - Part of Muscle Group
        UserMuscle(name: .biceps, subMuscleRestPcts: [.bicepsLongHead: 100, .bicepsShortHead: 100, .bicepsBrachialis: 100]),
        UserMuscle(name: .triceps, subMuscleRestPcts: [.tricepsLongHead: 100, .tricepsLateralHead: 100, .tricepsMedialHead: 100]),
        UserMuscle(name: .trapezius, subMuscleRestPcts: [.upperTraps: 100, .lowerTraps: 100]),
        UserMuscle(name: .latissimusDorsi, subMuscleRestPcts: [.upperLats: 100, .lowerLats: 100, .teresMajor: 100]),
        UserMuscle(name: .erectorSpinae, subMuscleRestPcts: [.iliocostalis: 100, .longissimus: 100, .spinalis: 100]),
        UserMuscle(name: .quadriceps, subMuscleRestPcts: [.rectusFemoris: 100, .vastusMedialis: 100, .vastusLateralis: 100]),
        UserMuscle(name: .gluteus, subMuscleRestPcts: [.gluteusMaximus: 100, .gluteusMedius: 100, .gluteusMinimus: 100]),
        UserMuscle(name: .hamstrings, subMuscleRestPcts: [.lateralHamstring: 100, .medialHamstring: 100]),
        
        // MARK: - Accessory
        UserMuscle(name: .hipFlexors, subMuscleRestPcts: [.adductors: 100, .abductors: 100]),
        UserMuscle(name: .scapularStabilizers, subMuscleRestPcts: [.teresMinor: 100, .infraspinatus: 100, .rhomboids: 100, .levatorScapulae: 100]),
        UserMuscle(name: .calves, subMuscleRestPcts: [.calvesGastrocnemius: 100, .calvesSoleus: 100]),
        UserMuscle(name: .forearms, subMuscleRestPcts: [.brachioradialis: 100, .forearmFlexors: 100, .forearmExtensors: 100]),
        UserMuscle(name: .cervicalSpine, subMuscleRestPcts: [.infrahyoid: 100, .sternocleidomastoid: 100, .scalenes: 100, .longusFlexors: 100])
    ]
}

*/
