//
//  ExercisePerformanceGraph.swift
//  FitHub
//
//  Created by Anthony Cantu on 2/20/25.
//
import SwiftUI
import Charts


struct ExercisePerformanceGraph: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .allTime
    let exercise: Exercise
    let value: Double?
    let currentMaxDate: Date?
    let pastMaxes: [MaxRecord]
    
    var body: some View {
        VStack {
            Text("\(exercise.name) \(exercise.type.usesWeight ? "One Rep Max" : "Max Reps")")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        Chart {
                            if !sortedMaxRecords.isEmpty {
                                // One Rep Max Line and Points
                                ForEach(sortedMaxRecords) { record in
                                    LineMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value(exercise.type.usesWeight ? "One Rep Max" : "Max Reps", record.value)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    PointMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value(exercise.type.usesWeight ? "One Rep Max" : "Max Reps", record.value)
                                    )
                                    .foregroundStyle(record.date == currentMaxDate ? .green : .blue)
                                    .annotation(position: .top) {
                                        Text(Format.smartFormat(record.value))
                                            .font(.caption)
                                            .foregroundColor(record.date == currentMaxDate ? .green : .blue)
                                            .padding(1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                            )
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: yAxisRange)
                        .frame(width: max(CGFloat(sortedMaxRecords.count) * 60, UIScreen.main.bounds.width - 40), height: UIScreen.main.bounds.height * 0.33)
                        .overlay(alignment: .center) {                    // ← ① add overlay
                            if sortedMaxRecords.isEmpty {
                                Text("No data for available \n for this exercise...")
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .overlay(alignment: .bottomTrailing, content: {
                            Text(exercise.type.usesWeight ? "lb" : "reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        })
                        .padding()
                        
                        Color.clear.frame(width: 0.1).id("END")   // sentinel at far right
                    }
                }
                .onAppear {
                    proxy.scrollTo("END", anchor: .trailing)    // jump to the end
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
    
    private var minValue: Double {
        if exercise.type.usesWeight {
            return sortedMaxRecords.map { $0.value }.min() ?? 100
        }
        return sortedMaxRecords.map { $0.value }.min() ?? 0
    }
    
    private var maxValue: Double {
        if exercise.type.usesWeight {
            return sortedMaxRecords.map { $0.value }.max() ?? 300
        }
        return sortedMaxRecords.map { $0.value }.max() ?? 50
    }
    
    private var yAxisRange: ClosedRange<Double> { return minValue - (minValue * 0.2)...maxValue + (maxValue * 0.2) }
    
    private var sortedMaxRecords: [MaxRecord] {
        var records = pastMaxes
        if let value = value, let date = currentMaxDate {
            records.append(MaxRecord(value: value, date: date))
        }
        return filterRecords(records)
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
