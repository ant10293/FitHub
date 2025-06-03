//
//  ExercisePerformanceGraph.swift
//  FitHub
//
//  Created by Anthony Cantu on 2/20/25.
//
import SwiftUI
import Charts


struct ExercisePerformanceGraph: View {
    @State private var selectedTimeRange: TimeRange = .allTime
    @Environment(\.colorScheme) var colorScheme
    var exercise: Exercise
    var value: Double
    var currentMaxDate: Date
    var pastMaxes: [MaxRecord]

    
    var body: some View {
        VStack {
            Text("\(exercise.name) \(exercise.usesWeight ? "One Rep Max" : "Max Reps")")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
            
            if sortedMaxRecords.isEmpty {
                List {
                    Text("No performance data available for this exercise.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
                .frame(height: 300)
            } else {
                ZStack {
                    Chart {
                        // One Rep Max Line and Points
                        if exercise.usesWeight {
                            ForEach(sortedMaxRecords) { record in
                                LineMark(
                                    x: .value("Date", dateFormatter.string(from: record.date)),
                                    y: .value("One Rep Max", record.value)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Date", dateFormatter.string(from: record.date)),
                                    y: .value("One Rep Max", record.value)
                                )
                                .foregroundStyle(record.date == currentMaxDate ? .green : .blue)
                                .annotation(position: .top) {
                                    Text(smartFormat(record.value))
                                        .font(.caption)
                                        .foregroundColor(record.date == currentMaxDate ? .green : .blue)
                                        .padding(1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                        )
                                }
                            }
                        } else {
                            // Max Reps Line and Points
                            ForEach(sortedMaxRecords) { record in
                                LineMark(
                                    x: .value("Date", dateFormatter.string(from: record.date)),
                                    y: .value("Max Reps", record.value)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Date", dateFormatter.string(from: record.date)),
                                    y: .value("Max Reps", record.value)
                                )
                                .foregroundStyle(record.date == currentMaxDate ? .green : .blue)
                                .annotation(position: .top) {
                                    Text(smartFormat(record.value))
                                        .font(.caption)
                                        .foregroundColor(record.date == currentMaxDate ? .green : .blue)
                                        .padding(1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                        )
                                }
                            }
                        }
                    }
                    .chartYScale(domain: yAxisRange)
                    .frame(minHeight: 250)
                    .padding()
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(exercise.usesWeight ? "lbs" : "reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                                .padding(.horizontal)
                        }.zIndex(1)
                    }
                }
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var sortedMaxRecords: [MaxRecord] {
        var records = pastMaxes
        let currentRecord = MaxRecord(value: value, date: currentMaxDate)
        records.append(currentRecord)
        return filterRecords(records)
    }
    
    var minValue: Double {
        return sortedMaxRecords.map { $0.value }.min() ?? 0
    }
    
    var maxValue: Double {
        return sortedMaxRecords.map { $0.value }.max() ?? 0
    }
    
    var yAxisRange: ClosedRange<Double> {
        let minValueAdjusted = minValue - (minValue * 0.2)
        let maxValueAdjusted = maxValue + (maxValue * 0.2)
        return minValueAdjusted...maxValueAdjusted
    }
    
    private func filterRecords(_ records: [MaxRecord]) -> [MaxRecord] {
        let calendar = Calendar.current
        var filteredRecords: [MaxRecord]
        
        // Filter based on the selected time range
        switch selectedTimeRange {
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .allTime:
            filteredRecords = records
        }
        
        var maxRecordsByDate = [Date: MaxRecord]()
        
        for record in filteredRecords {
            if let existingRecord = maxRecordsByDate[record.date] {
                if record.value > existingRecord.value {
                    maxRecordsByDate[record.date] = record
                }
            } else {
                maxRecordsByDate[record.date] = record
            }
        }
        return Array(maxRecordsByDate.values).sorted { $0.date < $1.date }
    }
}
/*
struct ExercisePerformanceGraph: View {
    @State private var selectedTimeRange: TimeRange = .allTime
    @Environment(\.colorScheme) var colorScheme
    var exercise: Exercise
    var value: Double
    var currentMaxDate: Date
    var pastMaxes: [MaxRecord]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var sortedMaxRecords: [MaxRecord] {
        var records = pastMaxes
        let currentRecord = MaxRecord(value: value, date: currentMaxDate)
        records.append(currentRecord)
        return filterRecords(records)
    }
    
    var minValue: Double {
        return sortedMaxRecords.map { $0.value }.min() ?? 0
    }
    
    var maxValue: Double {
        return sortedMaxRecords.map { $0.value }.max() ?? 0
    }
    
    var yAxisRange: ClosedRange<Double> {
        let minValueAdjusted = minValue - (minValue * 0.2)
        let maxValueAdjusted = maxValue + (maxValue * 0.2)
        return minValueAdjusted...maxValueAdjusted
    }
    
    private func filterRecords(_ records: [MaxRecord]) -> [MaxRecord] {
        let calendar = Calendar.current
        var filteredRecords: [MaxRecord]
        
        // Filter based on the selected time range
        switch selectedTimeRange {
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
            filteredRecords = records.filter { $0.date >= startDate }
        case .allTime:
            filteredRecords = records
        }
        
        var maxRecordsByDate = [Date: MaxRecord]()
        
        for record in filteredRecords {
            if let existingRecord = maxRecordsByDate[record.date] {
                if record.value > existingRecord.value {
                    maxRecordsByDate[record.date] = record
                }
            } else {
                maxRecordsByDate[record.date] = record
            }
        }
        return Array(maxRecordsByDate.values).sorted { $0.date < $1.date }
    }
    
    // Calculate a dynamic width for the chart:
    // Use a width factor (e.g. 50 points per record), but ensure a minimum width equal to the screen width.
    private var chartWidth: CGFloat {
        let widthFactor: CGFloat = 50
        let calculated = CGFloat(sortedMaxRecords.count) * widthFactor
        return max(calculated, UIScreen.main.bounds.width)
    }
    
    var body: some View {
        VStack {
            Text("\(exercise.name) \(exercise.usesWeight ? "One Rep Max" : "Max Reps")")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
            
            if sortedMaxRecords.isEmpty {
                List {
                    Text("No performance data available for this exercise.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
                .frame(height: 300)
            } else {
                ZStack {
                    // Wrap the chart in a horizontal scroll view
                    ScrollView(.horizontal) {
                        Chart {
                            if exercise.usesWeight {
                                ForEach(sortedMaxRecords) { record in
                                    LineMark(
                                        x: .value("Date", dateFormatter.string(from: record.date)),
                                        y: .value("One Rep Max", record.value)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    PointMark(
                                        x: .value("Date", dateFormatter.string(from: record.date)),
                                        y: .value("One Rep Max", record.value)
                                    )
                                    .foregroundStyle(record.date == currentMaxDate ? .green : .blue)
                                    .annotation(position: .top) {
                                        Text(smartFormat(record.value))
                                            .font(.caption)
                                            .foregroundColor(record.date == currentMaxDate ? .green : .blue)
                                            .padding(1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                            )
                                    }
                                }
                            } else {
                                ForEach(sortedMaxRecords) { record in
                                    LineMark(
                                        x: .value("Date", dateFormatter.string(from: record.date)),
                                        y: .value("Max Reps", record.value)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    PointMark(
                                        x: .value("Date", dateFormatter.string(from: record.date)),
                                        y: .value("Max Reps", record.value)
                                    )
                                    .foregroundStyle(record.date == currentMaxDate ? .green : .blue)
                                    .annotation(position: .top) {
                                        Text(smartFormat(record.value))
                                            .font(.caption)
                                            .foregroundColor(record.date == currentMaxDate ? .green : .blue)
                                            .padding(1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                            )
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: yAxisRange)
                        .frame(width: chartWidth, height: 300)
                        .padding()
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(exercise.usesWeight ? "lbs" : "reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                                .padding(.trailing)
                        }
                        .zIndex(1)
                    }
                }
            }
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
 */
