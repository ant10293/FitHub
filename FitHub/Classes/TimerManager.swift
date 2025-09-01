//
//  TimerManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class TimerManager: ObservableObject {
    @Published var secondsElapsed: Int = 0
    @Published var isActive: Bool = false
    private var timer: Timer?

    // Rest
    @Published var restTimeRemaining: Int = 0
    @Published var restIsActive: Bool = false
    @Published var restTotalSeconds: Int = 0
    private var restTimer: Timer?

    // Hold
    @Published var holdTimeRemaining: Int = 0
    @Published var holdIsActive: Bool = false
    @Published var holdTotalSeconds: Int = 0
    private var holdTimer: Timer?

    // MARK: - Public API

    func startRest(for seconds: Int) {
        startCountdown(
            seconds: seconds,
            total: \.restTotalSeconds,
            remaining: \.restTimeRemaining,
            isActive: \.restIsActive,
            timerStorage: \.restTimer
        )
    }

    func stopRest() {
        stopCountdown(
            total: \.restTotalSeconds,
            remaining: \.restTimeRemaining,
            isActive: \.restIsActive,
            timerStorage: \.restTimer
        )
    }

    func pauseHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdIsActive = false
    }
    
    func resumeHold() {
        guard holdTimeRemaining > 0, holdTotalSeconds > 0, holdIsActive == false else { return }
        resumeCountdown(
            remaining: \.holdTimeRemaining,
            isActive: \.holdIsActive,
            timerStorage: \.holdTimer
        )
    }
    
    func startHold(for seconds: Int) {
        startCountdown(
            seconds: seconds,
            total: \.holdTotalSeconds,
            remaining: \.holdTimeRemaining,
            isActive: \.holdIsActive,
            timerStorage: \.holdTimer
        )
    }

    func stopHold() {
        stopCountdown(
            total: \.holdTotalSeconds,
            remaining: \.holdTimeRemaining,
            isActive: \.holdIsActive,
            timerStorage: \.holdTimer
        )
    }

    // MARK: - Stopwatch (unchanged)
    func startTimer() {
        timer?.invalidate()
        isActive = true
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.secondsElapsed += 1
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        stopTimer()
        secondsElapsed = 0
    }

    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
        holdTimer?.invalidate()
    }

    // MARK: - Shared countdown logic

    private func startCountdown(
        seconds: Int,
        total: ReferenceWritableKeyPath<TimerManager, Int>,
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>
    ) {
        // cancel any existing timer of this kind
        self[keyPath: timerStorage]?.invalidate()

        self[keyPath: total] = max(1, seconds)
        self[keyPath: remaining] = self[keyPath: total]
        self[keyPath: isActive] = true

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self[keyPath: remaining] > 0 {
                self[keyPath: remaining] -= 1
            } else {
                timer.invalidate()
                self[keyPath: isActive] = false
            }
        }
        self[keyPath: timerStorage] = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func stopCountdown(
        total: ReferenceWritableKeyPath<TimerManager, Int>,
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>
    ) {
        self[keyPath: timerStorage]?.invalidate()
        self[keyPath: timerStorage] = nil
        self[keyPath: isActive] = false
        self[keyPath: remaining] = 0
        self[keyPath: total] = 0
    }
    
    private func resumeCountdown(
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>
    ) {
        self[keyPath: timerStorage]?.invalidate()
        self[keyPath: isActive] = true

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self[keyPath: remaining] > 0 {
                self[keyPath: remaining] -= 1
            } else {
                timer.invalidate()
                self[keyPath: isActive] = false
            }
        }
        self[keyPath: timerStorage] = t
        RunLoop.main.add(t, forMode: .common)
    }
}
