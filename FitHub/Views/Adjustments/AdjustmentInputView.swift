//
//  AdjustmentInputView.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/15/25.
//

import SwiftUI

struct AdjustmentInputView: View {
    @Binding var value: AdjustmentValue
    
    var body: some View {
        Group {
            switch value {
            case .number(let n):
                numberStepper(value: n ?? 0)
            case .letter(let l):
                letterPicker(selectedLetter: l ?? .a)
            case .size(let s):
                sizePicker(selectedSize: s ?? .xsmall)
            case .degrees(let d):
                degreesSlider(degrees: d ?? 0)
            }
        }
    }
    
    // MARK: - Number Stepper
    private func numberStepper(value: Int) -> some View {
        HStack {
            Spacer()
            Text("\(value)")
                .monospacedDigit()
            Stepper(
                "",
                value: Binding(
                    get: { value },
                    set: { newValue in
                        // Always set a non-nil value when user interacts
                        self.value = .number(newValue)
                    }
                ),
                in: -100...100
            )
            .fixedSize()
        }
    }

    // MARK: - Letter Picker
    private func letterPicker(selectedLetter: AdjustmentLetter) -> some View {
        chipPicker(
            selectedLetter,
            cases: AdjustmentLetter.allCases,
            label: { $0.rawValue.capitalized },
            onSelect: { 
                // Always set a non-nil value when user interacts
                value = .letter($0) 
            }
        )
    }

    // MARK: - Size Picker
    private func sizePicker(selectedSize: AdjustmentSize) -> some View {
        chipPicker(
            selectedSize,
            cases: AdjustmentSize.allCases,
            label: { $0.rawValue },
            onSelect: { 
                // Always set a non-nil value when user interacts
                value = .size($0) 
            }
        )
    }
    
    // MARK: - Degrees Slider
    private func degreesSlider(degrees: Int) -> some View {
        HStack {
            Text("\(degrees)°")
                .monospacedDigit()
                .frame(width: screenWidth * 0.1)
            Slider(
                value: Binding(
                    get: { Double(degrees) },
                    set: { newValue in
                        // Always set a non-nil value when user interacts
                        value = .degrees(Int(newValue.rounded()))
                    }
                ),
                in: 0...180,
                step: 1
            )
        }
    }
}

extension AdjustmentInputView {
    private func chipPicker<T: CaseIterable & Hashable>(
        _ selected: T,
        cases: T.AllCases,
        label: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) -> some View where T.AllCases: RandomAccessCollection {
        let items = Array(cases)

        return ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            onSelect(item)
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(item, anchor: .center)
                            }
                        } label: {
                            Text(label(item))
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selected == item ? Color.accentColor : Color.secondary.opacity(0.2))
                                )
                                .foregroundColor(selected == item ? .white : .primary)
                        }
                        .id(item)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
        }
    }
}
