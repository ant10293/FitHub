//
//  DurationPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/1/25.
//

import SwiftUI

struct DurationPicker: View {
    /// - Stored as seconds in the `Time` type
    @Binding var time: TimeSpan

    var hourRange: ClosedRange<Int> = 0...23
    var minuteRange: ClosedRange<Int> = 0...59
    var minuteStep: Int = 1

    // ── helpers -----------------------------------------------------------
    private var hoursBinding: Binding<Int> {
        Binding(
            get: { time.components.h },
            set: { newHours in
                let mins = time.components.m
                time = .hrMinToSec(hours: newHours, minutes: mins)
            }
        )
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { time.components.m },
            set: { newMinutes in
                let hrs = time.components.h
                time = .hrMinToSec(hours: hrs, minutes: newMinutes)
            }
        )
    }

    private var minuteOptions: [Int] {
        stride(from: minuteRange.lowerBound,
               through: minuteRange.upperBound,
               by: max(1, minuteStep)).map { $0 }
    }

    // ── view --------------------------------------------------------------
    var body: some View {
        HStack(spacing: 16) {
            // Hours wheel
            Picker("Hours", selection: hoursBinding) {
                ForEach(Array(hourRange), id: \.self) { h in
                    Text("\(h) hr").tag(h)
                }
            }
            .pickerStyle(.wheel)
            .clipped()

            // Minutes wheel
            Picker("Minutes", selection: minutesBinding) {
                ForEach(minuteOptions, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .clipped()
        }
        .labelsHidden()
    }
}

