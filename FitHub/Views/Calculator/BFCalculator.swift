//
//  BFCalculator.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct BFCalculator: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserData
    @StateObject private var kbd = KeyboardManager.shared

    // Store canonically (cm) but the UI will show / edit in the user’s unit via Binding adapter
    @State private var waist: Length
    @State private var neck:  Length
    @State private var hip:   Length    // only used for female
    @State private var height: Length

    @State private var activeCard: ActiveCard = .none
    @State private var showingResult = false
    @State private var computedBF: Double = 0

    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)

        // Safely unwrap stored values (default to 0 cm if missing)
        let waistLen  = userData.currentMeasurementValue(for: .waist).asLength ?? Length(cm: 0)
        let neckLen   = userData.currentMeasurementValue(for: .neck).asLength  ?? Length(cm: 0)
        let hipLen    = userData.currentMeasurementValue(for: .hips).asLength  ?? Length(cm: 0)
        let heightLen = userData.physical.height

        _waist  = State(initialValue: waistLen)
        _neck   = State(initialValue: neckLen)
        _hip    = State(initialValue: hipLen)
        _height = State(initialValue: heightLen)
    }

    var body: some View {
        let height = screenHeight * 0.1

        VStack {
            ScrollView {
                waistCard
                    .padding(.top)
                neckCard
                if userData.physical.gender == .female {
                    hipCard
                }
                heightCard

                if !kbd.isVisible {
                    Spacer(minLength: height)

                    RectangularButton(
                        title: "Calculate Body Fat %",
                        enabled: isCalculateEnabled,
                        action: calculateAndShow
                    )
                    .padding(.horizontal)

                    Spacer(minLength: height)
                }
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Body Fat % Calculator", displayMode: .inline)
        .overlay(
            Group {
                if showingResult {
                    CalcResultView(title: "Body Fat Percentage", singleResult: "\(String(format: "%.2f", computedBF)) %", dismissAction: {
                        showingResult = false
                        dismiss()
                    })
                }
            }
        )
    }

    // MARK: - Computations

    private var isCalculateEnabled: Bool {
        // Always work in canonical cm to determine validity
        let hasCore = waist.inCm > 0 && neck.inCm > 0 && height.inCm > 0
        if userData.physical.gender == .male {
            return hasCore
        } else {
            return hasCore && hip.inCm > 0
        }
    }

    private func calculateAndShow() {
        let w = waist.inCm
        let n = neck.inCm
        let h = height.inCm
        let hp = hip.inCm

        let bf: Double
        if userData.physical.gender == .male {
            // US Navy (cm version)
            bf = 86.010 * log10(w - n) - 70.041 * log10(h) + 36.76
        } else {
            bf = 163.205 * log10(w + hp - n) - 97.684 * log10(h) - 78.387
        }

        // 1) Save back numbers if they changed (stored in metric)
        userData.updateMeasurementValue(for: .waist, with: w)
        userData.updateMeasurementValue(for: .neck,  with: n)
        if userData.physical.gender == .female {
            userData.updateMeasurementValue(for: .hips, with: hp)
        }
        userData.updateMeasurementValue(for: .bodyFatPercentage, with: bf)

        computedBF = bf
        showingResult = true
    }

    // MARK: - Cards
    private var waistCard: some View {
        MeasurementCard(
            title: "Waist",
            isActive: activeCard == .waist,
            onTap: { toggle(.waist) },
            onClose: closePicker,
            valueView: {
                Text(summary(for: waist, unit: UnitSystem.current.sizeUnit))
            },
            content: {
                TextField("Waist (\(UnitSystem.current.sizeUnit))", text: $waist.asText())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    private var neckCard: some View {
        MeasurementCard(
            title: "Neck",
            isActive: activeCard == .neck,
            onTap: { toggle(.neck) },
            onClose: closePicker,
            valueView: {
                Text(summary(for: neck, unit: UnitSystem.current.sizeUnit))
            },
            content: {
                TextField("Neck (\(UnitSystem.current.sizeUnit))", text: $neck.asText())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    private var hipCard: some View {
        MeasurementCard(
            title: "Hip",
            isActive: activeCard == .hip,
            onTap: { toggle(.hip) },
            onClose: closePicker,
            valueView: {
                Text(summary(for: hip, unit: UnitSystem.current.sizeUnit))
            },
            content: {
                TextField("Hip (\(UnitSystem.current.sizeUnit))", text: $hip.asText())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    private var heightCard: some View {
        MeasurementCard(
            title: "Height",
            isActive: activeCard == .height,
            onTap: { toggle(.height) },
            onClose: closePicker,
            valueView: {
                height.heightFormatted.foregroundStyle(.gray)
            },
            content: {
                HeightSelectorRow(height: $height)
            }
        )
    }

    // MARK: - Helpers
    private func summary(for length: Length, unit: String) -> String {
        let value = length.displayString
        return value.isEmpty ? "—" : "\(value) \(unit)"
    }

    private func toggle(_ card: ActiveCard) {
        activeCard = activeCard == card ? .none : card
    }

    private func closePicker() {
        kbd.dismiss()
        activeCard = .none
    }

    private enum ActiveCard {
        case none, waist, neck, hip, height
    }
}
