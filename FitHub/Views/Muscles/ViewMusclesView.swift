import SwiftUI


struct ViewMusclesView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @ObservedObject var userData: UserData
    @State private var selectedOption: ViewOption = .recovery
    @State private var selectedDay: DaysOfWeek?
    @State var selectedMuscle: Muscle?
    @State private var showFrontView: Bool = true
    @State private var isTapped: Bool = false
    @State private var tappedMuscleImage: String? = nil  // Store the tapped muscle image temporarily
    @State private var showTappedImageOverlay: Bool = false    // Control the display of the overlay
    @State private var restPercentages: [Muscle: Int] = [:]  // State to hold the rest percentages
    
    var body: some View {
        VStack {
            // Picker for recovery and upcoming
            viewPicker
            
            ZStack {
                muscleView()
                muscleButtons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        flipButton
                    }
                }
            }
            
            let size: CGFloat = UIScreen.main.bounds.width * 0.15
            if selectedOption == .upcoming {
                workoutDaysScroller(size: size)
            } else {
                muscleCategoryScroller(size: size)
            }
        }
        .padding()
        .navigationBarTitle("Your Muscles", displayMode: .inline)
        .onAppear(perform: calculateRestPercentages)
        .navigationDestination(item: $selectedMuscle) { muscle in
            DetailedMuscleGroupsView(
                userData: userData,
                showFront: showFrontView, // or $showFrontView if the param is a Binding<Bool>
                muscle: muscle,
                onClose: {
                    selectedMuscle = nil    // popping the stack
                }
            )
        }
    }
    
    private var viewPicker: some View {
        Picker("View Option", selection: $selectedOption) {
            Text("Recovery").tag(ViewOption.recovery)
            Text("Upcoming").tag(ViewOption.upcoming)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    @ViewBuilder private func muscleView() -> some View {
        if selectedOption == .recovery {
            MuscleGroupsView(showFront: $showFrontView, gender: userData.physical.gender, selectedMuscles: getMusclesForSelectedOption(), restPercentages: restPercentages)
            
            if showTappedImageOverlay, let imageName = tappedMuscleImage {
                DirectImageView(imageName: imageName)
            }
        } else {
            SimpleMuscleGroupsView(showFront: $showFrontView, gender: userData.physical.gender, selectedSplit: getSplitCategoriesForSelectedOption())
        }
    }
    
    private var muscleButtons: some View {
        ForEach(musclePositions(front: showFrontView), id: \.id) { muscle in
            muscleButton(for: muscle.muscle, position: muscle.position, size: muscle.size)
        }
    }
    
    // Reusable button function
    private func muscleButton(for category: Muscle, position: CGPoint, size: CGSize) -> some View {
        Button(action: { muscleTapped(category) }) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: size.width, height: size.height)
        }
        .position(position)
    }
    
    private var flipButton: some View {
        FloatingButton(image: "arrow.2.circlepath", action: { showFrontView.toggle() })
            .padding(.trailing)
            .padding(.bottom)
    }
    
    @ViewBuilder private func workoutDaysScroller(size: CGFloat) -> some View {
        Divider()
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(upcomingWorkoutDays, id: \.self) { day in
                    Button {
                        withAnimation {
                            selectedDay = day
                            print("Selected day: \(day)")
                        }
                    } label: {
                        Text(day.rawValue)
                            .frame(height: size)
                            .frame(minWidth: 60)              // ensure a minimum tappable width
                            .padding(.horizontal)                        // give it some vertical/horizontal padding
                            .background(day == selectedDay ? Color.blue : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())        // extend hit‐area to the full rectangle
                    }
                }
            }
        }
    }
    
    @ViewBuilder private func muscleCategoryScroller(size: CGFloat) -> some View {
        Divider()
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(Muscle.allCases.filter { $0.isVisible }, id: \.self) { category in
                    Button(action: { muscleTapped(category) }) {
                        HStack {
                            Muscle.getButtonForCategory(category, gender: userData.physical.gender)
                                .resizable()
                                .scaledToFit()
                                .frame(width: size, height: size)
                            VStack(alignment: .leading) {
                                Text(category.simpleName)
                                    .frame(maxWidth: size * 1.5)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .padding(.bottom, -5)
                                    .minimumScaleFactor(0.6)
                                Text("\(restPercentages[category] ?? 100)%")
                                    .font(.subheadline)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .padding(5)
                                    .background(Color.gray.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
        }
    }
    
    struct MuscleHitInfo: Identifiable {
        let muscle: Muscle
        let position: CGPoint
        let size: CGSize
        let side: Side?
        
        /// Stable ID (muscle + side) so duplicate L/R entries don’t collide in ForEach.
        var id: String { muscle.rawValue + (side?.rawValue ?? "") }
        
        enum Side: String { case left = "L", right = "R", mid = "M" }
    }

    // Muscle positions for front and rear views
    func musclePositions(front: Bool) -> [MuscleHitInfo] {
        front ? muscleHitInfosFront : muscleHitInfosBack
    }

    
    // MARK: - FRONT hit regions
    private let muscleHitInfosFront: [MuscleHitInfo] = [
        .init(muscle: .trapezius,       position: .init(x: 178.5, y: 112),  size: .init(width: 60,  height: 20),  side: .mid),
        .init(muscle: .deltoids,        position: .init(x: 122,   y: 145),  size: .init(width: 25,  height: 35),  side: .left),
        .init(muscle: .deltoids,        position: .init(x: 236,   y: 145),  size: .init(width: 25,  height: 35),  side: .right),
        .init(muscle: .pectorals,       position: .init(x: 178.5, y: 149),  size: .init(width: 85,  height: 45),  side: .mid),
        .init(muscle: .abdominals,      position: .init(x: 178.5, y: 214),  size: .init(width: 50,  height: 85),  side: .mid),
        .init(muscle: .biceps,          position: .init(x: 127,   y: 185),  size: .init(width: 18,  height: 50),  side: .left),
        .init(muscle: .biceps,          position: .init(x: 231,   y: 185),  size: .init(width: 18,  height: 50),  side: .right),
        .init(muscle: .triceps,         position: .init(x: 110,   y: 190),  size: .init(width: 18,  height: 50),  side: .left),
        .init(muscle: .triceps,         position: .init(x: 245,   y: 190),  size: .init(width: 18,  height: 50),  side: .right),
        .init(muscle: .forearms,        position: .init(x: 120,   y: 255),  size: .init(width: 22,  height: 80),  side: .left),
        .init(muscle: .forearms,        position: .init(x: 236,   y: 255),  size: .init(width: 22,  height: 80),  side: .right),
        .init(muscle: .quadriceps,      position: .init(x: 180,   y: 310),  size: .init(width: 80,  height: 100), side: .mid),
        .init(muscle: .calves,          position: .init(x: 180,   y: 430),  size: .init(width: 70,  height: 80),  side: .mid)
    ]

    // MARK: - BACK hit regions
    private let muscleHitInfosBack: [MuscleHitInfo] = [
        .init(muscle: .trapezius,       position: .init(x: 179,   y: 132),  size: .init(width: 62,  height: 70),  side: .mid),
        .init(muscle: .deltoids,        position: .init(x: 122,   y: 145),  size: .init(width: 25,  height: 35),  side: .left),
        .init(muscle: .deltoids,        position: .init(x: 236,   y: 145),  size: .init(width: 25,  height: 35),  side: .right),
        .init(muscle: .triceps,         position: .init(x: 115,   y: 190),  size: .init(width: 35,  height: 50),  side: .left),
        .init(muscle: .triceps,         position: .init(x: 240,   y: 190),  size: .init(width: 35,  height: 50),  side: .right),
        .init(muscle: .forearms,        position: .init(x: 120,   y: 255),  size: .init(width: 22,  height: 80),  side: .left),
        .init(muscle: .forearms,        position: .init(x: 237,   y: 255),  size: .init(width: 22,  height: 80),  side: .right),
        .init(muscle: .latissimusDorsi, position: .init(x: 151,   y: 185),  size: .init(width: 30,  height: 50),  side: .left),
        .init(muscle: .latissimusDorsi, position: .init(x: 205,   y: 185),  size: .init(width: 30,  height: 50),  side: .right),
        .init(muscle: .erectorSpinae,   position: .init(x: 178.5, y: 220),  size: .init(width: 60,  height: 20),  side: .mid),
        .init(muscle: .gluteus,         position: .init(x: 180,   y: 262),  size: .init(width: 75,  height: 60),  side: .mid),
        .init(muscle: .hamstrings,      position: .init(x: 180,   y: 330),  size: .init(width: 75,  height: 70),  side: .mid),
        .init(muscle: .calves,          position: .init(x: 180,   y: 415),  size: .init(width: 70,  height: 80),  side: .mid)
    ]
    
    // Options for the picker
    private enum ViewOption { case recovery, upcoming }
    
    private func getSplitCategoriesForSelectedOption() -> [SplitCategory] {
        switch selectedOption {
        case .recovery: return [] // Not relevant for Recovery
        case .upcoming: guard let selectedDay = selectedDay else { return [] }
            return getSplitCategoriesForSelectedDay(selectedDay)
        }
    }
    
    private func getSplitCategoriesForSelectedDay(_ selectedDay: DaysOfWeek) -> [SplitCategory] {
        // Filter templates by selected day
        let selectedDayTemplates = userData.workoutPlans.trainerTemplates.filter { template in
            guard let templateDate = template.date else { return false }
            let templateDay = CalendarUtility.shared.weekday(from: templateDate)
            return DaysOfWeek(weekday: templateDay) == selectedDay
        }
        
        // Collect split categories from templates
        let categories = selectedDayTemplates.flatMap { $0.categories }
        return Array(Set(categories)) // Ensure unique categories
    }
    
    // Get muscles for the selected option
    private func getMusclesForSelectedOption() -> [Muscle] {
        switch selectedOption {
        case .recovery: return getRecentlyWorkedMuscles()
        case .upcoming: guard let selectedDay = selectedDay else { return [] }
            return getUpcomingMusclesForSelectedDay(selectedDay)
        }
    }
    
    private func getRecentlyWorkedMuscles() -> [Muscle] {
        if let twoDaysAgo = CalendarUtility.shared.hoursAgo(userData.settings.muscleRestDuration) {
            let recentlyWorkedCategories = userData.workoutPlans.completedWorkouts
                .filter { $0.date > twoDaysAgo }
                .flatMap { workout in
                    workout.template.exercises.flatMap { exercise -> [Muscle] in
                        var involvedMuscles: [Muscle] = []
                        involvedMuscles.append(contentsOf: exercise.primaryMuscles)
                        involvedMuscles.append(contentsOf: exercise.secondaryMuscles)
                        
                        return involvedMuscles
                    }
                }
            
            return Array(Set(recentlyWorkedCategories))
        }
        return []
    }
    
    // Update the muscleTapped function
    private func muscleTapped(_ muscle: Muscle) {
        print("Tapped muscle: \(muscle.rawValue)")
        // Display the tapped muscle image
        tappedMuscleImage = AssetPath.getTapImage(muscle: muscle, showFrontView: showFrontView, gender: userData.physical.gender)
        showTappedImageOverlay = true
        selectedMuscle = muscle
        
        // Hide the overlay after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tappedMuscleImage = nil
            showTappedImageOverlay = false
            print("Showing detail view for: \(muscle.rawValue)")
        }
    }
    
    private func getUpcomingMusclesForSelectedDay(_ selectedDay: DaysOfWeek) -> [Muscle] {        
        // Filter trainer templates that have a valid date and match the selected day
        let selectedDayTemplates = userData.workoutPlans.trainerTemplates.filter { template in
            guard let templateDate = template.date else { return false }
            let templateDay = CalendarUtility.shared.weekday(from: templateDate)
            return DaysOfWeek(weekday: templateDay) == selectedDay
        }
                
        let categories = selectedDayTemplates.flatMap { $0.categories } // Collect all categories from the selected templates
        let muscles = categories.flatMap { SplitCategory.muscles[$0] ?? [] } // Map categories to their respective muscles
        
        // Return unique muscles
        return Array(Set(muscles))
    }
    
    private var upcomingWorkoutDays: [DaysOfWeek] {
        // Filter planned workout dates to only include today and future dates
        let upcomingDates = userData.getPlannedWorkoutDates().filter { plannedDate in
            if let endOfDay = CalendarUtility.shared.date(bySettingHour: 23, minute: 59, second: 59, of: plannedDate) {
                return endOfDay >= Date()
            }
            return false
        }
        
        // Map the upcoming dates to DaysOfWeek
        let upcomingDays = upcomingDates.compactMap { plannedDate in
            CalendarUtility.shared.weekday(from: plannedDate)
        }.compactMap { weekday in DaysOfWeek(weekday: weekday) }
        
        return upcomingDays
    }
    
    private func calculateRestPercentages() {
        let now         = Date()
        let windowHours = max(1.0, Double(userData.settings.muscleRestDuration)) // avoid /0

        // 1) Only workouts in [0, window]
        let recent = userData.workoutPlans.completedWorkouts.filter {
            let h = now.timeIntervalSince($0.date) / 3600.0
            return h >= 0 && h <= windowHours
        }

        // 2) Accumulate (Σ weight×pct, Σ weight)
        var buckets: [Muscle:(rest: Double, weight: Double)] = [:]

        for workout in recent {
            let hoursSince = now.timeIntervalSince(workout.date) / 3600.0
            let ratio = hoursSince / windowHours
            let pctRest = max(0.0, min(1.0, ratio)) * 100.0   // clamp to 0…100

            for exercise in workout.template.exercises {

                // ✅ Count completed sets under the new SetMetric model
                let setCount = exercise.setDetails.filter { sd in
                    guard let c = sd.completed else { return false }
                    switch c {
                    case .reps(let r):     return r > 0
                    case .hold(let span):  return span.inSeconds > 0
                    }
                }.count
                guard setCount > 0 else { continue }

                for engage in exercise.muscles {
                    let base   = engage.engagementPercentage / 100.0
                    let ps     = engage.isPrimary ? 1.0 : 0.5
                    let weight = base * ps * Double(setCount)

                    var bucket = buckets[engage.muscleWorked] ?? (0, 0)
                    bucket.rest   += weight * pctRest
                    bucket.weight += weight
                    buckets[engage.muscleWorked] = bucket
                }
            }
        }

        // 3) Normalize, clamp to 0…100; 100 if untouched
        restPercentages = Dictionary(uniqueKeysWithValues:
            Muscle.allCases.map { m in
                let b = buckets[m] ?? (0, 0)
                let pct = b.weight > 0 ? (b.rest / b.weight).rounded() : 100.0
                return (m, Int(max(0.0, min(100.0, pct))))
            }
        )
    }
}


// must stay in original order for mapping to proper days in this view
extension DaysOfWeek {
    init?(weekday: Int) {
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: return nil
        }
    }
}




