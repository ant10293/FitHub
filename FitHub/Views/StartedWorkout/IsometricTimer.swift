//
//  IsometricTimer.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/15/25.
//

import SwiftUI


struct IsometricTimerRing: View {
    @ObservedObject var manager: TimerManager
    let holdSeconds: Int   // e.g., 30 or whatever you want as the default
    let onCompletion: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Track
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.25)
                    .foregroundStyle(.gray)
                
                // Progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                Text("\(Format.timeString(from: manager.holdTimeRemaining))")
                    .font(.largeTitle).bold()
                    .monospacedDigit()
            }
            .padding(.horizontal)
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
                    onCompletion(secElapsed)
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
            .padding(.top)
        }
        .padding()
        .onAppear(perform: toggleHold)
        .onChange(of: manager.holdTimeRemaining) {
            if progress == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onCompletion(secElapsed) // close one second after completion
                }
            }
        }
    }
    
    // Progress for the HOLD countdown
    private var progress: CGFloat {
        guard manager.holdTotalSeconds > 0 else { return 0 }
        let done = secElapsed
        let prog = CGFloat(done) / CGFloat(max(manager.holdTotalSeconds, 1))
        return prog
    }

    // Derive states
    private var isRunning: Bool { manager.holdIsActive }
    private var isPaused: Bool { !manager.holdIsActive && manager.holdTotalSeconds > 0 && manager.holdTimeRemaining > 0 }
    private var isIdle: Bool { manager.holdTotalSeconds == 0 || manager.holdTimeRemaining == 0 }
    private var secElapsed: Int { max(0, manager.holdTotalSeconds - manager.holdTimeRemaining) }

    private func toggleHold() {
        if isRunning {
            manager.pauseHold()
        } else if isPaused {
            manager.resumeHold()
        } else {
            // Idle: arm a new hold with the default duration
            manager.startHold(for: holdSeconds)
        }
    }
}
