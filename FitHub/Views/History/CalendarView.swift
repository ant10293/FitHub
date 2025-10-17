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
            // ── Month nav bar ─────────────────────────────────────────────
            HStack {
                Button(action: moveToPreviousMonth) {
                    Image(systemName: "arrow.left").bold()
                        .contentShape(Rectangle())
                }

                Spacer()

                Text("\(Format.monthName(from: currentMonth)) \(String(year(from: currentMonth)))")
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
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

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
            .padding(.horizontal)   // same horizontal padding for both rows
            .padding(.vertical)
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: - Day cell plumbing (unchanged)
    @ViewBuilder
    private func dayCell(for day: Date?) -> some View {
        if let day {
            if let w = workout(for: day) {
                NavigationLink(
                    destination: CompletedDetails(
                        workout: w,
                        categories: SplitCategory.concatenateCategories(for: w.template.categories)
                    )
                ) { baseDayView(for: day) }
                .buttonStyle(.plain)
            } else {
                baseDayView(for: day)
            }
        } else {
            placeholderDayCell
        }
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

    // MARK: - Helpers (unchanged)
    private func workout(for date: Date) -> CompletedWorkout? {
        return completedWorkouts.first {
            CalendarUtility.shared.isDate(($0.template.date ?? $0.date), inSameDayAs: date)
            && !$0.template.exercises.isEmpty
        }
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
            ZStack {
                Text("\(CalendarUtility.shared.day(from: day))")
                    .foregroundStyle(workoutColor)
                    .frame(width: 30, height: 30)
                    .background(backgroundView)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                if CalendarUtility.shared.isDate(day, inSameDayAs: today) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 35, height: 35)
                        .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36) // ensure each cell takes full column width
        }

        private var isWorkoutDay: Bool {
            completedWorkouts.contains { CalendarUtility.shared.isDate($0, inSameDayAs: day) }
        }

        private var isPlannedWorkoutDay: Bool {
            plannedWorkouts.contains { CalendarUtility.shared.isDate($0, inSameDayAs: day) }
        }

        private var workoutColor: Color {
            (isWorkoutDay || isPlannedWorkoutDay) ? .white : (colorScheme == .dark ? .white : .black)
        }

        private var backgroundView: some View {
            Group {
                if isWorkoutDay { Circle().fill(.green).shadow(radius: 2.5) }
                else if isPlannedWorkoutDay { Circle().fill(.blue).shadow(radius: 2.5) }
                else { Color.clear }
            }
        }
    }
}
