import SwiftUI
import Charts

struct MeasurementsGraph: View {
    @ObservedObject var userData: UserData
    var selectedMeasurement: MeasurementType
    @State private var selectedTimeRange: TimeRange = .allTime
    @Environment(\.colorScheme) var colorScheme
    
    init(userData: UserData, selectedMeasurement: MeasurementType) {
        self.userData = userData
        self.selectedMeasurement = selectedMeasurement  
    }

    var body: some View {
        VStack {
            Text("\(selectedMeasurement.rawValue) History")
                .font(.headline)
                .centerHorizontally()
            
            if sortedMeasurementRecords.isEmpty {
                List {
                    Text("No data available for the selected measurement.")
                        .foregroundColor(.gray)
                        .padding()
                }
                .frame(height: 300)
            } else {
                ZStack {
                    Chart {
                        ForEach(sortedMeasurementRecords) { record in
                            LineMark(
                                x: .value("Date", dateFormatter.string(from: record.date)),
                                y: .value("Value", record.value)
                            )
                            .foregroundStyle(.blue)
                            PointMark(
                                x: .value("Date", dateFormatter.string(from: record.date)),
                                y: .value("Value", record.value)
                            )
                            .foregroundStyle(record.date == currentMeasurementDate ? .green : .blue)
                            .annotation(position: .top) {
                                Text(smartFormat(record.value))
                                    .font(.caption)
                                    .foregroundColor(record.date == currentMeasurementDate ? .green : .blue)
                                    .padding(1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground).opacity(0.8))
                                    )
                            }
                            /*.annotation(position: .top) {
                                Text(smartFormat(record.value))
                                    .font(.caption)
                                    .foregroundColor(record.date == currentMeasurementDate ? .green: .blue)
                            }*/
                        }
                    }
                    .chartYScale(domain: yAxisRange)
                    .frame(minHeight: 250)
                    .padding()
                    
                    if let unitLabel = selectedMeasurement.unitLabel {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(unitLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom)
                                    .padding(.trailing)
                            }.zIndex(1)
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

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var sortedMeasurementRecords: [Measurement] {
        var records: [Measurement] = []
        
        // Gather past and current measurements
        if let pastRecords = userData.pastMeasurements[selectedMeasurement] {
            records = pastRecords
        }
        if let currentRecord = userData.currentMeasurements[selectedMeasurement], currentRecord.value > 0 {
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
            let dateString = dateFormatter.string(from: record.date)
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
    
    var currentMeasurementDate: Date? {
        return userData.currentMeasurements[selectedMeasurement]?.date
    }
    
    var minValue: Double {
        sortedMeasurementRecords.map { $0.value }.min() ?? 0
    }
    
    var maxValue: Double {
        sortedMeasurementRecords.map { $0.value }.max() ?? 0
    }
    
    var yAxisRange: ClosedRange<Double> {
        let minValueAdjusted = minValue - (minValue * 0.1)
        let maxValueAdjusted = maxValue + (maxValue * 0.1)
        return minValueAdjusted...maxValueAdjusted
    }
}

