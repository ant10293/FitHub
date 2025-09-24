//
//  ExerciseperformanceormanceGraph.swift
//  FitHub
//
//  Created by Anthony Cantu on 2/20/25.
//
import SwiftUI
import Charts

struct ExercisePerformanceGraph: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .allTime
    // MARK: – Inputs
    let exercise: Exercise
    let performance: ExercisePerformance?
    
    var body: some View {
        VStack {
            Text("\(exercise.name) \(exercise.performanceTitle)")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        Chart {
                            if !sortedRecords.isEmpty {
                                // One Rep Max Line and Points
                                ForEach(sortedRecords) { record in
                                    LineMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value(exercise.performanceTitle, record.value.displayValue)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    PointMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value(exercise.performanceTitle, record.value.displayValue)
                                    )
                                    .foregroundStyle(record.id == performance?.currentMax?.id ? .green : .blue)
                                    .annotation(position: .top) {
                                        Text(Format.smartFormat(record.value.displayValue))
                                            .font(.caption)
                                            .foregroundStyle(record.id == performance?.currentMax?.id ? .green : .blue)
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
                        .frame(width: max(CGFloat(sortedRecords.count) * 60, UIScreen.main.bounds.width - 40), height: UIScreen.main.bounds.height * 0.33)
                        .overlay(alignment: .center) {                    // ← ① add overlay
                            if sortedRecords.isEmpty {
                                Text("No data available \n for this exercise...")
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .overlay(alignment: .bottomTrailing, content: {
                            Text(exercise.performanceUnit)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
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
    
    // MARK: – Derived helpers
    private var allRecords: [MaxRecord] {
        guard let perf = performance else { return [] }
        var recs = perf.pastMaxes ?? []
        if let current = perf.currentMax { recs.append(current) }
        return recs
    }
    
    /// Records after time‑range filtering and per‑day de‑duplication.
    private var sortedRecords: [MaxRecord] {
        guard !allRecords.isEmpty else { return [] }
        
        let filtered: [MaxRecord] = {
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
        
        // keep highest per calendar day
        var highestPerDay: [Date: MaxRecord] = [:]
        for rec in filtered {
            let day = CalendarUtility.shared.startOfDay(for: rec.date)
            if let existing = highestPerDay[day] {
                if rec.value.displayValue > existing.value.displayValue {
                    highestPerDay[day] = rec
                }
            } else {
                highestPerDay[day] = rec
            }
        }
        
        return highestPerDay.values.sorted { $0.date < $1.date }
    }
    
    private var minValue: Double {
        if exercise.usesWeight { return sortedRecords.map { $0.value.displayValue }.min() ?? 100 }
        return sortedRecords.map { $0.value.displayValue }.min() ?? 0
    }
    
    private var maxValue: Double {
        if exercise.usesWeight { return sortedRecords.map { $0.value.displayValue }.max() ?? 300 }
        return sortedRecords.map { $0.value.displayValue }.max() ?? 50
    }
    
    private var yAxisRange: ClosedRange<Double> { return minValue - (minValue * 0.2)...maxValue + (maxValue * 0.2) }
}
    


