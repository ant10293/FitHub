//
//  RestPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI
import SwiftUI

struct RestPicker: View {
    @Binding var time: TimeSpan

    var minuteRange: ClosedRange<Int> = 0...59
    var secondRange: ClosedRange<Int> = 0...59
    var secondStep: Int = 1

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { time.components.m },
            set: { time = .fromMinSec(minutes: $0, seconds: time.components.s) }
        )
    }
    private var secondsBinding: Binding<Int> {
        Binding(
            get: { time.components.s },
            set: { time = .fromMinSec(minutes: time.components.m, seconds: $0) }
        )
    }
    private var secondOptions: [Int] {
        stride(from: secondRange.lowerBound, through: secondRange.upperBound, by: max(1, secondStep)).map { $0 }
    }

    var body: some View {
        HStack(spacing: 16) {
            Picker("Minutes", selection: minutesBinding) {
                ForEach(Array(minuteRange), id: \.self) { m in
                    Text("\(m) min")
                        .monospacedDigit()
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)      // ← let it breathe
            .layoutPriority(1)                // ← win space in the HStack

            Picker("Seconds", selection: secondsBinding) {
                ForEach(secondOptions, id: \.self) { s in
                    Text("\(s) sec")
                        .monospacedDigit()
                        .tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
        }
        .labelsHidden() // hide the picker titles; units are in-row
    }
}
