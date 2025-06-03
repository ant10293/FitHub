//
//  DetailedMuscleGroupsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/21/24.
//

import SwiftUI


struct DetailedMuscleGroupsView: View {
    @EnvironmentObject var userData: UserData
    var muscle: Muscle
    @State var showFront: Bool
    @State private var hasFront: Bool = false
    @State private var hasRear: Bool = false
    @State private var selectedSubMuscle: SubMuscles? = nil
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            Text(muscle.simpleName)
                .font(.headline)
            + Text(muscle.rawValue != muscle.simpleName ? " (\(muscle.rawValue))" : "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            
            ZStack {
                // Determine whether to show front or rear view
                if showFront {
                    if Muscle.hasFrontImages.contains(muscle) {
                        DirectImageView(imageName: "(M)Front_Detailed_Blank-\(muscle.rawValue.replacingOccurrences(of: " ", with: "-").lowercased())")
                            .opacity(1.0)
                    }
                    
                    ForEach(Muscle.getSubMuscles(for: muscle), id: \.self) { subMuscle in
                        ForEach(subMuscle.detailedMuscleGroupImages.filter { $0.contains("Front") }, id: \.self) { imagePath in
                            DirectImageView(imageName: imagePath)
                                .opacity(calculateOpacity(for: subMuscle))
                                .onTapGesture {
                                    selectedSubMuscle = subMuscle
                                }
                        }
                    }
                } else {
                    if Muscle.hasRearImages.contains(muscle) {
                        DirectImageView(imageName: "(M)Rear_Detailed_Blank-\(muscle.rawValue.replacingOccurrences(of: " ", with: "-").lowercased())")
                            .opacity(1.0)
                    }
                    
                    ForEach(Muscle.getSubMuscles(for: muscle), id: \.self) { subMuscle in
                        ForEach(subMuscle.detailedMuscleGroupImages.filter { $0.contains("Rear") }, id: \.self) { imagePath in
                            DirectImageView(imageName: imagePath)
                                .opacity(calculateOpacity(for: subMuscle))
                                .onTapGesture {
                                    selectedSubMuscle = subMuscle
                                }
                        }
                    }
                }
                if hasFront && hasRear {
                    Button(action: { withAnimation { showFront.toggle() } }) {
                        Image(systemName: "arrow.2.circlepath")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 300)
                    .padding(.top, 220)
                }
            }
            
            List {
                Section(header: Text("Select submuscle to view recent sets")) {
                    ForEach(Muscle.getSubMuscles(for: muscle), id: \.self) { subMuscle in
                        VStack(alignment: .leading) {
                            HStack {
                                if SubMuscles.hasNoImages.contains(subMuscle) {
                                    Text(subMuscle.simpleName)
                                        .foregroundColor(.gray)
                                    +
                                    // we will remove this upon color coding the visible muscles
                                    Text(" (Deep)")
                                        .fontWeight(.semibold)
                                    
                                } else {
                                    Text(subMuscle.simpleName)
                                        .foregroundColor(determineTextColor(for: subMuscle))
                                }
                                Spacer()
                                Text("\(calculateRestPercentage(for: subMuscle))%")
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            if subMuscle.simpleName != subMuscle.rawValue {
                                Text(subMuscle.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSubMuscle = subMuscle
                        }
                    }
                }
            }
        }
        .onAppear {
            determineDefaultViewSide()
        }
        .sheet(item: $selectedSubMuscle) { subMuscle in
            RecentlyCompletedSetsView(muscle: subMuscle, userData: userData) {
                selectedSubMuscle = nil
            }
        }
        .padding()
    }
    
    private func determineTextColor(for subMuscle: SubMuscles) -> Color {
        let hasFrontImage = SubMuscles.hasFrontImages.contains(subMuscle)
        let hasRearImage = SubMuscles.hasRearImages.contains(subMuscle)
        let hasBothImages = SubMuscles.hasBothImages.contains(subMuscle)
        
        if hasBothImages {
            return colorScheme == .dark ? .white : .black
        } else if showFront && hasFrontImage || !showFront && hasRearImage {
            return colorScheme == .dark ? .white : .black
        } else {
            return .gray // Incorrect side or no images available
        }
    }
    
    // Determine the default view (front or rear) based on available images
    private func determineDefaultViewSide() {
        let subMuscles = Muscle.getSubMuscles(for: muscle)
        hasFront = subMuscles.contains { SubMuscles.hasFrontImages.contains($0) }
        hasRear = subMuscles.contains { SubMuscles.hasRearImages.contains($0) }
        if !hasFront && showFront {
            showFront = false
        } else if !hasRear && !showFront {
            showFront = true
        }
    }
    
    // Calculate opacity for a sub-muscle based on rest percentage
    private func calculateOpacity(for subMuscle: SubMuscles) -> Double {
        let restPercentage = calculateRestPercentage(for: subMuscle)
        return 1.0 - Double(restPercentage) / 100.0
    }
    
    private func calculateRestPercentage(for subMuscle: SubMuscles) -> Int {
        let now = Date()
        let muscleRestDuration = Double(userData.muscleRestDuration) // in hours
        
        // 1) Gather all (Exercise, Date) pairs from completed workouts,
        //    but only if the exercise has at least one completed set.
        let recentlyWorkedExercises: [(Exercise, Date)] = userData.completedWorkouts.flatMap { workout in
            workout.template.exercises.compactMap { exercise in
                let hasCompletedSets = exercise.setDetails.contains { $0.repsCompleted != nil }
                return hasCompletedSets ? (exercise, workout.date) : nil
            }
        }
        
        // Weighted average accumulators
        var totalWeight = 0.0
        var totalRest   = 0.0
        
        for (exercise, workoutDate) in recentlyWorkedExercises {
            // 2) Calculate hours since this workout
            let hoursSinceWorkout = now.timeIntervalSince(workoutDate) / 3600
            // Skip if beyond your rest window
            guard hoursSinceWorkout <= muscleRestDuration else { continue }
            
            // 3) Check if this subMuscle appears in primary or secondary submuscles
            //    We'll use weight = 1.0 if subMuscle is found in primary,
            //                   = 0.5 if subMuscle only in secondary,
            //                   = 0.0 if not found at all.
            let primarySubs = exercise.primarySubMuscles ?? []
            let secondarySubs = exercise.secondarySubMuscles ?? []
            
            let muscleWeight: Double
            if primarySubs.contains(subMuscle) {
                muscleWeight = 1.0
            } else if secondarySubs.contains(subMuscle) {
                muscleWeight = 0.5
            } else {
                continue // this exercise doesn't target our subMuscle
            }
            
            // 4) For each completed set in this exercise, update rest stats
            let validSets = exercise.setDetails.filter { $0.repsCompleted != nil }
            for _ in validSets {
                // e.g. linear scale from 0–100% rest within muscleRestDuration
                let rawPercent = (hoursSinceWorkout / muscleRestDuration) * 100
                let restPercent = max(0, min(100, Int(rawPercent)))
                
                totalWeight += muscleWeight
                totalRest   += muscleWeight * Double(restPercent)
            }
        }
        
        // 5) If no sets found for this subMuscle, it's fully rested at 100%
        guard totalWeight > 0 else {
            return 100
        }
        
        // 6) Weighted average of rest percentages across all completed sets
        let finalRest = totalRest / totalWeight
        return Int(finalRest)
    }
}

struct RecentlyCompletedSetsView: View {
    var muscle: SubMuscles
    @ObservedObject var userData: UserData
    var onClose: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var recentlyWorkedSets: [ExerciseWithSetDetails] {
        userData.completedWorkouts.flatMap { workout in
            workout.template.exercises.compactMap { exercise in
                let sets = exercise.setDetails.filter { set in
                    (set.repsCompleted ?? 0) > 0
                    && exercise.allSubMuscles?.contains(muscle) == true
                }
                return sets.isEmpty ? nil : ExerciseWithSetDetails(exerciseName: exercise.name, sets: sets, usesWeight: exercise.usesWeight, completionDate: workout.date)
            }
        }.filter { $0.completionDate > Date().addingTimeInterval(-Double(userData.muscleRestDuration) * 60 * 60) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if !recentlyWorkedSets.isEmpty {
                        ForEach(recentlyWorkedSets, id: \.self) { exerciseWithSetDetails in
                            Section(header: VStack(alignment: .leading) {
                                Text(exerciseWithSetDetails.exerciseName)
                                    .font(.headline)
                                    .padding(.vertical, 5)
                                Text("Completed on: \(exerciseWithSetDetails.completionDate, formatter: dateFormatter)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }) {
                                ForEach(exerciseWithSetDetails.sets) { setDetail in
                                    VStack(alignment: .leading) {
                                        Text("Set \(setDetail.setNumber)")
                                            .font(.subheadline)
                                        HStack {
                                            Text("Reps: \(setDetail.repsCompleted ?? 0)")
                                            if exerciseWithSetDetails.usesWeight {
                                                Text("Weight: \(setDetail.weight, specifier: "%.2f") lbs")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    } else {
                        Text("No recently worked sets for this submuscle.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("\(muscle.rawValue)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    // for filtering rest calculation
    struct ExerciseWithSetDetails: Identifiable, Hashable {
        var id = UUID()
        var exerciseName: String
        var sets: [SetDetail]
        var usesWeight: Bool
        var completionDate: Date
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
