import SwiftUI
import Charts

// month, 6 months, year
// with option to select year if available (eg. 2023)
struct WorkoutConsistency: View {
    @ObservedObject var userData: UserData
    @Environment(\.colorScheme) var colorScheme
    var workoutDates: [Date]
    
    // New state for filtering
    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // Filter workoutDates based on selected time range
    var filteredWorkoutDates: [Date] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedTimeRange {
        case .month:
            guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return workoutDates }
            return workoutDates.filter { $0 >= oneMonthAgo }
        case .sixMonths:
            guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else { return workoutDates }
            return workoutDates.filter { $0 >= sixMonthsAgo }
        case .year:
            // Use the selectedYear to compute start and end of the year.
            guard let startDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
                  let endDate = calendar.date(from: DateComponents(year: selectedYear, month: 12, day: 31))
            else { return workoutDates }
            return workoutDates.filter { $0 >= startDate && $0 <= endDate }
        case .allTime:
            return workoutDates
        }
    }
    
    // Generate workout data using filtered dates
    var workoutData: [WorkoutData] {
        let calendar = Calendar.current
        let weeks = calendar.generateWeeklyIntervals(for: filteredWorkoutDates)
        return weeks.map { week in
            let workoutCount = filteredWorkoutDates.filter { calendar.isDate($0, equalTo: week.start, toGranularity: .weekOfYear) }.count
            let formattedWeek = formatDate(week.start)
            return WorkoutData(week: week.start, formattedWeek: formattedWeek, workoutCount: workoutCount)
        }
    }
    
    var body: some View {
        VStack {
            Text("Workouts Per Week")
                .font(.headline)
                .padding(.top)
            
            if workoutData.isEmpty {
                List {
                    Text("No workout data available.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                Chart {
                    ForEach(workoutData, id: \.week) { data in
                        BarMark(
                            x: .value("Week", data.formattedWeek),
                            y: .value("Workouts", data.workoutCount)
                        )
                        .cornerRadius(8)
                        .foregroundStyle(.blue)
                    }
                    RuleMark(
                        y: .value("Workout Days Per Week", userData.workoutDaysPerWeek)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.gray)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("\(userData.workoutDaysPerWeek) days/week")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(1)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                            )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                        AxisTick()
                    }
                }
                .chartXAxis {
                    AxisMarks() {
                        AxisValueLabel()
                        AxisTick()
                    }
                }
                .padding()
            
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
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    struct WorkoutData {
        let week: Date
        let formattedWeek: String
        let workoutCount: Int
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

extension Calendar {
    func generateWeeklyIntervals(for dates: [Date]) -> [DateInterval] {
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }
        var intervals = [DateInterval]()
        var currentStartDate = startOfWeek(for: minDate)
        let endDate = endOfWeek(for: maxDate)
        
        while currentStartDate <= endDate {
            if let interval = dateInterval(of: .weekOfYear, for: currentStartDate) {
                intervals.append(interval)
                currentStartDate = interval.end
            } else {
                break
            }
        }
        
        return intervals
    }
    
    func startOfWeek(for date: Date) -> Date {
        return dateInterval(of: .weekOfYear, for: date)!.start
    }
    
    func endOfWeek(for date: Date) -> Date {
        return dateInterval(of: .weekOfYear, for: date)!.end
    }
}
