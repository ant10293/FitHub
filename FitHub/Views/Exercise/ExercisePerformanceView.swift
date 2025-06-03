import SwiftUI


struct ExercisePerformanceView: View {
    var exercise: Exercise
    var maxValue: Double?
    var repsXweight: RepsXWeight?
    var currentMaxDate: Date?
    var pastMaxes: [MaxRecord]
    @State private var selectedTimeRange: TimeRange = .allTime
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack {
            HStack {
                Text("Sort by").bold()
                    .padding(.trailing)
                Picker("Select Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue.capitalized).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing)
            }
            .padding(.bottom, -10)
            .padding(.top)
            .zIndex(0)
            
            List {
                ForEach(sortedMaxRecords(), id: \.id) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Date: \(dateFormatter.string(from: record.date))")
                            Text(exercise.usesWeight ? "One Rep Max: \(smartFormat(record.value)) lbs" : "Max Reps: \(smartFormat(record.value)) reps")
                            //Text("Max Value: \(smartFormat(record.value)) \(exercise.usesWeight ? "lbs" : "reps")")
                            if exercise.usesWeight {
                                if let repsWeight = record.repsXweight {
                                    Text("\(smartFormat(repsWeight.weight)) lbs x \(repsWeight.reps) reps")
                                    //.font(.caption)
                                }
                            }
                        }
                        Spacer()
                        if record.date == currentMaxDate {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func sortedMaxRecords() -> [MaxRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: timeInterval(for: selectedTimeRange), to: Date())!
        var records = pastMaxes.filter { $0.date >= startDate }
        if let currentMaxDate = currentMaxDate, let maxValue = maxValue {
            let currentRecord = MaxRecord(id: UUID(), value: maxValue, repsXweight: repsXweight, date: currentMaxDate)
            records.append(currentRecord)
        }
        return records.sorted(by: { $0.date > $1.date })
    }
    
    private func timeInterval(for range: TimeRange) -> DateComponents {
        switch range {
        case .month:
            return DateComponents(month: -1)
        case .sixMonths:
            return DateComponents(month: -6)
        case .year:
            return DateComponents(year: -1)
        case .allTime:
            return DateComponents(year: -100) // Arbitrary long time ago
        }
    }
}


