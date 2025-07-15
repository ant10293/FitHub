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
            VStack(spacing: 20) {
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
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("History")
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear(perform: onAppearAction)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MenuView()) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
        }
    }
    
    private func onAppearAction() {
        workoutDates = userData.getWorkoutDates()
        plannedWorkoutDates = userData.getPlannedWorkoutDates()
    }
    
    // MARK: – Header
    private var headerSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 1) {
                HStack(spacing: 0) {
                    Text("Workout Streak: ").bold()
                    + Text("\(userData.sessionTracking.workoutStreak) ")
                    Image(systemName: "flame")
                }

                let longest = userData.sessionTracking.longestWorkoutStreak
                (Text("Longest Streak:").bold() +
                 Text(" \(longest) \(longest == 1 ? "day" : "days")"))
                    .font(.subheadline)
            }
            Spacer()
        }
        .overlay(alignment: .trailing) {
            FloatingButton(
                image: showCalendar ? "chart.bar" : "calendar",
                foreground: .blue,
                background: colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white,
                size: 15,
                action: { showCalendar.toggle() }
            )
            .padding(.trailing)
        }
    }

    private var LegendView: some View {
        VStack(spacing: 10) {
            if showCalendar {
                HStack {
                    Text(" ")
                    Circle()
                        .fill(.blue)
                        .frame(width: 15, height: 15, alignment: .leading)
                    Text("Planned Workouts")
                    Spacer()
                }
            }
            NavigationLink(destination: CompletedWorkouts(userData: userData)) {
                HStack {
                    Text(" ")
                    if showCalendar {
                        Circle()
                            .fill(.green)
                            .frame(width: 15, height: 15, alignment: .leading)
                    }
                    Text("Completed Workouts")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .frame(width: 15, height: 15)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack {
                VStack {
                    Text("Last Month")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(workoutCountForLastMonth())")
                }
                .padding()
                VStack {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(workoutCountForCurrentMonth())")
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
    
    private func workoutCountForLastMonth() -> Int {
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        return workoutDates.filter { calendar.isDate($0, equalTo: lastMonth, toGranularity: .month) }.count
    }
    
    private func workoutCountForCurrentMonth() -> Int {
        return workoutDates.filter { calendar.isDate($0, equalTo: currentMonth, toGranularity: .month) }.count
    }
}

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
