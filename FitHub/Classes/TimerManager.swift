//
//  TimerManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

final class TimerManager: ObservableObject {
    // MARK: - Workout (stopwatch by date)
    @Published var secondsElapsed: Int = 0
    @Published var isActive: Bool = false
    @Published var workoutStartAt: Date? = nil
    private var workoutTimer: Timer?

    // MARK: - Rest (countdown by date)
    @Published var restTimeRemaining: Int = 0
    @Published var restIsActive: Bool = false
    @Published var restTotalSeconds: Int = 0
    @Published var restStartAt: Date? = nil
    private var restTimer: Timer?

    // MARK: - Hold (classic decrementing countdown)
    @Published var holdTimeRemaining: Int = 0
    @Published var holdIsActive: Bool = false
    @Published var holdTotalSeconds: Int = 0
    private var holdTimer: Timer?

    deinit {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        holdTimer?.invalidate()
    }

    // MARK: - WORKOUT (stopwatch, date-driven)
    func startTimer(startDate: Date? = nil) {
        workoutTimer?.invalidate()
        isActive = true
        workoutStartAt = startDate ?? Date()
        tickWorkout()

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickWorkout()
        }
        RunLoop.main.add(t, forMode: .common)
        workoutTimer = t
    }

    func stopTimer() {
        isActive = false
        workoutTimer?.invalidate()
    }
    
    func resetTimer() {
        workoutTimer = nil
        workoutStartAt = nil
        secondsElapsed = 0
    }

    private func tickWorkout() {
        secondsElapsed = CalendarUtility.secondsSince(workoutStartAt)
    }

    // MARK: - REST (countdown, date-driven via shared startCountdown)
    func startRest(for seconds: Int, startDate: Date? = nil) {
        startCountdown(
            seconds: seconds,
            total: \.restTotalSeconds,
            remaining: \.restTimeRemaining,
            isActive: \.restIsActive,
            timerStorage: \.restTimer,
            mode: .dateDriven(startAt: \.restStartAt, startDate: startDate)
        )
    }

    func stopRest() {
        stopCountdown(
            total: \.restTotalSeconds,
            remaining: \.restTimeRemaining,
            isActive: \.restIsActive,
            timerStorage: \.restTimer,
            startAt: \.restStartAt
        )
    }

    // MARK: - HOLD (classic decrementing via shared startCountdown/resumeCountdown)
    func startHold(for seconds: Int) {
        startCountdown(
            seconds: seconds,
            total: \.holdTotalSeconds,
            remaining: \.holdTimeRemaining,
            isActive: \.holdIsActive,
            timerStorage: \.holdTimer,
            mode: .decrementing
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

    func stopHold() {
        stopCountdown(
            total: \.holdTotalSeconds,
            remaining: \.holdTimeRemaining,
            isActive: \.holdIsActive,
            timerStorage: \.holdTimer
        )
    }

    // MARK: - Shared countdown engine

    private enum CountdownMode {
        case decrementing
        case dateDriven(startAt: ReferenceWritableKeyPath<TimerManager, Date?>,
                        startDate: Date?)
    }

    private func startCountdown(
        seconds: Int,
        total: ReferenceWritableKeyPath<TimerManager, Int>,
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>,
        mode: CountdownMode
    ) {
        // cancel existing timer of this kind
        self[keyPath: timerStorage]?.invalidate()

        // seed totals/flags
        self[keyPath: total] = max(1, seconds)
        self[keyPath: isActive] = true

        // set startAt for date-driven, and compute initial remaining
        switch mode {
        case .dateDriven(let startAtKP, let startDate):
            self[keyPath: startAtKP] = startDate ?? Date()
            let elapsed = CalendarUtility.secondsSince(self[keyPath: startAtKP])
            self[keyPath: remaining] = max(0, self[keyPath: total] - elapsed)

        case .decrementing:
            self[keyPath: remaining] = self[keyPath: total]
        }

        // schedule ticks
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }

            switch mode {
            case .dateDriven(let startAtKP, _):
                let elapsed = CalendarUtility.secondsSince(self[keyPath: startAtKP])
                self[keyPath: remaining] = max(0, self[keyPath: total] - elapsed)
                if self[keyPath: remaining] <= 0 {
                    timer.invalidate()
                    self[keyPath: isActive] = false
                    self[keyPath: startAtKP] = nil
                }

            case .decrementing:
                if self[keyPath: remaining] > 0 {
                    self[keyPath: remaining] -= 1
                } else {
                    timer.invalidate()
                    self[keyPath: isActive] = false
                }
            }
        }
        self[keyPath: timerStorage] = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func stopCountdown(
        total: ReferenceWritableKeyPath<TimerManager, Int>,
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>,
        startAt: ReferenceWritableKeyPath<TimerManager, Date?>? = nil
    ) {
        self[keyPath: timerStorage]?.invalidate()
        self[keyPath: timerStorage] = nil
        self[keyPath: isActive] = false
        self[keyPath: remaining] = 0
        self[keyPath: total] = 0
        if let startAt { self[keyPath: startAt] = nil }
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
