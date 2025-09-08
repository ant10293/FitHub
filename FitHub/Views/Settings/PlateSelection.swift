import SwiftUI

struct PlateSelection: View {
    @ObservedObject var userData: UserData

    // layout
    private let gridSpacing: CGFloat = 12

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 3)
    }

    // MARK: - Derived state
    private var all: [Mass] { WeightPlates.allOptions() }
    private var defaults: [Mass] { WeightPlates.defaultOptions() }
    private var selection: [Mass] { userData.evaluation.availablePlates.resolvedPlates }
    private var selectionSet: Set<Mass> { Set(selection) }
    private var allSet: Set<Mass> { Set(all) }
    private var defaultsSet: Set<Mass> { Set(defaults) }

    private var isDefaultSelection: Bool { selectionSet == defaultsSet }
    private var isAllSelected: Bool { allSet.isSubset(of: selectionSet) }
    private var isSelectionEmpty: Bool { selection.isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(all, id: \.self) { mass in
                        PlateChip(
                            mass: mass,
                            selected: selectionSet.contains(mass),
                            color: WeightPlates.color(for: mass, in: selection)
                        ) {
                            toggle(mass)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0, contentMode: .fit)
                    }
                }

                footerActions
            }
            .padding()
        }
        .navigationBarTitle("Available Plates", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    setPlates(defaults)
                }
                .foregroundStyle(isDefaultSelection ? .gray : .red)
                .disabled(isDefaultSelection)
            }
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(spacing: 4) {
            Text("Choose which plates you own").font(.headline)
            Text("Used for rounding, plate math, and the visualizer.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RectangularButton(
                    title: "Clear Selection",
                    enabled: !isSelectionEmpty,
                    action: {
                        setPlates([])
                    }
                )

                RectangularButton(
                    title: "Select All",
                    enabled: !isAllSelected,
                    color: .green,
                    action: {
                        setPlates(defaults)
                    }
                )
            }
        }
        .padding(.vertical)
    }

    // MARK: - Data

    private func toggle(_ mass: Mass) {
        var set = selectionSet
        if set.contains(mass) { set.remove(mass) } else { set.insert(mass) }
        setPlates(Array(set))
    }

    private func setPlates(_ plates: [Mass]) {
        userData.evaluation.availablePlates.setPlates(plates.sorted(by: massLessThan))
        userData.saveSingleStructToFile(\.evaluation, for: .evaluation)
    }

    private func massLessThan(_ a: Mass, _ b: Mass) -> Bool {
        switch UnitSystem.current {
        case .imperial: return a.inLb < b.inLb
        case .metric:   return a.inKg < b.inKg
        }
    }
}

// MARK: - Chip

private struct PlateChip: View {
    let mass: Mass
    let selected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.20))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? color : .secondary.opacity(0.35),
                            lineWidth: selected ? 2 : 1)

                HStack {
                    Spacer(minLength: 0)
                    mass.formattedText()
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)

                if selected {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.small)
                                .foregroundStyle(color)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
