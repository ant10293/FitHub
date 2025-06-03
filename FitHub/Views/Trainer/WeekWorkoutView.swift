//
//  WeekWorkoutView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/7/24.
//
//
//  WeekWorkoutView.swift
//  FitHub
//
//  Created by <You> on <Today’s Date>.
//

import SwiftUI
import Combine

// MARK: - View‑model ----------------------------------------------------

@MainActor
final class WeekWorkoutVM: ObservableObject {
    // Published results for the view layer
    @Published var dayInfos: [DayInfo]        = []
    @Published var earliestFutureDate: Date   = Date()

    private var cancellables                  = Set<AnyCancellable>()
    private let calendar                      = Calendar.current
    private let userData: UserData            // weak reference not needed – UD is @Observed

    init(userData: UserData) {
        self.userData = userData

        // Listen for any change that matters
        Publishers.CombineLatest4(
            userData.$workoutsStartDate,
            userData.$trainerTemplates,
            userData.$completedWorkouts,
            userData.objectWillChange              // catches mutations inside arrays
        )
        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _, _ in self?.recalculate() }
        .store(in: &cancellables)

        recalculate() // initial load
    }

    // ------------------------------------------------------------------
    private func recalculate() {
        let cal          = calendar
        let today        = Date().startOfDay(using: cal)
        let startDate    = userData.workoutsStartDate ?? Date()
        let weekRange    = startDate.datesOfWeek(using: cal)

        // Group templates by date
        let workoutsByDate: [Date?: [WorkoutTemplate]] = Dictionary(
            grouping: userData.trainerTemplates
        ) { tpl -> Date? in
            if let d = tpl.date {
                return d.startOfDay(using: cal)
            }
            if let cw = userData.completedWorkouts.first(where: { $0.template.id == tpl.id }),
               let d2 = cw.template.date {
                return d2.startOfDay(using: cal)
            }
            return nil                           // no date found
        }

        // Build DayInfo objects
        dayInfos = weekRange.map { date in
            let midnight  = date.startOfDay(using: cal)
            let workouts  = workoutsByDate[midnight] ?? []

            let status: DayInfo.Status = {
                if let first = workouts.first, let tplDate = first.date,
                   cal.isDate(tplDate, inSameDayAs: date) {
                    let endOfDay = cal.date(bySettingHour:23, minute:59, second:59, of: date)!
                    return Date() > endOfDay ? .pastPlanned : .planned
                }
                if userData.completedWorkouts.contains(where: {
                    cal.isDate($0.template.date ?? Date(), inSameDayAs: date)
                }) { return .completed }
                return .planned
            }()

            let rows = workouts.map {
                DayInfo.WorkoutRow(
                    id: $0.id,
                    categoriesText: SplitCategory.concatenateCategories(for: $0.categories),
                    template: $0
                )
            }

            return DayInfo(
                id: midnight,
                dayName: dayOfWeekFormatter.string(from: midnight),
                shortDate: dateFormatter.string(from: midnight),
                isToday: cal.isDateInToday(midnight),
                status: status,
                workouts: rows
            )
        }

        earliestFutureDate =
            dayInfos.first(where: { $0.id >= today })?.id ?? today
    }
}

// MARK: - DTO used by the view -----------------------------------------

struct DayInfo: Identifiable, Hashable {
    enum Status { case pastPlanned, completed, planned }

    let id: Date
    let dayName: String
    let shortDate: String
    let isToday: Bool
    let status: Status
    let workouts: [WorkoutRow]

    struct WorkoutRow: Identifiable, Hashable {
        let id: UUID
        let categoriesText: String
        let template: WorkoutTemplate
    }
}

// MARK: - Week Workout View --------------------------------------------

struct WeekWorkoutView: View {
    @ObservedObject var userData: UserData
    @StateObject private var vm: WeekWorkoutVM

    @State private var selectedTemplate: WorkoutTemplate?

    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _vm       = StateObject(wrappedValue: WeekWorkoutVM(userData: userData))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 12) {
                    ForEach(vm.dayInfos) { info in
                        DayWorkoutView(
                            info: info,
                            onSelect: { selectedTemplate = $0 }
                        )
                        .id(info.id)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .onAppear {
                proxy.scrollTo(vm.earliestFutureDate, anchor: .center)
            }
        }
    }
}

// MARK: - Single‑day card ---------------------------------------------

struct DayWorkoutView: View {
    @Environment(\.colorScheme) private var colorScheme
    let info: DayInfo
    let onSelect: (WorkoutTemplate) -> Void

    var body: some View {
        ZStack {
            VStack {
                Text(info.dayName)
                    .font(.caption).fontWeight(.semibold)

                Text(info.shortDate)
                    .font(.caption)

                if info.workouts.isEmpty {
                    Text("Rest")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white : .gray)
                } else {
                    ForEach(info.workouts) { row in
                        Text(row.categoriesText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForStatus(info.status))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 2)
                            .onTapGesture { onSelect(row.template) }
                    }
                }
            }
            .frame(width: 90, height: 110)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cardBorder, lineWidth: info.workouts.isEmpty ? 0 : 2)
            )
            .cornerRadius(10)
            .shadow(radius: 3)

            if info.isToday {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 110, height: 130)
            }
        }
    }

    // MARK: - Appearance helpers
    private var cardBackground: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
    }
    private var cardBorder: Color { colorForStatus(info.status) }

    private func colorForStatus(_ s: DayInfo.Status) -> Color {
        switch s {
        case .pastPlanned: return .red
        case .completed:   return .green
        case .planned:     return .blue
        }
    }
}

// MARK: - Date helpers & formatters ------------------------------------

/*
import SwiftUI


struct WeekWorkoutView: View {
    @ObservedObject var userData: UserData
    let calendar = Calendar.current
    @State private var selectedTemplate: WorkoutTemplate?

    var body: some View {
        let startDate = userData.workoutsStartDate
        let weekRange = startDate?.datesOfWeek(using: calendar) ?? Date().datesOfWeek(using: calendar)
        
        // Group workouts by date
        let today = Date().startOfDay(using: calendar)
        let workoutsByDate = Dictionary(grouping: userData.trainerTemplates, by: { trainerTemplate in
            // If the trainer template has a date, use it; otherwise, check completed workouts
            trainerTemplate.date?.startOfDay(using: calendar) ??
            userData.completedWorkouts.first(where: { $0.template.id == trainerTemplate.id })?.template.date?.startOfDay(using: calendar)
        })
        
        let earliestFutureDate = workoutsByDate.keys
            .compactMap { $0 }  // This removes nil values
            .filter { $0 >= today }
            .sorted()
            .first ?? today
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 12) {
                    ForEach(weekRange, id: \.self) { date in
                        // Fetch workouts for the current date
                        let workouts = workoutsByDate[date.startOfDay(using: calendar)] ?? []
                        
                        DayWorkoutView(userData: userData, date: date, workouts: workouts, onSelect: { template in
                            selectedTemplate = template
                        })
                        .id(date.startOfDay(using: calendar)) // Assign a unique ID to each day
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                proxy.scrollTo(earliestFutureDate, anchor: .center)
            }
        }
    }
    
    struct DayWorkoutView: View {
        @ObservedObject var userData: UserData
        @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
        var date: Date
        var workouts: [WorkoutTemplate]
        var onSelect: (WorkoutTemplate) -> Void
        let calendar = Calendar.current
        
        var body: some View {
            let isToday = calendar.isDateInToday(date)
            let dateStatus = determineDateStatus()
            
            ZStack {
                VStack {
                    Text(dayOfWeekFormatter.string(from: date)) // Day of the week
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(dateFormatter.string(from: date)) // Date
                        .font(.caption)
                        .fontWeight(.regular)
                    
                    if workouts.isEmpty {
                        Text("Rest")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white : .gray)
                    } else {
                        ForEach(workouts, id: \.id) { workout in
                            VStack(alignment: .leading) {
                                Text(SplitCategory.concatenateCategories(for: workout.categories))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorForStatus(dateStatus))
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.8)
                                    .padding(.horizontal, 2)
                            }.onTapGesture {
                                onSelect(workout)
                            }
                        }
                    }
                }
                .frame(width: 90, height: 110) // Adjust the frame height to accommodate the additional text
                .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorForStatus(dateStatus), lineWidth: !workouts.isEmpty ? 2 : 0)
                )
                
                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2)) // Semi-transparent gray
                        .frame(width: 110, height: 130)
                }
            }
        }
        
        private func determineDateStatus() -> DateStatus {
            let now = Date()
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? startOfDay.addingTimeInterval(86400 - 1)
            
            if let templateDate = workouts.first?.date, calendar.isDate(templateDate, inSameDayAs: date) {
                if now > endOfDay {
                    return .pastPlanned
                } else {
                    return .planned
                }
            } else if userData.completedWorkouts.first(where: { completed in
                calendar.isDate(completed.template.date ?? now, inSameDayAs: date)
            }) != nil {
                return .completed
            }
            return .planned
        }
        
        private func colorForStatus(_ status: DateStatus) -> Color {
            switch status {
            case .pastPlanned: return Color.red
            case .completed: return Color.green
            case .planned: return Color.blue
            }
        }
        
        enum DateStatus {
            case pastPlanned
            case completed
            case planned
        }
    }
}
*/

struct WeekLegendView: View {
    var body: some View {
        HStack(spacing: 15) {
            LegendItem(color: .blue, label: "Planned")
            LegendItem(color: .green, label: "Completed")
            LegendItem(color: .red, label: "Missed")
        }
        .padding(.top, 8)
    }
}

struct LegendItem: View {
    var color: Color
    var label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()

let dayOfWeekFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()


extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2  // 2 = Monday in most regions
        // Rebuild date from .yearForWeekOfYear / .weekOfYear
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
    
    // The rest stays the same
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
    
    func datesOfWeek(using calendar: Calendar = .current) -> [Date] {
        let start = self.startOfWeek(using: calendar)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
