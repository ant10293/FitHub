import SwiftUI

struct SetInputRow: View {
    // Inputs
    let setNumber: Int
    let exercise: Exercise
    
    @Binding var weightText: String
    @Binding var metricText:   String
    
    // Column sizes + gaps
    private let setsColWidth:  CGFloat = 54
    private let fieldColWidth: CGFloat = 100
    private let hGap:          CGFloat = 20   // horizontal gap between columns
    private let vGap:          CGFloat = 4    // vertical gap between rows
    
    private var isHeaderRow: Bool { setNumber == 1 }
    private var usesReps: Bool { exercise.effort.usesReps }
    
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: hGap, verticalSpacing: vGap) {
            // ── Header row (only on first logical row) ─────────────────
            if isHeaderRow {
                GridRow {
                    Text("Set")
                        .font(.headline)
                        .frame(width: setsColWidth)
                    
                    if exercise.type.usesWeight {
                         weightHeader
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
                
                if exercise.type.usesWeight {
                     weightField
                } else {
                     Color.clear.frame(width: fieldColWidth) // ← holds column space
                }
                
                if usesReps {
                    repsField
                } else {
                    timeField
                }
            }
        }
    }
}

// MARK: - Column headers
private extension SetInputRow {
    var weightHeader: some View {
        VStack(spacing: 0) {
            Text(UnitSystem.current.weightUnit)
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
            Text(usesReps ? "Reps" : "Time")
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

// MARK: - Fields
private extension SetInputRow {
    var weightField: some View {
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
