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

