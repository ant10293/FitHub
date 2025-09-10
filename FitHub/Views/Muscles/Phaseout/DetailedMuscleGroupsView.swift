//
//  DetailedMuscleGroupsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/21/24.
//
/*
import SwiftUI
import Foundation


struct DetailedMuscleGroupsView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @ObservedObject var userData: UserData
    @State var showFront: Bool
    @State private var hasFront: Bool = false
    @State private var hasRear: Bool = false
    @State private var selectedSubMuscle: SubMuscles? = nil
    @State private var selectedView: ViewOptions = .recovery
    @State private var restPercentages: [SubMuscles: Int] = [:]  // State to hold the rest percentages
    var muscle: Muscle
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                muscleView()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        flipButton()
                    }
                }
            }
            
            viewPicker
            subMuscleList
        }
        .padding()
        .navigationBarTitle(nameHeader, displayMode: .inline)
        .onAppear(perform: determineDefaultViewSide)
        .sheet(item: $selectedSubMuscle, onDismiss: { selectedSubMuscle = nil }) { subMuscle in
            RecentlyCompletedSetsView(userData: userData, muscle: subMuscle)
        }
    }
    
    private var nameHeader: Text {
        return (
        Text(muscle.simpleName)
        + Text(muscle.rawValue != muscle.simpleName ? " (\(muscle.rawValue))" : "")
        )
    }

    @ViewBuilder private func muscleView() -> some View {
        if showFront {
            if Muscle.hasFrontImages.contains(muscle) {
                ImageStack(front: true)
            }
        } else {
            if Muscle.hasRearImages.contains(muscle) {
                ImageStack(front: false)
            }
        }
    }
    
    @ViewBuilder private func ImageStack(front: Bool) -> some View {
        if selectedView == .recovery {
            DirectImageView(imageName: muscle.blankImage(front: front, gender: userData.physical.gender))
                .opacity(1.0)
            ForEach(Muscle.getSubMuscles(for: muscle), id: \.self) { subMuscle in
                ForEach(AssetPath.getDetailedMuscleImages(category: subMuscle, gender: userData.physical.gender).filter { $0.contains(front ? "Front" : "Rear") }, id: \.self) { imagePath in
                    DirectImageView(imageName: imagePath)
                        .opacity(calculateOpacity(for: subMuscle))
                        .onTapGesture {
                            selectedSubMuscle = subMuscle
                        }
                }
            }
        } else {
            DirectImageView(imageName: muscle.coloredImage(front: front, gender: userData.physical.gender))
                .opacity(1.0)
        }
    }
    
    @ViewBuilder private func flipButton() -> some View {
        if hasFront && hasRear { FloatingButton(image: "arrow.2.circlepath", action: { showFront.toggle() }) }
    }
    
    private var viewPicker: some View {
        Picker("Select View", selection: $selectedView) {
            ForEach(ViewOptions.allCases, id: \.self) { view in
                Text(view.rawValue).tag(view)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var subMuscleList: some View {
        List {
            Section {
                ForEach(Muscle.getSubMuscles(for: muscle), id: \.self) { subMuscle in
                    HStack {
                        let hasImage = !SubMuscles.hasNoImages.contains(subMuscle)
                        VStack(alignment: .leading) {
                            HStack {
                                if !hasImage {
                                    Text(subMuscle.simpleName)
                                        .foregroundStyle(.gray)
                                    + Text(" (Deep)") // we will remove this upon color coding the visible muscles
                                        .fontWeight(.light)
                                } else {
                                    Text(subMuscle.simpleName)
                                        .foregroundStyle(determineTextColor(for: subMuscle))
                                }
                                
                                Spacer()

                                if selectedView == .recovery {
                                    Text("\(restPercentages[subMuscle] ?? 100)%")
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.gray)
                                } else {
                                    if hasImage {
                                        RoundedRectangle(cornerRadius: 2)
                                         .fill(subMuscle.fillColor)
                                         .frame(width: 30, height: 12)
                                    }
                                }
                            }
                            
                            if !subMuscle.rawValue.contains(subMuscle.simpleName) {
                                Text(subMuscle.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .italic(true)
                            }
                            if let note = subMuscle.note {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSubMuscle = subMuscle
                    }
                }
            } header: {
                Text(selectedView == .recovery ? "Select submuscle to view recent sets" : "")
            }
        }
    }
    
    private enum ViewOptions: String, CaseIterable {
        case recovery = "Recovery"
        case identification = "Identification"
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
        if !hasFront && showFront { showFront = false }
        else if !hasRear && !showFront { showFront = true }
    }
    
    // Calculate opacity for a sub-muscle based on rest percentage
    private func calculateOpacity(for subMuscle: SubMuscles) -> Double {
        return 1.0 - Double(restPercentages[subMuscle] ?? 100) / 100.0
    }
    
    // MARK: - Sub-muscle rest % (single pass) -------------------------------
    private func calculateRestPercentages() {
        let now         = Date()
        let windowHours = max(1.0, Double(userData.settings.muscleRestDuration)) // avoid divide-by-zero

        // temp buckets keyed by sub-muscle: (Σ weight×pct , Σ weight)
        var buckets: [SubMuscles: (rest: Double, weight: Double)] = [:]

        // 1️⃣ recent workouts only within [0, windowHours]
        let recent = userData.workoutPlans.completedWorkouts.filter {
            let h = now.timeIntervalSince($0.date) / 3600.0
            return h >= 0 && h <= windowHours
        }

        for workout in recent {
            let hoursSince = now.timeIntervalSince(workout.date) / 3600.0
            let ratio      = hoursSince / windowHours
            let pctRest    = max(0.0, min(1.0, ratio)) * 100.0   // clamp 0…100

            for exercise in workout.template.exercises {
                // ✅ Count completed sets under the new SetMetric model
                let sets = exercise.setDetails.filter { sd in
                    guard let c = sd.completed else { return false }
                    switch c {
                    case .reps(let r):     return r > 0
                    case .hold(let span):  return span.inSeconds > 0
                    }
                }.count
                guard sets > 0 else { continue }

                let primarySubs   = Set(exercise.primarySubMuscles ?? [])
                let secondarySubs = Set(exercise.secondarySubMuscles ?? [])

                for engage in exercise.muscles {
                    guard let subs = engage.submusclesWorked else { continue }

                    for subEng in subs {
                        let sub = subEng.submuscleWorked

                        // primary/secondary factor
                        let psFactor: Double
                        if      primarySubs.contains(sub)   { psFactor = 1.0 }
                        else if secondarySubs.contains(sub) { psFactor = 0.5 }
                        else { continue }

                        // engagement% × primary/secondary × set count
                        let weight = (Double(subEng.engagementPercentage) / 100.0) * psFactor * Double(sets)

                        var bucket = buckets[sub] ?? (0, 0)
                        bucket.rest   += weight * pctRest
                        bucket.weight += weight
                        buckets[sub]   = bucket
                    }
                }
            }
        }

        // 2️⃣ convert buckets → 0–100 ints; default 100 when untouched, clamp for safety
        restPercentages = Dictionary(
            uniqueKeysWithValues:
                Muscle.getSubMuscles(for: muscle).map { sub in
                    let bucket = buckets[sub] ?? (0, 0)
                    let raw = bucket.weight > 0 ? (bucket.rest / bucket.weight).rounded() : 100.0
                    let clamped = max(0.0, min(100.0, raw))
                    return (sub, Int(clamped))
                }
        )
    }
}


extension SubMuscles {
    /// Returns the fill color for this submuscle
    var fillColor: Color {
        if SubMuscles.colorRed.contains(self)    { return .red }
        if SubMuscles.colorGreen.contains(self)  { return .green }
        if SubMuscles.colorBlue.contains(self)   { return .blue }
        if SubMuscles.colorYellow.contains(self) { return .yellow }
        return .gray  // fallback, if you need one
    }
}

//  Muscle+Images.swift
//  FitHub
extension Muscle {
    /// kebab-cased file name fragment (“latissimus-dorsi”)
    private var slug: String {
        rawValue.replacingOccurrences(of: " ", with: "-").lowercased()
    }

    /// `…/Blank/Front/<slug>`
    func blankImage(front: Bool, gender: Gender) -> String {
        AssetPath.getImagePath(
            for: .detailedMuscle,
            isfront: front,
            // the API has mutually-exclusive flags
            isBlank: true,
            isColored: false,
            gender: gender
        ) + slug
    }

    /// `…/Color/Front/<slug>`
    func coloredImage(front: Bool, gender: Gender) -> String {
        AssetPath.getImagePath(
            for: .detailedMuscle,
            isfront: front,
            isBlank: false,
            isColored: true,
            gender: gender
        ) + slug
    }
}
*/
