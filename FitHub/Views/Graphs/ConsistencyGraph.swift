import SwiftUI
import Charts

// month, 6 months, year
// with option to select year if available (eg. 2023)
struct ConsistencyGraph: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedYear: Int = CalendarUtility.shared.currentYear
    let workoutDates: [Date]
    let workoutDaysPerWeek: Int
    
    var body: some View {
        VStack {
            Text("Workouts Per Week")
                .font(.headline)
                .padding(.top)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        Chart {
                            if !workoutData.isEmpty {
                                ForEach(workoutData, id: \.week) { data in
                                    BarMark(
                                        x: .value("Week", data.formattedWeek),
                                        y: .value("Workouts", data.workoutCount)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.blue)
                                }
                            }
                            RuleMark(
                                y: .value("Workout Days Per Week", workoutDaysPerWeek)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.gray)
                            .annotation(position: .top, alignment: .trailing) {
                                Text("\(workoutDaysPerWeek) days/week")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .chartYScale(domain: 0...7)
                        .chartXAxisLabel("Week Start Date", alignment: .center)
                        .frame(width: max(CGFloat(workoutData.count) * 60, UIScreen.main.bounds.width - 40), height: UIScreen.main.bounds.height * 0.33)
                        .overlay(alignment: .center) {
                            if workoutData.isEmpty {
                                Text("No workout data available")
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        Color.clear.frame(width: 0.1).id("END")   // sentinel at far right
                    }
                }
                .onAppear { proxy.scrollTo("END", anchor: .trailing) }
            }
        
            // Picker for Time Range
            Picker("Select Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue)
                        .tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private struct WorkoutData {
        let week: Date
        let formattedWeek: String
        let workoutCount: Int
    }
    
    // Filter workoutDates based on selected time range
    private var filteredWorkoutDates: [Date] {
        switch selectedTimeRange {
        case .month:
            if let oneMonthAgo = CalendarUtility.shared.monthsAgo(1) {
                return workoutDates.filter { $0 >= oneMonthAgo }
            }
            return workoutDates
        case .sixMonths:
            if let sixMonthsAgo = CalendarUtility.shared.monthsAgo(6) {
                return workoutDates.filter { $0 >= sixMonthsAgo }
            }
            return workoutDates
        case .year:
            // Use the selectedYear to compute start and end of the year.
            if let startDate = CalendarUtility.shared.startOfYear(selectedYear),
               let endDate = CalendarUtility.shared.endOfYear(selectedYear) {
                return workoutDates.filter { $0 >= startDate && $0 <= endDate }
            }
            return workoutDates
        case .allTime:
            return workoutDates
        }
    }
    
    // Generate workout data using filtered dates
    private var workoutData: [WorkoutData] {
        let weeks = CalendarUtility.shared.generateWeeklyIntervals(for: filteredWorkoutDates)
        return weeks.map { week in
            let workoutCount = filteredWorkoutDates.filter { CalendarUtility.shared.isDate($0, equalTo: week.start, toGranularity: .weekOfYear) }.count
            let formattedWeek = week.start.monthDay
            return WorkoutData(week: week.start, formattedWeek: formattedWeek, workoutCount: workoutCount)
        }
    }
}

