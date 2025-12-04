import SwiftUI


struct HistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.calendar) var calendar
    @ObservedObject var userData: UserData
    @State private var currentMonth = Date()
    @State private var showCalendar: Bool = true
    @State private var workoutDates: [Date] = []
    @State private var plannedWorkoutDates: [Date] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                headerSection
                
                if showCalendar {
                    CalendarView(
                        currentMonth: $currentMonth,
                        workoutDates: workoutDates,
                        plannedWorkoutDates: plannedWorkoutDates,
                        completedWorkouts: userData.workoutPlans.completedWorkouts
                    )
                } else {
                    ConsistencyGraph(
                        workoutDates: workoutDates,
                        workoutDaysPerWeek: userData.workoutPrefs.workoutDaysPerWeek
                    )
                }
                
                LegendView
                    .padding()
                
                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear(perform: onAppearAction)
            .customToolbar(
                settingsDestination: { AnyView(SettingsView()) },
                menuDestination: { AnyView(MenuView()) }
            )
        }
    }
    
    private func onAppearAction() {
        workoutDates = userData.getWorkoutDates()
        plannedWorkoutDates = userData.getPlannedWorkoutDates()
    }
    
    // MARK: – Header
    private var headerSection: some View {
        let count = userData.sessionTracking.workoutStreak
        let longest = userData.sessionTracking.longestWorkoutStreak

        return HStack {
            Spacer()
            VStack(spacing: 2) {
                (
                  Text("Workout Streak: ").bold()
                + Text("\(count) ")
                + Text(Image(systemName: "flame"))
                )
                .lineLimit(1)
                .layoutPriority(1)             // claim width before shrinking
                .minimumScaleFactor(0.85)

                (
                  Text("Longest Streak: ").bold()
                + Text("\(longest) \(longest == 1 ? "day" : "days")")
                )
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)  // stable line height
            Spacer()
        }
        .overlay(alignment: .trailing) {
            FloatingButton(
                image: showCalendar ? "chart.bar" : "calendar",
                foreground: .blue,
                background: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white,
                action: { showCalendar.toggle() }
            )
            .padding(.trailing)
        }
        .padding(.vertical)
    }

    private var LegendView: some View {
        let width = screenWidth
        
        return VStack(spacing: 10) {
            if showCalendar {
                HStack {
                    Text(" ")
                    Circle()
                        .fill(.blue)
                        .frame(width: width * 0.0375, height: width * 0.0375, alignment: .leading)
                    Text("Planned Workouts")
                    Spacer()
                }
            }
            NavigationLink(destination: LazyDestination { CompletedWorkouts(userData: userData) }) {
                HStack {
                    Text(" ")
                    if showCalendar {
                        Circle()
                            .fill(.green)
                            .frame(width: width * 0.0375, height: width * 0.0375, alignment: .leading)
                    }
                    Text("Completed Workouts")
                        //.foregroundStyle(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .frame(width: width * 0.0375, height: width * 0.0375)
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack {
                VStack {
                    Text("Last Month")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Text("\(workoutCountForLastMonth)")
                }
                .padding()
                
                VStack {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Text("\(workoutCountForCurrentMonth)")
                }
                .padding()
            }
            .padding(.horizontal)
            .padding(.bottom, -10)
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var workoutCountForLastMonth: Int {
        if let lastMonth = CalendarUtility.shared.previousMonth(from: currentMonth) {
            return workoutDates.filter { CalendarUtility.shared.isDate($0, equalTo: lastMonth, toGranularity: .month) }.count
        }
        return 0
    }
    
    private var workoutCountForCurrentMonth: Int {
        return workoutDates.filter { CalendarUtility.shared.isDate($0, equalTo: currentMonth, toGranularity: .month) }.count
    }
}

// uses the standard calender, not modified with different week start day
extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return self.isDate(date1, inSameDayAs: date2)
    }
}

