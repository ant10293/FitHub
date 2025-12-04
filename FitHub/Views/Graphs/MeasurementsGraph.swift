import SwiftUI
import Charts

struct MeasurementsGraph: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .allTime
    let selectedMeasurement: MeasurementType
    let currentMeasurement: Measurement?
    let pastMeasurements: [Measurement]?

    var body: some View {
        VStack {
            Text("\(selectedMeasurement.rawValue) History")
                .font(.headline)
                .centerHorizontally()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
           
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ZStack(alignment: .bottomTrailing) {
                            Chart {
                                if !sortedMeasurementRecords.isEmpty {
                                    ForEach(sortedMeasurementRecords) { record in
                                        LineMark(
                                            x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                            y: .value("Value", record.entry.displayValue)
                                        )
                                        .foregroundStyle(.blue)
                                        PointMark(
                                            x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                            y: .value("Value", record.entry.displayValue)
                                        )
                                        .foregroundStyle(record.date == currentMeasurementDate ? .green : .blue)
                                        .annotation(position: .top) {
                                            Text(Format.smartFormat(record.entry.displayValue))
                                                .font(.caption)
                                                .foregroundStyle(record.date == currentMeasurementDate ? .green : .blue)
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
                            .overlay(alignment: .center) {
                                if sortedMeasurementRecords.isEmpty {
                                    Text("No data available for \n this measurement...")
                                        .foregroundStyle(.gray)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            if !sortedMeasurementRecords.isEmpty, let unitLabel = selectedMeasurement.unitLabel {
                                Text(unitLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: max(CGFloat(sortedMeasurementRecords.count) * 60, screenWidth - 40), height: screenHeight * 0.33)
                        
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
    
    private var sortedMeasurementRecords: [Measurement] {
        var records: [Measurement] = []
        
        // Gather past and current measurements
        if let pastRecords = pastMeasurements {
            records = pastRecords
        }
        if let currentRecord = currentMeasurement, currentRecord.entry.displayValue > 0 {
            records.append(currentRecord)
        }
        
        // Filter out records with value 0
        records = records.filter { $0.entry.displayValue > 0 }
        
        // Apply time range filter
        records = filterRecords(records)
        
        // Sort by date
        records = records.sorted { $0.date < $1.date }
        
        // Keep only the most recent record for each date
        var uniqueRecords: [Measurement] = []
        var seenDates: Set<String> = Set()
        
        for record in records.reversed() {
            let dateString = Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)
            if !seenDates.contains(dateString) {
                uniqueRecords.append(record)
                seenDates.insert(dateString)
            }
        }
        
        return uniqueRecords.reversed()
    }
    
    private func filterRecords(_ records: [Measurement]) -> [Measurement] {
        let filteredRecords: [Measurement]
        
        switch selectedTimeRange {
        case .month:
            if let startDate = CalendarUtility.shared.monthsAgo(1) {
            filteredRecords = records.filter { $0.date >= startDate }
            } else {
                filteredRecords = records
            }
        case .sixMonths:
            if let startDate = CalendarUtility.shared.monthsAgo(6) {
            filteredRecords = records.filter { $0.date >= startDate }
            } else {
                filteredRecords = records
            }
        case .year:
            if let startDate = CalendarUtility.shared.yearsAgo(1) {
            filteredRecords = records.filter { $0.date >= startDate }
            } else {
                filteredRecords = records
            }
        case .allTime:
            filteredRecords = records
        }
        
        return filteredRecords
    }
    
    private var currentMeasurementDate: Date? {
        guard let measurement = currentMeasurement else { return nil }
        return measurement.date
    }
    
    private var minValue: Double { sortedMeasurementRecords.map { $0.entry.displayValue }.min() ?? 0 }
    
    private var maxValue: Double { sortedMeasurementRecords.map { $0.entry.displayValue }.max() ?? 100 }
    
    private var yAxisRange: ClosedRange<Double> { return minValue - (minValue * 0.1)...maxValue + (maxValue * 0.1) }
}

