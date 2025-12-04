//
//  Calendar.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct CalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var currentMonth: Date
    @State private var selectedWorkout: CompletedWorkout? = nil
    let workoutDates: [Date]
    let plannedWorkoutDates: [Date]
    let completedWorkouts: [CompletedWorkout]

    // One grid definition reused for headers + days
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .center), count: 7)
    }

    private let weekdayHeaders = ["SUN","MON","TUE","WED","THU","FRI","SAT"] 

    var body: some View {
        VStack {
            Group {
                // ── Month nav bar ─────────────────────────────────────────────
                HStack {
                    Button(action: moveToPreviousMonth) {
                        Image(systemName: "arrow.left").bold()
                            .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    Text("\(currentMonth.monthName) \(String(year(from: currentMonth)))")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !isNextMonth(currentMonth) {
                        Button(action: moveToNextMonth) {
                            Image(systemName: "arrow.right").bold()
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding()
                
                // ── Headers + Days share the SAME grid ───────────────────────
                LazyVGrid(columns: columns, spacing: 0) {
                    // Header row
                    Group {
                        ForEach(weekdayHeaders, id: \.self) { day in
                            Text(day)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.bottom)
                    
                    // Day cells
                    ForEach(offsetDays.indices, id: \.self) { i in
                        dayCell(for: offsetDays[i])
                    }
                }
                .padding(.vertical)
            }
            .padding(.horizontal)
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .navigationDestination(item: $selectedWorkout) { workout in
            CompletedDetails(
                workout: workout,
                categories: SplitCategory.concatenateCategories(for: workout.template.categories)
            )
        }
    }

    // MARK: - Day cell plumbing
    @ViewBuilder
    private func dayCell(for day: Date?) -> some View {
        if let day {
            let workouts = workouts(for: day)
            if workouts.count == 1, let workout = workouts.first {
                // Single workout - set selectedWorkout on tap
                baseDayView(for: day)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWorkout = workout
                    }
            } else if workouts.count > 1 {
                // Multiple workouts - use Menu
                Menu {
                    ForEach(workouts, id: \.id) { workout in
                        Button(workoutLabel(for: workout)) {
                            selectedWorkout = workout
                        }
                    }
                } label: {
                    baseDayView(for: day)
                }
            } else {
                baseDayView(for: day)
            }
        } else {
            placeholderDayCell
        }
    }
    
    private func workoutLabel(for workout: CompletedWorkout) -> String {
        let timeString = Format.formatDate(workout.date, dateStyle: .none, timeStyle: .short)
        return "\(workout.template.name) - \(timeString)"
    }

    private func baseDayView(for day: Date) -> some View {
        DayView(
            day: day,
            completedWorkouts: workoutDates,
            plannedWorkouts: plannedWorkoutDates,
            today: Date()
        )
    }

    private var placeholderDayCell: some View {
        DayView(
            day: Date(),
            completedWorkouts: workoutDates,
            plannedWorkouts: plannedWorkoutDates,
            today: Date()
        )
        .hidden()
    }

    // MARK: - Helpers
    private func workouts(for date: Date) -> [CompletedWorkout] {
        return completedWorkouts.filter {
            CalendarUtility.shared.isDate($0.date, inSameDayAs: date)
            && !$0.template.exercises.isEmpty
        }.sorted { $0.date < $1.date } // Sort by time, earliest first
    }

    private func moveToPreviousMonth() {
        if let newMonth = CalendarUtility.shared.previousMonth(from: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func moveToNextMonth() {
        if let newMonth = CalendarUtility.shared.nextMonth(from: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func year(from date: Date) -> Int {
        CalendarUtility.shared.year(from: date)
    }

    private var days: [Date] {
        guard let interval = CalendarUtility.shared.dateInterval(of: .month, for: currentMonth) else { return [] }
        return CalendarUtility.shared.generateDates(inside: interval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }

    private var offsetDays: [Date?] {
        guard let firstDayOfMonth = CalendarUtility.shared.startOfMonth(for: currentMonth) else { return days }
        let weekdayOffset = CalendarUtility.shared.weekday(from: firstDayOfMonth) - 1 // Sunday-first
        var daysWithOffset: [Date?] = Array(repeating: nil, count: weekdayOffset)
        daysWithOffset.append(contentsOf: days)
        return daysWithOffset
    }

    private func isNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = CalendarUtility.shared.nextMonth(from: Date()) else { return false }
        return CalendarUtility.shared.isDate(date, equalTo: nextMonth, toGranularity: .month)
    }

    private struct DayView: View {
        @Environment(\.colorScheme) var colorScheme
        let day: Date
        let completedWorkouts: [Date]
        let plannedWorkouts: [Date]
        let today: Date

        var body: some View {
            GeometryReader { geometry in
                let cellSize = min(geometry.size.width, geometry.size.height) * 0.8
                ZStack {
                    Text("\(CalendarUtility.shared.day(from: day))")
                        .foregroundStyle(workoutColor)
                        .frame(width: cellSize, height: cellSize)
                        .background(backgroundView)
                        .clipShape(RoundedRectangle(cornerRadius: cellSize / 2))

                    if CalendarUtility.shared.isDate(day, inSameDayAs: today) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: cellSize * 1.17, height: cellSize * 1.17)
                            .zIndex(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 36) // ensure each cell takes full column width
        }

        private var isCompletedDay: Bool {
            completedWorkouts.contains { CalendarUtility.shared.isDate($0, inSameDayAs: day) }
        }

        private var isPlannedDay: Bool {
            plannedWorkouts.contains { CalendarUtility.shared.isDate($0, inSameDayAs: day) }
        }

        private var workoutColor: Color {
            (isCompletedDay || isPlannedDay) ? .white : (colorScheme == .dark ? .white : .black)
        }

        private var backgroundView: some View {
            Group {
                if isCompletedDay { Circle().fill(.green).shadow(radius: 2.5) }
                else if isPlannedDay { Circle().fill(.blue).shadow(radius: 2.5) }
                else { Color.clear }
            }
        }
    }
}
