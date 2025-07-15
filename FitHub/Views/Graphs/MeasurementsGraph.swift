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
                        Chart {
                            if !sortedMeasurementRecords.isEmpty {
                                ForEach(sortedMeasurementRecords) { record in
                                    LineMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value("Value", record.value)
                                    )
                                    .foregroundStyle(.blue)
                                    PointMark(
                                        x: .value("Date", Format.formatDate(record.date, dateStyle: .short, timeStyle: .none)),
                                        y: .value("Value", record.value)
                                    )
                                    .foregroundStyle(record.date == currentMeasurementDate ? .green : .blue)
                                    .annotation(position: .top) {
                                        Text(Format.smartFormat(record.value))
                                            .font(.caption)
                                            .foregroundColor(record.date == currentMeasurementDate ? .green : .blue)
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
                        .frame(width: max(CGFloat(sortedMeasurementRecords.count) * 60, UIScreen.main.bounds.width - 40), height: UIScreen.main.bounds.height * 0.33)
                        .overlay(alignment: .center) {                    // ← ① add overlay
                            if sortedMeasurementRecords.isEmpty {
                                Text("No data available for \n this measurement...")
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .overlay(alignment: .bottomTrailing, content: {
                            if let unitLabel = selectedMeasurement.unitLabel {
                                Text(unitLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
    
    private var sortedMeasurementRecords: [Measurement] {
        var records: [Measurement] = []
        
        // Gather past and current measurements
        if let pastRecords = pastMeasurements {
            records = pastRecords
        }
        if let currentRecord = currentMeasurement, currentRecord.value > 0 {
            records.append(currentRecord)
        }
        
        // Filter out records with value 0
        records = records.filter { $0.value > 0 }
        
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
        let calendar = Calendar.current
        let filteredRecords: [Measurement]
        
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
        
        return filteredRecords
    }
    
    private var currentMeasurementDate: Date? {
        guard let measurement = currentMeasurement else { return nil }
        return measurement.date
    }
    
    private var minValue: Double { sortedMeasurementRecords.map { $0.value }.min() ?? 0 }
    
    private var maxValue: Double { sortedMeasurementRecords.map { $0.value }.max() ?? 0 }
    
    private var yAxisRange: ClosedRange<Double> { return minValue - (minValue * 0.1)...maxValue + (maxValue * 0.1) }
}

