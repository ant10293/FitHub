import SwiftUI

struct SetInputRow<LoadField: View, MetricField: View>: View {
    let setNumber: Int
    let exercise: Exercise
    let isHeaderRow: Bool
    let load: SetLoad
    let metric: SetMetric

    // Inject the actual field content
    let loadField: () -> LoadField
    let metricField: () -> MetricField

    private let setsColWidth:  CGFloat = 54
    private let fieldColWidth: CGFloat = 100
    private let hGap:          CGFloat = 20
    private let vGap:          CGFloat = 4

    init(
        setNumber: Int,
        exercise: Exercise,
        load: SetLoad,
        metric: SetMetric,
        @ViewBuilder loadField: @escaping () -> LoadField,
        @ViewBuilder metricField: @escaping () -> MetricField
    ) {
        self.setNumber = setNumber
        self.exercise = exercise
        self.isHeaderRow = setNumber == 1
        self.load = load
        self.metric = metric
        self.loadField = loadField
        self.metricField = metricField
    }

    var body: some View {
        Grid(alignment: .center, horizontalSpacing: hGap, verticalSpacing: vGap) {
            if isHeaderRow {
                GridRow {
                    Text("Set")
                        .font(.headline)
                        .frame(width: setsColWidth)

                    if load != .none { loadHeader } else { Color.clear.frame(width: fieldColWidth) }
                    repsHeader
                }
            }

            GridRow {
                Text("\(setNumber)")
                    .fontWeight(.bold)
                    .frame(width: setsColWidth)

                if load != .none {
                    loadField()
                        .frame(width: fieldColWidth)
                } else {
                    Color.clear.frame(width: fieldColWidth)
                }

                metricField()
                    .frame(width: fieldColWidth)
            }
        }
    }
}

// MARK: - Column headers
private extension SetInputRow {
    var loadHeader: some View {
        VStack(spacing: 0) {
            Text(load.label)
                .font(exercise.weightInstruction == nil ? .headline : .caption)
                .fontWeight(.semibold)
            if let txt = exercise.weightInstruction {
                Text(txt.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: fieldColWidth)
    }
    
    var repsHeader: some View {
        VStack(spacing: 0) {
            Text(metric.label)
                .font(exercise.repsInstruction == nil ? .headline : .caption)
                .fontWeight(.semibold)
            if let txt = exercise.repsInstruction {
                Text(txt.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: fieldColWidth)
    }
}


/*
struct SetInputRow: View {
    // Inputs
    let setNumber: Int
    let exercise: Exercise
    
    @Binding var weightText: String
    @Binding var metricText: String
    
    // Column sizes + gaps
    private let setsColWidth:  CGFloat = 54
    private let fieldColWidth: CGFloat = 100
    private let hGap:          CGFloat = 20   // horizontal gap between columns
    private let vGap:          CGFloat = 4    // vertical gap between rows
    
    let isHeaderRow: Bool
    let metric: SetMetric
    let load: SetLoad

    
    init(
        setNumber: Int,
        exercise: Exercise,
        weightText: Binding<String>,
        metricText: Binding<String>
        
    ) {
        self.setNumber = setNumber
        self.exercise = exercise
        _weightText = weightText
        _metricText = metricText
        self.isHeaderRow = setNumber == 1
        self.load = exercise.getLoadMetric(metricValue: 0)
        self.metric = exercise.getPlannedMetric(value: 0)
    }
    
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: hGap, verticalSpacing: vGap) {
            // ── Header row (only on first logical row) ─────────────────
            if isHeaderRow {
                GridRow {
                    Text("Set")
                        .font(.headline)
                        .frame(width: setsColWidth)
                    
                    if load != .none {
                         loadHeader
                    } else {
                         Color.clear.frame(width: fieldColWidth) // ← holds column space
                    }
                    repsHeader
                }
            }
            
            // ── Data row ───────────────────────────────────────────────
            GridRow {
                Text("\(setNumber)")
                    .fontWeight(.bold)
                    .frame(width: setsColWidth)
                
                if load != .none {
                     loadField
                } else {
                     Color.clear.frame(width: fieldColWidth) // ← holds column space
                }
                
                switch metric {
                case .reps: repsField
                case .hold: timeField
                }
            }
        }
    }
}
 
 // MARK: - Fields
 private extension SetInputRow {
     var loadField: some View {
         TextField(
             "weight",
             text: Binding(
                 get: { weightText },
                 set: { newValue in
                     weightText = InputLimiter.filteredWeight(old: weightText, new: newValue)
                 }
             )
         )
         .keyboardType(.decimalPad)
         .multilineTextAlignment(.center)
         .textFieldStyle(.roundedBorder)
         .frame(width: fieldColWidth)
     }
     
     var repsField: some View {
         TextField(
             "reps",
             text: Binding(
                 get: { metricText },
                 set: { newValue in
                     metricText = InputLimiter.filteredReps(newValue)
                 }
             )
         )
         .keyboardType(.numberPad)
         .multilineTextAlignment(.center)
         .textFieldStyle(.roundedBorder)
         .frame(width: fieldColWidth)
     }
     
     var timeField: some View {
         TimeEntryField(text: $metricText)
             .frame(width: fieldColWidth)
    }
 }
*/
