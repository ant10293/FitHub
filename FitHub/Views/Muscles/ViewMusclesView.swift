import SwiftUI

struct MuscleAnnotation: View {
    var name: String
    var percentage: Int
    var position: CGPoint
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    
    var body: some View {
        VStack {
            Text("\(name)")
                .font(.caption)
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .cornerRadius(5)
            Text("\(percentage)%")
                .font(.caption)
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .cornerRadius(5)
        }
        .position(position)
    }
}


struct ViewMusclesView: View {
    @ObservedObject var userData: UserData
    @State private var selectedOption: ViewOption = .recovery
    @State private var selectedDay: daysOfWeek?
    @State private var showFrontView: Bool = true
    @State private var isTapped: Bool = false
    @State var selectedMuscle: Muscle?
    @State private var showingDetailView = false
    @State private var tappedMuscleImage: String? = nil  // Store the tapped muscle image temporarily
    @State private var showTappedImageOverlay = false    // Control the display of the overlay
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @State private var restPercentages: [Muscle: Int] = [:]  // State to hold the rest percentages
    
    var body: some View {
        VStack {
            // Picker for recovery and upcoming
            Picker("View Option", selection: $selectedOption) {
                Text("Recovery").tag(ViewOption.recovery)
                Text("Upcoming").tag(ViewOption.upcoming)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Muscle groups view
            Spacer(minLength: 90)
            GeometryReader { geometry in
                ZStack {
                    if selectedOption == .recovery {
                        MuscleGroupsView(userData: userData, selectedMuscles: getMusclesForSelectedOption(), showFront: $showFrontView, restPercentages: restPercentages)
                            .frame(width: geometry.size.width, height: 550)
                            .centerHorizontally()
                        
                        if showTappedImageOverlay, let imageName = tappedMuscleImage {
                            DirectImageView(imageName: imageName)
                                .frame(width: geometry.size.width, height: 550)
                                .centerHorizontally()
                        }
                        
                    } else {
                        SimpleMuscleGroupsView(selectedSplit: getSplitCategoriesForSelectedOption(), showFront: $showFrontView)
                            .frame(width: geometry.size.width, height: 550)
                            .centerHorizontally()
                    }
                    Group {
                        if showFrontView {
                            ForEach(musclePositions(front: true), id: \.id) { muscle in
                                muscleButton(for: muscle.category, position: muscle.position, size: muscle.size)
                            }
                        } else {
                            ForEach(musclePositions(front: false), id: \.id) { muscle in
                                muscleButton(for: muscle.category, position: muscle.position, size: muscle.size)
                            }
                        }
                    }
                    
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
                .frame(height: 350)
            }
            
            
            if selectedOption == .upcoming {
                Divider()
                // Selectable days
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        ForEach(upcomingWorkoutDays, id: \.self) { day in
                            Button(day.rawValue) {
                                withAnimation {
                                    selectedDay = day
                                    print("Selected day: \(day)")
                                }
                            }
                            .padding()
                            .frame(minWidth: 80) // Minimum width for each day button
                            .background(day == selectedDay ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            Spacer()
            
            if selectedOption == .recovery {
                Divider()
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        ForEach(Muscle.allCases.filter { ![.all, .scapularStabilizers, .hipFlexors].contains($0) }, id: \.self) { category in
                            Button(action: {
                                muscleTapped(category)
                            }) {
                                HStack {
                                    Muscle.getButtonForCategory(category)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                    VStack(alignment: .leading) {
                                        // Text(category.shortName)
                                        Text(category.simpleName)
                                            .frame(maxWidth: 75)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                            .padding(.bottom, -5)
                                            .minimumScaleFactor(0.6)
                                        Text("\(calculateRestPercentage(for: category))%")
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
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Your Muscles")
        .navigationDestination(isPresented: $showingDetailView) {
            if let muscle = selectedMuscle {
                DetailedMuscleGroupsView(muscle: muscle, showFront: showFrontView, onClose: {
                    selectedMuscle = nil
                    showingDetailView = false
                })
            }
        }
        .onAppear {
            calculateRestPercentages()
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
    enum ViewOption {
        case recovery, upcoming
    }
    
    private func getSplitCategoriesForSelectedOption() -> [SplitCategory] {
        switch selectedOption {
        case .recovery:
            return [] // Not relevant for Recovery
        case .upcoming:
            guard let selectedDay = selectedDay else {
                print("No day selected.")
                return []
            }
            return getSplitCategoriesForSelectedDay(selectedDay)
        }
    }
    
    private func getSplitCategoriesForSelectedDay(_ selectedDay: daysOfWeek) -> [SplitCategory] {
        let calendar = Calendar.current
        
        // Filter templates by selected day
        let selectedDayTemplates = userData.trainerTemplates.filter { template in
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
        case .recovery:
            return getRecentlyWorkedMuscles()
        case .upcoming:
            // Logic to fetch upcoming muscles
            guard let selectedDay = selectedDay else {
                print("No day selected.")
                return []
            }
            return getUpcomingMusclesForSelectedDay(selectedDay)
        }
    }
    
    private func getRecentlyWorkedMuscles() -> [Muscle] {
        let twoDaysAgo = Calendar.current.date(byAdding: .hour, value: -userData.muscleRestDuration, to: Date())!
        
        let recentlyWorkedCategories = userData.completedWorkouts
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
        tappedMuscleImage = Muscle.getTapForMuscle(muscle, showFrontView: showFrontView) // Function to map muscle to image
        showTappedImageOverlay = true
        selectedMuscle = muscle
        
        // Hide the overlay after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tappedMuscleImage = nil
            showTappedImageOverlay = false
            
            //detailedMuscleGroupImages = DetailedMuscleGroupImage.mapToDetailedMuscleGroupImages([muscle])
            showingDetailView = true
            print("Showing detail view for: \(muscle.rawValue)")
        }
    }
    
    private func getUpcomingMusclesForSelectedDay(_ selectedDay: daysOfWeek) -> [Muscle] {
        print("Selected day: \(selectedDay.rawValue)")
        
        let calendar = Calendar.current
        
        // Filter trainer templates that have a valid date and match the selected day
        let selectedDayTemplates = userData.trainerTemplates.filter { template in
            guard let templateDate = template.date else {
                print("Skipping template with nil date")
                return false
            }
            let templateDay = calendar.component(.weekday, from: templateDate)
            return daysOfWeek(weekday: templateDay) == selectedDay
        }
        
        print("Filtered templates count for selected day: \(selectedDayTemplates.count)")
        
        // Collect all categories from the selected templates
        let categories = selectedDayTemplates.flatMap { $0.categories }
        
        // Map categories to their respective muscles
        let muscles = categories.flatMap { SplitCategory.muscles[$0] ?? [] }
        
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
        }
            .compactMap { weekday in
                daysOfWeek(weekday: weekday)
            }
        print("Upcoming workout days: \(upcomingDays)")
        return upcomingDays
    }
    
    private func calculateRestPercentages() {
        var percentages: [Muscle: Int] = [:]
        let categories: [Muscle] = Muscle.allCases  // Or filter specific categories you need
        
        for category in categories {
            let restPercentage = calculateRestPercentage(for: category)
            percentages[category] = restPercentage
        }
        
        // Update the local state with calculated values
        restPercentages = percentages
    }
    
    func calculateRestPercentage(for muscle: Muscle) -> Int {
        let now = Date()
        // muscleRestDuration is presumably in hours. Adjust if needed.
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -userData.muscleRestDuration, to: now)!
        
        // 1) Filter completed workouts that occurred after the cutoff date,
        //    and check if they actually worked the target muscle.
        let recentlyWorked = userData.completedWorkouts.filter { workout in
            guard workout.date > cutoffDate else { return false }
            
            // Check if any exercise in this workout actively worked the muscle.
            return workout.template.exercises.contains { exercise in
                let isPrimary   = exercise.primaryMuscles.contains(muscle)
                let isSecondary = exercise.secondaryMuscles.contains(muscle)
                
                // Ensure at least one set is completed for this exercise.
                let hasValidSets = exercise.setDetails.contains { $0.repsCompleted != nil }
                
                return (isPrimary || isSecondary) && hasValidSets
            }
        }
        
        // 2) Now calculate a weighted rest percentage based on how recently each
        //    workout occurred, how many sets were completed, and whether the muscle was
        //    primary (1.0 weight) or secondary (0.5 weight).
        
        var totalWeight = 0.0
        var totalRest  = 0.0
        
        for workout in recentlyWorked {
            for exercise in workout.template.exercises {
                // Check muscle involvement
                let isPrimary   = exercise.primaryMuscles.contains(muscle)
                let isSecondary = exercise.secondaryMuscles.contains(muscle)
                
                // If this exercise doesn't involve the target muscle at all, skip
                guard (isPrimary || isSecondary) else { continue }
                
                // Weighted approach: primary = 1.0, secondary = 0.5
                let muscleWeight = isPrimary ? 1.0 : 0.5
                
                // All completed sets
                let validSets = exercise.setDetails.filter { $0.repsCompleted != nil }
                
                for _ in validSets {
                    // Hours since the workout
                    let hoursSinceLastWorkout = now.timeIntervalSince(workout.date) / 3600
                    // Convert that to 0–100% rest based on muscleRestDuration
                    // E.g., if muscleRestDuration is 48 hours, at 48h since last
                    // workout => 100% rest. At 24h => 50% rest, etc.
                    let rawRest = (hoursSinceLastWorkout / Double(userData.muscleRestDuration)) * 100
                    // Clamp between 0 and 100
                    let restPercentage = min(100, max(0, Int(rawRest)))
                    
                    // Tally up the weighted rest
                    totalWeight += muscleWeight
                    totalRest   += muscleWeight * Double(restPercentage)
                }
            }
        }
        
        // 3) If the muscle wasn’t worked at all recently, return 100% rest
        guard totalWeight > 0 else {
            return 100
        }
        
        // 4) Otherwise, compute final average rest percentage
        let finalRestPercentage = Int(totalRest / totalWeight)
        return finalRestPercentage
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




