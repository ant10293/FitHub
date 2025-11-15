//
//  WeekWorkoutVM.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/16/25.
//

import Foundation
import SwiftUI
import Combine


// MARK: - View‑model ----------------------------------------------------

@MainActor
final class WeekWorkoutVM: ObservableObject {
    // Published results for the view layer
    @Published var dayInfos: [DayInfo]        = []
    @Published var earliestFutureDate: Date   = Date()

    private var cancellables                  = Set<AnyCancellable>()
    private let userData: UserData            // weak reference not needed – UD is @Observed

    init(userData: UserData) {
        self.userData = userData
        
        let wpPublisher = userData.$workoutPlans          // Published<WorkoutPlans>.Publisher

        Publishers.CombineLatest4(
            wpPublisher.map(\.workoutsStartDate),
            wpPublisher.map(\.trainerTemplates),
            wpPublisher.map(\.completedWorkouts),
            userData.objectWillChange
        )
        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
        .sink { [weak self] _,_,_,_  in self?.recalculate() }
        .store(in: &cancellables)

        recalculate() // initial load
    }

    // ------------------------------------------------------------------
    private func recalculate() {
        let today = CalendarUtility.shared.startOfDay(for: Date())
        let stored = userData.workoutPlans.workoutsStartDate ?? Date()
        let startDate = CalendarUtility.shared.startOfWeek(for: stored) ?? stored
        let weekRange = CalendarUtility.shared.datesInWeek(startingFrom: startDate)

        // Group templates by date
        let workoutsByDate: [Date?: [WorkoutTemplate]] = Dictionary(
            grouping: userData.workoutPlans.trainerTemplates
        ) { tpl -> Date? in
            if let d = tpl.date { return CalendarUtility.shared.startOfDay(for: d) }
            if let cw = userData.workoutPlans.completedWorkouts.first(where: { $0.template.id == tpl.id }),
               let d2 = cw.template.date {
                return CalendarUtility.shared.startOfDay(for: d2)
            }
            return nil
        }

        // Build DayInfo objects
        dayInfos = weekRange.map { date in
            let midnight = CalendarUtility.shared.startOfDay(for: date)
            let workouts = workoutsByDate[midnight] ?? []

            let todaysCompleted = userData.workoutPlans.completedWorkouts.filter {
                CalendarUtility.shared.isDate(($0.template.date ?? $0.date), inSameDayAs: date)
            }

            // Only mark completed if a completion matches a planned template for this day
            let plannedIDs = Set(workouts.map(\.id))
            let hasMatchedCompletion = todaysCompleted.contains { plannedIDs.contains($0.template.id) }

            let status: DayInfo.Status = {
                if hasMatchedCompletion { return .completed }
                if !workouts.isEmpty,
                   let tplDate = workouts.first?.date,
                   CalendarUtility.shared.isDate(tplDate, inSameDayAs: date) {
                    if let endOfDay = CalendarUtility.shared.date(bySettingHour: 23, minute: 59, second: 59, of: date) {
                    return Date() > endOfDay ? .pastPlanned : .planned
                    }
                    return .planned
                }
                return .rest
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
                dayName: midnight.dayOfWeek,
                shortDate: midnight.dayOfWeek,
                isToday: CalendarUtility.shared.isDateInToday(midnight),
                status: status,
                workouts: rows
            )
        }

        earliestFutureDate = dayInfos.first(where: { $0.id >= today })?.id ?? today
    }
}

