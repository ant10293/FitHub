import SwiftUI


struct ExercisePerformanceView: View {
    @State private var selectedTimeRange: TimeRange = .allTime
    // MARK: – Inputs
    let exercise: Exercise
    let performance: ExercisePerformance?     // ← optional wrapper
    var onDelete: (MaxRecord.ID) -> Void 
    var onSetMax: (MaxRecord.ID) -> Void

    var body: some View {
        VStack(spacing: 6) {
            // ─────────  Time‑Range Picker  ─────────
            HStack {
                Text("Sort by").bold()
                Picker("Select Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue.capitalized).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)
            .padding(.bottom, -4)

            // ─────────  List of Records  ─────────
            List {
                if sortedRecords.isEmpty {
                    Text("No data available for this exercise.")
                        .foregroundStyle(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(sortedRecords, id: \.id) { record in
                        HStack {
                            Menu {
                                Button {
                                    onSetMax(record.id)
                                } label: {
                                    Label("Set as Current Max", systemImage: "star")
                                }
                                .disabled(record.id == performance?.currentMax?.id)

                                Button(role: .destructive) {
                                    onDelete(record.id)
                                } label: {
                                    Label("Delete Entry", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .imageScale(.large)
                                    .accessibilityLabel("More options")
                                    .foregroundStyle(Color.blue)
                            }
                            .buttonStyle(.plain) // no row highlight on tap
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date: ").bold()
                                + Text(Format.formatDate(record.date, dateStyle: .short, timeStyle: .none))
                                
                                record.value.formattedText

                                if let loadXmetric = record.loadXmetric {
                                    loadXmetric.formattedText
                                }
                            }

                            Spacer()

                            if record.id == performance?.currentMax?.id {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: – Helpers
    private var allRecords: [MaxRecord] {
        guard let perf = performance else { return [] }
        var recs = perf.pastMaxes ?? []
        if let current = perf.currentMax { recs.append(current) }
        return recs
    }

    private var sortedRecords: [MaxRecord] {
        guard !allRecords.isEmpty else { return [] }

        let startCutoff: Date = {
            switch selectedTimeRange {
            case .month:
                return CalendarUtility.shared.monthsAgo(1) ?? Date()
            case .sixMonths:
                return CalendarUtility.shared.monthsAgo(6) ?? Date()
            case .year:
                return CalendarUtility.shared.yearsAgo(1) ?? Date()
            case .allTime:
                // 100 years back is “good enough” to show everything
                return CalendarUtility.shared.yearsAgo(100) ?? Date()
            }
        }()

        return allRecords
            .filter { $0.date >= startCutoff }
            .sorted { $0.date > $1.date }
    }
}

