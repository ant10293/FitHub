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
        Form {
            // ───────────────── Waist / Neck / Hip
            Section {
                let unit = UnitSystem.current.sizeUnit
                TextField("Waist (\(unit))", text: $waist.asText())
                    .keyboardType(.decimalPad)

                TextField("Neck (\(unit))", text: $neck.asText())
                    .keyboardType(.decimalPad)

                if userData.physical.gender == .female {
                    TextField("Hip (\(unit))", text: $hip.asText())
                        .keyboardType(.decimalPad)
                }
            } header: {
                Text("Enter Waist and Neck Measurements")
            }

            // ───────────────── Height
            Section {
                HeightSelectorRow(height: $height)
            } header: {
                Text("Enter your Height")
            }

            // ───────────────── Action
            Section {
                EmptyView()
            } footer: {
                if !kbd.isVisible {
                    RectangularButton(
                        title: "Calculate Body Fat %",
                        enabled: isCalculateEnabled,
                        action: calculateAndShow
                    )
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
        }
        .disabled(showingResult)
        .blur(radius: showingResult ? 10 : 0)
        .background(Color(UIColor.systemGroupedBackground))
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Body Fat % Calculator", displayMode: .inline)
        .overlay(
            Group {
                if showingResult {
                    BodyFatResultView(bodyFat: computedBF) {
                        showingResult = false
                        dismiss()
                    }
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

    // MARK: - Result Overlay

    struct BodyFatResultView: View {
        @Environment(\.colorScheme) var colorScheme
        let bodyFat: Double
        var dismissAction: () -> Void

        var body: some View {
            VStack {
                Text("Body Fat Percentage")
                    .font(.headline)
                Text("\(bodyFat, specifier: "%.2f") %")
                    .font(.title2)

                RectangularButton(title: "Close", action: dismissAction)
                    .padding()
            }
            .frame(width: UIScreen.main.bounds.width * 0.8,
                   height: UIScreen.main.bounds.height * 0.25)
            .background(colorScheme == .dark
                        ? Color(UIColor.secondarySystemBackground)
                        : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
    }
}
