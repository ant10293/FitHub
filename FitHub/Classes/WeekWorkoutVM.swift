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
    private let calendar                      = Calendar.current
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
        let cal          = calendar
        let today        = Date().startOfDay(using: cal)
        let startDate    = userData.workoutPlans.workoutsStartDate ?? Date()
        let weekRange    = startDate.datesOfWeek(using: cal)

        // Group templates by date
        let workoutsByDate: [Date?: [WorkoutTemplate]] = Dictionary(
            grouping: userData.workoutPlans.trainerTemplates
        ) { tpl -> Date? in
            if let d = tpl.date {
                return d.startOfDay(using: cal)
            }
            if let cw = userData.workoutPlans.completedWorkouts.first(where: { $0.template.id == tpl.id }),
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
                if userData.workoutPlans.completedWorkouts.contains(where: {
                    cal.isDate($0.template.date ?? Date(), inSameDayAs: date)
                }) {
                    return .completed
                }
                if let first = workouts.first, let tplDate = first.date,
                   cal.isDate(tplDate, inSameDayAs: date) {
                    let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
                    return Date() > endOfDay ? .pastPlanned : .planned
                }
                
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
                dayName: Format.dayOfWeek(from: midnight),
                shortDate: Format.shortDate(from: midnight),
                isToday: cal.isDateInToday(midnight),
                status: status,
                workouts: rows
            )
        }

        earliestFutureDate =
            dayInfos.first(where: { $0.id >= today })?.id ?? today
    }
}
