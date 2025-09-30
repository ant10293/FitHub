//
//  SimpleStopwatch.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/27/25.
//

import SwiftUI

struct SimpleStopwatch: View {
    let start: Date
    let isStopped: Bool
    @State private var frozenSeconds: Int? = nil

    var body: some View {
        Group {
            if isStopped {
                Text(Format.timeString(from: frozenSeconds ?? currentElapsed))
                    .monospacedDigit()
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(Format.timeString(from: currentElapsed))
                        .monospacedDigit()
                }
            }
        }
        .onChange(of: isStopped) { _, nowStopped in
            frozenSeconds = nowStopped ? currentElapsed : nil
        }
    }

    private var currentElapsed: Int {
        max(0, CalendarUtility.secondsSince(start))
    }
}
