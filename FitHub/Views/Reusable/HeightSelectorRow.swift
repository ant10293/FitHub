import SwiftUI

struct HeightSelectorRow: View {
    @AppStorage(UnitSystem.storageKey) private var unit: UnitSystem = .metric

    @Binding var height: Length

    @State private var feet: Int   = 0
    @State private var inches: Int = 0

    private let cmRange     = 90...250
    private let feetRange   = 3...7
    private let inchesRange = 0...11
    private let wheelH      = UIScreen.main.bounds.height * 0.20

    var body: some View {
        VStack {
            if unit == .imperial {
                // ft / in wheels
                HStack(spacing: 0) {
                    Picker("", selection: $feet) {
                        ForEach(feetRange, id: \.self) { Text("\($0)") }
                    }
                    .labelsHidden()
                    .overlay(alignment: .trailing) {
                        Text("ft")
                            .bold()
                            .foregroundStyle(.gray)
                            .offset(x: -50)
                    }

                    Picker("", selection: $inches) {
                        ForEach(inchesRange, id: \.self) { Text("\($0)") }
                    }
                    .labelsHidden()
                    .overlay(alignment: .trailing) {
                        Text("in")
                            .bold()
                            .foregroundStyle(.gray)
                            .offset(x: -45)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: wheelH)
                .onAppear(perform: syncImperialFromMetric)
                .onChange(of: feet)   { pushImperialToMetric() }
                .onChange(of: inches) { pushImperialToMetric() }
            } else {
                // Single “cm” wheel
                Picker("", selection: cmBinding) {
                    ForEach(cmRange, id: \.self) { Text("\($0)") }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(height: wheelH)
                .overlay(alignment: .trailing) {
                    Text("cm")
                        .bold()
                        .foregroundStyle(.gray)
                        .offset(x: -60)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .onChange(of: unit) { oldUnit, newUnit in
            if newUnit == .imperial {
                syncImperialFromMetric()
            }
        }
    }

    // MARK: - Metric wheel binding (Int cm <-> Length)
    private var cmBinding: Binding<Int> {
        Binding<Int>(
            get: { Int(round(height.inCm)) },
            set: { height.setCm(Double($0)) }
        )
    }

    // MARK: - Helpers
    private var totalInches: Int { feet * 12 + inches }

    private func syncImperialFromMetric() {
        let totalIn = Int(round(height.inInch))
        feet   = totalIn / 12
        inches = totalIn % 12
    }

    private func pushImperialToMetric() {
        height.setIn(Double(totalInches))
    }
}
