import SwiftUI


struct ViewMusclesView: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @ObservedObject var userData: UserData
    @State private var selectedOption: ViewOption = .recovery
    @State private var selectedDay: daysOfWeek?
    @State private var showFrontView: Bool = true
    @State private var isTapped: Bool = false
    @State var selectedMuscle: Muscle?
    @State private var showingDetailView = false
    @State private var tappedMuscleImage: String? = nil  // Store the tapped muscle image temporarily
    @State private var showTappedImageOverlay = false    // Control the display of the overlay
    @State private var restPercentages: [Muscle: Int] = [:]  // State to hold the rest percentages
    
    var body: some View {
        VStack {
            // Picker for recovery and upcoming
            viewPicker
            
            // Muscle groups view
            Spacer(minLength: 90)
            GeometryReader { geometry in
                ZStack {
                    muscleView(width: geometry.size.width)
                    muscleButtons()
                    flipButton
                }
                .frame(height: 350)
            }
            
            workoutDaysScroller()
            muscleCategoryScroller()
            Spacer()
        }
        .padding()
        .navigationBarTitle("Your Muscles", displayMode: .inline)
        .onAppear(perform: calculateRestPercentages)
        .navigationDestination(isPresented: $showingDetailView) {
            if let muscle = selectedMuscle {
                DetailedMuscleGroupsView(userData: userData, showFront: showFrontView, muscle: muscle, onClose: {
                    selectedMuscle = nil
                    showingDetailView = false
                })
            }
        }
    }
    
    private var viewPicker: some View {
        Picker("View Option", selection: $selectedOption) {
            Text("Recovery").tag(ViewOption.recovery)
            Text("Upcoming").tag(ViewOption.upcoming)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    @ViewBuilder private func muscleView(width: CGFloat) -> some View {
        if selectedOption == .recovery {
            MuscleGroupsView(showFront: $showFrontView, gender: userData.physical.gender, selectedMuscles: getMusclesForSelectedOption(), restPercentages: restPercentages)
                .frame(width: width, height: 550)
                .centerHorizontally()
            
            if showTappedImageOverlay, let imageName = tappedMuscleImage {
                DirectImageView(imageName: imageName)
                    .frame(width: width, height: 550)
                    .centerHorizontally()
            }
        } else {
            SimpleMuscleGroupsView(showFront: $showFrontView, gender: userData.physical.gender, selectedSplit: getSplitCategoriesForSelectedOption())
                .frame(width: width, height: 550)
                .centerHorizontally()
        }
    }
    
    @ViewBuilder private func muscleButtons() -> some View {
        ForEach(musclePositions(front: showFrontView), id: \.id) { muscle in
            muscleButton(for: muscle.category, position: muscle.position, size: muscle.size)
        }
    }
    
    // Reusable button function
    func muscleButton(for category: Muscle, position: CGPoint, size: CGSize) -> some View {
        Button(action: { muscleTapped(category) }) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: size.width, height: size.height)
        }
        .position(position)
    }
    
    private var flipButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showFrontView.toggle()
                }) {
                    Image(systemName: "arrow.2.circlepath")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 50)
        }
    }
    
    @ViewBuilder private func workoutDaysScroller() -> some View {
        if selectedOption == .upcoming {
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
                                .frame(minWidth: 60)              // ensure a minimum tappable width
                                .padding()                        // give it some vertical/horizontal padding
                                .background(day == selectedDay ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())        // extend hit‐area to the full rectangle
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private func muscleCategoryScroller() -> some View {
        if selectedOption == .recovery {
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    ForEach(Muscle.allCases.filter { $0.isVisible }, id: \.self) { category in
                        Button(action: { muscleTapped(category) }) {
                            HStack {
                                Muscle.getButtonForCategory(category, gender: userData.physical.gender)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(category.simpleName)
                                        .frame(maxWidth: 75)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .padding(.bottom, -5)
                                        .minimumScaleFactor(0.6)
                                    Text("\(restPercentages[category] ?? 100)%")
                                        .font(.subheadline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
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
    }
    
    // Muscle positions for front and rear views
    func musclePositions(front: Bool) -> [(id: UUID, category: Muscle, position: CGPoint, size: CGSize)] {
        if front {
            return [
                (id: UUID(), category: .trapezius, position: CGPoint(x: 178.5, y: 112), size: CGSize(width: 60, height: 20)),
                (id: UUID(), category: .deltoids, position: CGPoint(x: 122, y: 145), size: CGSize(width: 25, height: 35)),
                (id: UUID(), category: .deltoids, position: CGPoint(x: 236, y: 145), size: CGSize(width: 25, height: 35)),
                (id: UUID(), category: .pectorals, position: CGPoint(x: 178.5, y: 149), size: CGSize(width: 85, height: 45)),
                (id: UUID(), category: .abdominals, position: CGPoint(x: 178.5, y: 214), size: CGSize(width: 50, height: 85)),
                (id: UUID(), category: .biceps, position: CGPoint(x: 127, y: 185), size: CGSize(width: 18, height: 50)),
                (id: UUID(), category: .biceps, position: CGPoint(x: 231, y: 185), size: CGSize(width: 18, height: 50)),
                (id: UUID(), category: .triceps, position: CGPoint(x: 110, y: 190), size: CGSize(width: 18, height: 50)),
                (id: UUID(), category: .triceps, position: CGPoint(x: 245, y: 190), size: CGSize(width: 18, height: 50)),
                (id: UUID(), category: .forearms, position: CGPoint(x: 120, y: 255), size: CGSize(width: 22, height: 80)),
                (id: UUID(), category: .forearms, position: CGPoint(x: 236, y: 255), size: CGSize(width: 22, height: 80)),
                (id: UUID(), category: .quadriceps, position: CGPoint(x: 180, y: 310), size: CGSize(width: 80, height: 100)),
                (id: UUID(), category: .calves, position: CGPoint(x: 180, y: 430), size: CGSize(width: 70, height: 80))
            ]
        } else {
            return [
                (id: UUID(), category: .trapezius, position: CGPoint(x: 179, y: 132), size: CGSize(width: 62, height: 70)),
                (id: UUID(), category: .deltoids, position: CGPoint(x: 122, y: 145), size: CGSize(width: 25, height: 35)),
                (id: UUID(), category: .deltoids, position: CGPoint(x: 236, y: 145), size: CGSize(width: 25, height: 35)),
                (id: UUID(), category: .triceps, position: CGPoint(x: 115, y: 190), size: CGSize(width: 35, height: 50)),
                (id: UUID(), category: .triceps, position: CGPoint(x: 240, y: 190), size: CGSize(width: 35, height: 50)),
                (id: UUID(), category: .forearms, position: CGPoint(x: 120, y: 255), size: CGSize(width: 22, height: 80)),
                (id: UUID(), category: .forearms, position: CGPoint(x: 237, y: 255), size: CGSize(width: 22, height: 80)),
                (id: UUID(), category: .latissimusDorsi, position: CGPoint(x: 151, y: 185), size: CGSize(width: 30, height: 50)),
                (id: UUID(), category: .latissimusDorsi, position: CGPoint(x: 205, y: 185), size: CGSize(width: 30, height: 50)),
                (id: UUID(), category: .erectorSpinae, position: CGPoint(x: 178.5, y: 220), size: CGSize(width: 60, height: 20)),
                (id: UUID(), category: .gluteus, position: CGPoint(x: 180, y: 262), size: CGSize(width: 75, height: 60)),
                (id: UUID(), category: .hamstrings, position: CGPoint(x: 180, y: 330), size: CGSize(width: 75, height: 70)),
                (id: UUID(), category: .calves, position: CGPoint(x: 180, y: 415), size: CGSize(width: 70, height: 80))
            ]
        }
    }
    
    // Options for the picker
    enum ViewOption { case recovery, upcoming }
    
    private func getSplitCategoriesForSelectedOption() -> [SplitCategory] {
        switch selectedOption {
        case .recovery: return [] // Not relevant for Recovery
        case .upcoming: guard let selectedDay = selectedDay else { return [] }
            return getSplitCategoriesForSelectedDay(selectedDay)
        }
    }
    
    private func getSplitCategoriesForSelectedDay(_ selectedDay: daysOfWeek) -> [SplitCategory] {
        let calendar = Calendar.current
        
        // Filter templates by selected day
        let selectedDayTemplates = userData.workoutPlans.trainerTemplates.filter { template in
            guard let templateDate = template.date else { return false }
            let templateDay = calendar.component(.weekday, from: templateDate)
            return daysOfWeek(weekday: templateDay) == selectedDay
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
        let twoDaysAgo = Calendar.current.date(byAdding: .hour, value: -userData.settings.muscleRestDuration, to: Date())!
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
            showingDetailView = true
            print("Showing detail view for: \(muscle.rawValue)")
        }
    }
    
    private func getUpcomingMusclesForSelectedDay(_ selectedDay: daysOfWeek) -> [Muscle] {        
        let calendar = Calendar.current
        // Filter trainer templates that have a valid date and match the selected day
        let selectedDayTemplates = userData.workoutPlans.trainerTemplates.filter { template in
            guard let templateDate = template.date else { return false }
            let templateDay = calendar.component(.weekday, from: templateDate)
            return daysOfWeek(weekday: templateDay) == selectedDay
        }
                
        let categories = selectedDayTemplates.flatMap { $0.categories } // Collect all categories from the selected templates
        let muscles = categories.flatMap { SplitCategory.muscles[$0] ?? [] } // Map categories to their respective muscles
        
        // Return unique muscles
        return Array(Set(muscles))
    }
    
    private var upcomingWorkoutDays: [daysOfWeek] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Filter planned workout dates to only include today and future dates
        let upcomingDates = userData.getPlannedWorkoutDates().filter { plannedDate in
            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: plannedDate) {
                return endOfDay >= currentDate
            }
            return false
        }
        
        // Map the upcoming dates to daysOfWeek
        let upcomingDays = upcomingDates.compactMap { plannedDate in
            calendar.dateComponents([.weekday], from: plannedDate).weekday
        }.compactMap { weekday in daysOfWeek(weekday: weekday) }
        
        return upcomingDays
    }
    
    private func calculateRestPercentages() {
        let now         = Date()
        let windowHours = Double(userData.settings.muscleRestDuration)

        // temp buckets: (Σ weight × pct , Σ weight)
        var buckets: [Muscle:(rest: Double, weight: Double)] = [:]

        // ── 1. Filter recent workouts once ───────────────────────────────
        let recent = userData.workoutPlans.completedWorkouts
            .filter { now.timeIntervalSince($0.date) / 3600 <= windowHours }

        // ── 2. Single scan over workouts / exercises / sets ──────────────
        for workout in recent {
            let hoursSince = now.timeIntervalSince(workout.date) / 3600
            let pctRest    = min(1, hoursSince / windowHours) * 100   // linear 0‒100

            for exercise in workout.template.exercises {
                let setCount = exercise.setDetails
                                   .filter { $0.repsCompleted != nil }.count
                guard setCount > 0 else { continue }

                for engage in exercise.muscles {
                    let base   = engage.engagementPercentage / 100       // 0‒1
                    let ps     = engage.isPrimary ? 1.0 : 0.5
                    let weight = base * ps * Double(setCount)

                    var bucket = buckets[engage.muscleWorked] ?? (0,0)
                    bucket.rest   += weight * pctRest
                    bucket.weight += weight
                    buckets[engage.muscleWorked] = bucket
                }
            }
        }

        // ── 3. Convert buckets → 0‒100 ints; default 100 if untouched ────
        restPercentages = Dictionary(
            uniqueKeysWithValues:
                Muscle.allCases.map { muscle in
                    let bucket = buckets[muscle] ?? (0,0)
                    let pct = bucket.weight > 0
                            ? Int((bucket.rest / bucket.weight).rounded())
                            : 100
                    return (muscle, pct)
                }
        )
    }
}


// must stay in original order for mapping to proper days in this view
extension daysOfWeek {
    init?(weekday: Int) {
        switch weekday {
        case 1:
            self = .sunday
        case 2:
            self = .monday
        case 3:
            self = .tuesday
        case 4:
            self = .wednesday
        case 5:
            self = .thursday
        case 6:
            self = .friday
        case 7:
            self = .saturday
        default:
            return nil
        }
    }
}




