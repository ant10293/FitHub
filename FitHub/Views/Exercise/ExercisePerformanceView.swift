import SwiftUI


struct ExercisePerformanceView: View {
    @State private var selectedTimeRange: TimeRange = .allTime
    let exercise: Exercise
    let maxValue: Double?
    let repsXweight: RepsXWeight?
    let currentMaxDate: Date?
    let pastMaxes: [MaxRecord]
    
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
            .zIndex(0)
            
            List {
                if sortedMaxRecords.isEmpty {
                    Text("No data available for this exercise.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(sortedMaxRecords, id: \.id) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date: \(Format.formatDate(record.date, dateStyle: .short, timeStyle: .none))")
                                Text(exercise.type.usesWeight ? "One Rep Max: \(Format.smartFormat(record.value)) lbs" : "Max Reps: \(Format.smartFormat(record.value)) reps")
                                if exercise.type.usesWeight {
                                    if let repsWeight = record.repsXweight {
                                        Text("\(Format.smartFormat(repsWeight.weight)) lbs x \(repsWeight.reps) reps")
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
    }
    
    private var sortedMaxRecords: [MaxRecord] {
        let startDate = Calendar.current.date(byAdding: timeInterval(for: selectedTimeRange), to: Date())!
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


