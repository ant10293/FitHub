//
//  CalendarUtility.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/13/25.
//

import Foundation

/// A comprehensive calendar utility that provides safe, reusable calendar operations
/// and eliminates force unwrapping throughout the codebase.
final class CalendarUtility {
    
    // MARK: - Singleton
    static let shared = CalendarUtility()
    private init() {}
    
    // MARK: - Calendar Configuration
    private lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday as first day of week
        return calendar
    }()
    
    // MARK: - Date Components
    
    /// Safely extracts year component from a date
    func year(from date: Date) -> Int {
        calendar.component(.year, from: date)
    }
    
    /// Safely extracts month component from a date
    func month(from date: Date) -> Int {
        calendar.component(.month, from: date)
    }
    
    /// Safely extracts day component from a date
    func day(from date: Date) -> Int {
        calendar.component(.day, from: date)
    }
    
    /// Safely extracts weekday component from a date
    func weekday(from date: Date) -> Int {
        calendar.component(.weekday, from: date)
    }
    
    /// Safely extracts week of year component from a date
    func weekOfYear(from date: Date) -> Int {
        calendar.component(.weekOfYear, from: date)
    }
    
    // MARK: - Date Arithmetic (Safe)
    
    /// Safely adds a time interval to a date
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }
    
    /// Safely creates a date from components
    func date(from components: DateComponents) -> Date? {
        calendar.date(from: components)
    }
    
    /// Safely creates date components from a date
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }
    
    /// Safely creates date components between two dates
    func dateComponents(_ components: Set<Calendar.Component>, from startDate: Date, to endDate: Date) -> DateComponents {
        calendar.dateComponents(components, from: startDate, to: endDate)
    }
    
    // MARK: - Common Date Operations
    
    /// Gets the start of day for a given date
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Gets the end of day for a given date (23:59:59)
    func endOfDay(for date: Date) -> Date? {
        calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
    }
    
    /// Sets specific time components on a date
    func date(bySettingHour hour: Int, minute: Int, second: Int, of date: Date) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: second, of: date)
    }
    
    // MARK: - Week Operations
    
    /// Gets the start of the week for a given date
    func startOfWeek(for date: Date) -> Date? {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)
    }
    
    /// Gets the end of the week for a given date
    func endOfWeek(for date: Date) -> Date? {
        guard let startOfWeek = startOfWeek(for: date) else { return nil }
        return self.date(byAdding: .day, value: 6, to: startOfWeek)
    }
    
    /// Generates all dates in a week starting from a given date
    func datesInWeek(startingFrom date: Date) -> [Date] {
        guard let startOfWeek = startOfWeek(for: date) else { return [] }
        return (0..<7).compactMap { dayOffset in
            self.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    /// Generates weekly intervals for a set of dates (for consistency graph)
    func generateWeeklyIntervals(for dates: [Date]) -> [DateInterval] {
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }
        var intervals = [DateInterval]()
        var currentStartDate = startOfWeek(for: minDate) ?? minDate
        let endDate = endOfWeek(for: maxDate) ?? maxDate
        
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
    
    // MARK: - Month Operations
    
    /// Gets the start of the month for a given date
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return calendar.date(from: components)
    }
    
    /// Gets the end of the month for a given date
    func endOfMonth(for date: Date) -> Date? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return self.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1)
    }
    
    /// Gets the first day of the month with proper weekday offset
    func firstDayOfMonthWithOffset(for date: Date) -> (firstDay: Date?, weekdayOffset: Int) {
        guard let firstDay = startOfMonth(for: date) else { return (nil, 0) }
        let weekdayOffset = weekday(from: firstDay) - 1 // Sunday-first
        return (firstDay, weekdayOffset)
    }
    
    /// Generates all dates in a month with proper grid offset
    func datesInMonthWithOffset(for date: Date) -> [Date?] {
        let (_, weekdayOffset) = firstDayOfMonthWithOffset(for: date)
        
        // Get all days in the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let daysInMonth = calendar.generateDates(inside: monthInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
        
        // Create offset array
        var datesWithOffset: [Date?] = Array(repeating: nil, count: weekdayOffset)
        datesWithOffset.append(contentsOf: daysInMonth)
        
        return datesWithOffset
    }
    
    // MARK: - Date Comparison
    
    /// Checks if two dates are the same day
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Checks if a date is today
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /// Checks if two dates are equal to a specific granularity
    func isDate(_ date1: Date, equalTo date2: Date, toGranularity granularity: Calendar.Component) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: granularity)
    }
    
    /// Checks if a date is in the same month as another date
    func isDate(_ date1: Date, inSameMonthAs date2: Date) -> Bool {
        isDate(date1, equalTo: date2, toGranularity: .month)
    }
    
    /// Checks if a date is in the same week as another date
    func isDate(_ date1: Date, inSameWeekAs date2: Date) -> Bool {
        isDate(date1, equalTo: date2, toGranularity: .weekOfYear)
    }
    
    // MARK: - Date Intervals
    
    /// Safely gets a date interval for a specific component
    func dateInterval(of component: Calendar.Component, for date: Date) -> DateInterval? {
        calendar.dateInterval(of: component, for: date)
    }
    
    /// Generates dates inside an interval matching specific components
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        calendar.generateDates(inside: interval, matching: components)
    }
    
    // MARK: - Time Period Calculations
    
    /// Gets a date from a specified number of months ago
    func monthsAgo(_ months: Int, from date: Date = Date()) -> Date? {
        self.date(byAdding: .month, value: -months, to: date)
    }
    
    /// Gets a date from a specified number of years ago
    func yearsAgo(_ years: Int, from date: Date = Date()) -> Date? {
        self.date(byAdding: .year, value: -years, to: date)
    }
    
    /// Gets a date from a specified number of days ago
    func daysAgo(_ days: Int, from date: Date = Date()) -> Date? {
        self.date(byAdding: .day, value: -days, to: date)
    }
    
    /// Gets a date from a specified number of hours ago
    func hoursAgo(_ hours: Int, from date: Date = Date()) -> Date? {
        self.date(byAdding: .hour, value: -hours, to: date)
    }
    
    // MARK: - Specific Time Periods
    
    /// Gets the date from one month ago
    var oneMonthAgo: Date? {
        monthsAgo(1)
    }
    
    /// Gets the date from six months ago
    var sixMonthsAgo: Date? {
        monthsAgo(6)
    }
    
    /// Gets the date from one year ago
    var oneYearAgo: Date? {
        yearsAgo(1)
    }
    
    /// Gets the date from 100 years ago (for "all time" calculations)
    var oneHundredYearsAgo: Date? {
        yearsAgo(100)
    }
    
    // MARK: - Navigation
    
    /// Gets the previous month from a given date
    func previousMonth(from date: Date) -> Date? {
        self.date(byAdding: .month, value: -1, to: date)
    }
    
    /// Gets the next month from a given date
    func nextMonth(from date: Date) -> Date? {
        self.date(byAdding: .month, value: 1, to: date)
    }
    
    /// Checks if a date is in the next month relative to today
    func isNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = nextMonth(from: Date()) else { return false }
        return isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    // MARK: - Workout-Specific Operations
    
    /// Checks if a planned workout date is in the past (considering end of day)
    func isPlannedWorkoutInPast(_ plannedDate: Date, currentDate: Date = Date()) -> Bool {
        guard let endOfDay = endOfDay(for: plannedDate) else { return false }
        return endOfDay < currentDate
    }
    
    /// Gets the number of days between two dates
    func daysBetween(_ date1: Date, and date2: Date) -> Int {
        let components = dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }
    
    /// Checks if a date is within the last 30 days
    func isWithinLast30Days(_ date: Date, from currentDate: Date = Date()) -> Bool {
        daysBetween(date, and: currentDate) < 30
    }
    
    // MARK: - Year Operations
    
    /// Gets the start of a specific year
    func startOfYear(_ year: Int) -> Date? {
        let components = DateComponents(year: year, month: 1, day: 1)
        return calendar.date(from: components)
    }
    
    /// Gets the end of a specific year
    func endOfYear(_ year: Int) -> Date? {
        let components = DateComponents(year: year, month: 12, day: 31)
        return calendar.date(from: components)
    }
    
    /// Gets the current year
    var currentYear: Int {
        year(from: Date())
    }
    
    // MARK: - Time Component Extraction
    
    /// Gets hour and minute components from a date
    func hourMinuteComponents(from date: Date) -> (hour: Int, minute: Int) {
        let components = dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0, components.minute ?? 0)
    }
    
    /// Gets weekday component from a date
    func weekdayComponent(from date: Date) -> Int? {
        let components = dateComponents([.weekday], from: date)
        return components.weekday
    }
    
    // MARK: - Date Formatting Helpers
    
    /// Gets the month name from a date
    func monthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    /// Gets the year from a date as a string
    func yearString(from date: Date) -> String {
        String(year(from: date))
    }
    
    /// Gets the full month and year string
    func monthYearString(from date: Date) -> String {
        "\(monthName(from: date)) \(yearString(from: date))"
    }
    
    // MARK: - Age Calculations
    
    /// Calculates age between two dates
    func age(from birthDate: Date, to currentDate: Date = Date()) -> Int {
        let components = dateComponents([.year], from: birthDate, to: currentDate)
        return components.year ?? 0
    }
}

// MARK: - Convenience Extensions

extension Date {
    /// Convenience property to access the calendar utility
    //var calendar: CalendarUtility { CalendarUtility.shared }
}

// MARK: - Calendar Extension for generateWeeklyIntervals (for backward compatibility)

extension Calendar {
    /// Generates weekly intervals for a set of dates (for consistency graph)
    func generateWeeklyIntervals(for dates: [Date]) -> [DateInterval] {
        CalendarUtility.shared.generateWeeklyIntervals(for: dates)
    }
    
    /// Gets the start of the week for a given date (safe version)
    func startOfWeek(for date: Date) -> Date? {
        CalendarUtility.shared.startOfWeek(for: date)
    }
    
    /// Gets the end of the week for a given date (safe version)
    func endOfWeek(for date: Date) -> Date? {
        CalendarUtility.shared.endOfWeek(for: date)
    }
}


