//
//  IsometricTimer.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/15/25.
//

import SwiftUI


import SwiftUI

struct IsometricTimerRing: View {
    @ObservedObject var manager: TimerManager
    let defaultHoldSeconds: Int   // e.g., 30 or whatever you want as the default

    // Progress for the HOLD countdown
    private var progress: CGFloat {
        guard manager.holdTotalSeconds > 0 else { return 0 }
        let done = manager.holdTotalSeconds - manager.holdTimeRemaining
        return CGFloat(done) / CGFloat(max(manager.holdTotalSeconds, 1))
    }

    // Derive states
    private var isRunning: Bool { manager.holdIsActive }
    private var isPaused: Bool { !manager.holdIsActive && manager.holdTotalSeconds > 0 && manager.holdTimeRemaining > 0 }
    private var isIdle: Bool { manager.holdTotalSeconds == 0 || manager.holdTimeRemaining == 0 }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Track
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.25)
                    .foregroundStyle(.gray)

                // Progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)

                // Label: show remaining seconds (or "0 s" if idle)
                Text("\(Format.timeString(from: manager.holdTimeRemaining))")
                    .font(.largeTitle).bold()
                    .monospacedDigit()
            }
            .accessibilityLabel("Isometric hold timer")
            .accessibilityValue("\(manager.holdTimeRemaining) seconds remaining")

            // Controls
            HStack(spacing: 12) {
                Button {
                    toggleHold()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(isRunning ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2)))
                }
                .accessibilityLabel(isRunning ? "Pause hold" : (isPaused ? "Resume hold" : "Start hold"))

                Button(role: .destructive) {
                    manager.stopHold()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().strokeBorder(Color.red.opacity(0.6)))
                }
                .accessibilityLabel("Reset hold")
            }
        }
    }

    private func toggleHold() {
        if isRunning {
            manager.pauseHold()
        } else if isPaused {
            manager.resumeHold()
        } else {
            // Idle: arm a new hold with the default duration
            manager.startHold(for: defaultHoldSeconds)
        }
    }
}
