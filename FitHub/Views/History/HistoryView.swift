import SwiftUI


struct HistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.calendar) var calendar
    @EnvironmentObject var userData: UserData
    @State private var currentMonth = Date()
    @State private var showCalendar: Bool = true
    @State private var isNavigationActive: Bool = false
    @State private var workoutDates: [Date] = []
    @State private var plannedWorkoutDates: [Date] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    VStack(spacing: 1) {
                        HStack {
                            Text("Workout Streak: ").bold()
                            + Text("\(userData.workoutStreak)")
                            Image(systemName: "flame")
                        }
                        let longestStreak = userData.longestWorkoutStreak
                        Text("Longest Streak: ").bold()
                            .font(.subheadline)
                        + Text("\(longestStreak) \(longestStreak != 1 ? "days" : "day")")
                            .font(.subheadline)
                    }
                    
                    ToggleButton
                        .padding(.trailing, 35)
                }
                .padding(.top, 10)
                
                if showCalendar {
                    CalendarView(userData: userData, currentMonth: $currentMonth, workoutDates: workoutDates, plannedWorkoutDates: plannedWorkoutDates)
                    
                } else {
                    WorkoutConsistency(userData: userData, workoutDates: workoutDates)
                }
                
                LegendView
                    .padding(.horizontal)
                
                Spacer()
            }
            .onAppear {
                workoutDates = userData.getWorkoutDates()
                plannedWorkoutDates = userData.getPlannedWorkoutDates()
            }
            .navigationTitle("History")
            .background(Color(UIColor.systemGroupedBackground))
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
    
    private var ToggleButton: some View {
        Button(action: {
            showCalendar.toggle()
        }) {
            Image(systemName: showCalendar ? "chart.bar" : "calendar")
                .resizable()
                .frame(width: 15, height: 15)
                .padding()
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .foregroundColor(.blue)
                .clipShape(Circle())
        }
        .padding(.leading)
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
        .cornerRadius(10)
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
