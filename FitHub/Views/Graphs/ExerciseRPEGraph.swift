//
//  ExerciseRPEGraph.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/21/25.
//

import SwiftUI
import Charts

struct ExerciseRPEGraph: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .allTime
    // MARK: – Inputs
    let exercise: Exercise
    let completedWorkouts: [CompletedWorkout]

    var body: some View {
        VStack {
            Text("\(exercise.name) RPE Trend")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        Chart {
                            if !sortedRecords.isEmpty {
                                // RPE Line and Points
                                ForEach(sortedRecords) { record in
                                    let isLatest = record.date == latestRecord?.date
                                    
                                    LineMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value("RPE", record.rpe)
                                    )
                                    .foregroundStyle(isLatest ? .green : .blue)
                                    
                                    PointMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value("RPE", record.rpe)
                                    )
                                    .foregroundStyle(isLatest ? .green : .blue)
                                }
                            }
                        }
                        .chartYScale(domain: yAxisRange)
                        .frame(width: max(CGFloat(sortedRecords.count) * 60, UIScreen.main.bounds.width - 40), height: UIScreen.main.bounds.height * 0.33)
                        .overlay(alignment: .center) {
                            if sortedRecords.isEmpty {
                                Text("No data available \n for this exercise...")
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .chartYAxisLabel(position: .trailing) {
                            Text("RPE")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Color.clear.frame(width: 0.1).id("END")   // sentinel at far right
                    }
                }
                .onAppear { proxy.scrollTo("END", anchor: .trailing) }
            }
            
            Picker("Select Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue.capitalized).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }
    
    // MARK: – RPE Record Structure
    private struct RPERecord: Identifiable {
        let id: UUID = UUID()
        let date: Date
        let rpe: Double
    }
    
    // MARK: – Data Processing
    /// Extract all RPE records from completed workouts
    private var allRecords: [RPERecord] {
        var records: [RPERecord] = []
        
        // Find all workouts where this exercise was performed
        for workout in completedWorkouts {
            // Check if the exercise exists in this workout's template
            if let workoutExercise = workout.template.exercises.first(where: { $0.id == exercise.id }) {
                // Get all setDetails for this exercise
                let allSets = workoutExercise.setDetails
                
                // Filter sets that have RPE values and calculate average
                let rpeValues = allSets.compactMap { $0.rpe }
                
                // Only create a record if there are RPE values
                if !rpeValues.isEmpty {
                    let averageRPE = rpeValues.reduce(0, +) / Double(rpeValues.count)
                    records.append(RPERecord(date: workout.date, rpe: averageRPE))
                }
            }
        }
        
        return records
    }
    
    /// Records after time‑range filtering and per‑day de‑duplication.
    private var sortedRecords: [RPERecord] {
        guard !allRecords.isEmpty else { return [] }
        
        let filtered: [RPERecord] = {
            switch selectedTimeRange {
            case .month:
                if let start = CalendarUtility.shared.monthsAgo(1) {
                    return allRecords.filter { $0.date >= start }
                }
                return allRecords
            case .sixMonths:
                if let start = CalendarUtility.shared.monthsAgo(6) {
                    return allRecords.filter { $0.date >= start }
                }
                return allRecords
            case .year:
                if let start = CalendarUtility.shared.yearsAgo(1) {
                    return allRecords.filter { $0.date >= start }
                }
                return allRecords
            case .allTime:
                return allRecords
            }
        }()
        
        // Keep average RPE per calendar day (if multiple workouts on same day, average them)
        var rpePerDay: [Date: [Double]] = [:]
        for rec in filtered {
            let day = CalendarUtility.shared.startOfDay(for: rec.date)
            if rpePerDay[day] == nil {
                rpePerDay[day] = []
            }
            rpePerDay[day]?.append(rec.rpe)
        }
        
        // Convert to records with averaged RPE per day
        let dailyRecords = rpePerDay.compactMap { (date, rpeValues) -> RPERecord? in
            guard !rpeValues.isEmpty else { return nil }
            let averageRPE = rpeValues.reduce(0, +) / Double(rpeValues.count)
            return RPERecord(date: date, rpe: averageRPE)
        }
        
        return dailyRecords.sorted { $0.date < $1.date }
    }
    
    /// The latest (most recent) RPE record
    private var latestRecord: RPERecord? { sortedRecords.last }
    
    private var minValue: Double { sortedRecords.map { $0.rpe }.min() ?? 0 }
    
    private var maxValue: Double { sortedRecords.map { $0.rpe }.max() ?? 10 }
    
    private var yAxisRange: ClosedRange<Double> {
        let adjustedMin = min(minValue, 0)
        let adjustedMax = max(maxValue, 10)
        return adjustedMin...adjustedMax
    }
}
