//
//  Calender.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var userData: UserData
    @Binding var currentMonth: Date
    var workoutDates: [Date]
    var plannedWorkoutDates: [Date]
    @Environment(\.calendar) var calendar
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.moveToPreviousMonth()
                }) {
                    Image(systemName: "arrow.left").bold()
                        .contentShape(Rectangle())
                }
                
                Spacer()
                
                Text("\(monthName(from: currentMonth)) \(String(year(from: currentMonth)))")
                    .font(.headline)
                
                Spacer()
                
                if !isNextMonth(currentMonth) {
                    Button(action: {
                        self.moveToNextMonth()
                    }) {
                        Image(systemName: "arrow.right").bold()
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            HStack {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 15) {
                ForEach(Array(offsetDays.enumerated()), id: \.offset) { index, day in
                    if let day = day {
                        if let workout = workout(for: day) {
                            NavigationLink(destination: CompletedDetails(workout: workout, categories: SplitCategory.concatenateCategories(for: workout.template.categories))) {
                                DayView(day: day,
                                        completedWorkouts: workoutDates,
                                        plannedWorkouts: plannedWorkoutDates,
                                        today: Date())
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            DayView(day: day,
                                    completedWorkouts: workoutDates,
                                    plannedWorkouts: plannedWorkoutDates,
                                    today: Date())
                        }
                    } else {
                        DayView(day: Date(),
                                completedWorkouts: workoutDates,
                                plannedWorkouts: plannedWorkoutDates,
                                today: Date())
                        .hidden()
                    }
                }
            }
            .padding(.vertical)
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func workout(for date: Date) -> CompletedWorkout? {
        return userData.completedWorkouts.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private func moveToPreviousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func moveToNextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthName(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: date)
    }
    
    private func year(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: date)
    }
    
    private var days: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        return calendar.generateDates(inside: interval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }
    
    private var offsetDays: [Date?] {
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let weekdayOffset = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var daysWithOffset: [Date?] = Array(repeating: nil, count: weekdayOffset)
        daysWithOffset.append(contentsOf: days)
        
        return daysWithOffset
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    private func isNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) else { return false }
        return calendar.isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    struct DayView: View {
        let day: Date
        let completedWorkouts: [Date]
        let plannedWorkouts: [Date]
        let today: Date
        @Environment(\.calendar) var calendar
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            ZStack {
                Text("\(calendar.component(.day, from: day))")
                    .foregroundColor(workoutColor)
                    .frame(width: 30, height: 30)
                    .background(backgroundView)
                    .cornerRadius(15)
                // Outer circle if today:
                if calendar.isDate(day, inSameDayAs: today) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 35, height: 35)
                        .zIndex(1)
                }
            }
        }
        
        private var isWorkoutDay: Bool {
            completedWorkouts.contains(where: { calendar.isDate($0, inSameDayAs: day) })
        }
        
        private var isPlannedWorkoutDay: Bool {
            plannedWorkouts.contains { workoutDate in
                calendar.isDate(workoutDate, inSameDayAs: day)
            }
        }
        
        private var workoutColor: Color {
            if isWorkoutDay || isPlannedWorkoutDay {
                return .white
            } else {
                return colorScheme == .dark ? .white : .black
            }
        }
        
        private var backgroundView: some View {
            Group {
                if isWorkoutDay {
                    Circle().fill(.green)
                        .shadow(radius: 2.5)
                } else if isPlannedWorkoutDay {
                    Circle().fill(.blue)
                        .shadow(radius: 2.5)
                } else {
                    Color.clear
                }
            }
        }
    }
}
