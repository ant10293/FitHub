//
//  TimerManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

// TODO: remove workoutTimer
final class TimerManager: ObservableObject {
    // MARK: - Rest (countdown by date)
    @Published var restIsActive: Bool = false
    @Published var restTotalSeconds: Int = 0
    @Published var restStartAt: Date? = nil

    // MARK: - Hold (classic decrementing countdown)
    @Published var holdTimeRemaining: Int = 0
    @Published var holdIsActive: Bool = false
    @Published var holdTotalSeconds: Int = 0
    private var holdTimer: Timer?

    deinit {
        holdTimer?.invalidate()
        print("timer denitialized")
    }
    
    func stopAll() {
        stopRest()
        stopHold()
    }

    // MARK: - REST (Timeline-driven via SimpleStopwatch style)
    func startRest(for seconds: Int, startDate: Date? = nil) {
        let clamped = max(0, seconds)
        guard clamped > 0 else {
            stopRest()
            return
        }
        restTotalSeconds = clamped
        restStartAt = startDate ?? Date()
        restIsActive = true
    }

    func stopRest() {
        restIsActive = false
        restTotalSeconds = 0
        restStartAt = nil
    }
    
    func restTimeRemaining(at referenceDate: Date = Date()) -> Int {
        guard restIsActive, let start = restStartAt else { return 0 }
        let elapsed = max(0, Int(referenceDate.timeIntervalSince(start).rounded()))
        let remaining = max(0, restTotalSeconds - elapsed)
        if remaining == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.stopRest()
            }
        }
        return remaining
    }

    // MARK: - HOLD (classic decrementing via shared startCountdown/resumeCountdown)
    func startHold(totalSeconds: Int, initialElapsed: Int = 0) {
        startCountdown(
            seconds: totalSeconds,
            initialElapsed: initialElapsed,
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

    // MARK: - Shared countdown engine (used for hold timers, etc.)
    private enum CountdownMode {
        case decrementing
        case dateDriven(startAt: ReferenceWritableKeyPath<TimerManager, Date?>,
                        startDate: Date?)
    }
    
    private func startCountdown(
        seconds: Int,
        initialElapsed: Int = 0,
        total: ReferenceWritableKeyPath<TimerManager, Int>,
        remaining: ReferenceWritableKeyPath<TimerManager, Int>,
        isActive: ReferenceWritableKeyPath<TimerManager, Bool>,
        timerStorage: ReferenceWritableKeyPath<TimerManager, Timer?>,
        mode: CountdownMode = .decrementing
    ) {
        // cancel existing timer of this kind
        self[keyPath: timerStorage]?.invalidate()

        // seed totals/flags
        self[keyPath: total] = max(1, seconds)
        self[keyPath: isActive] = true
        
        switch mode {
        case .decrementing:
            let clampedElapsed = max(0, min(initialElapsed, self[keyPath: total]))
            self[keyPath: remaining] = max(0, self[keyPath: total] - clampedElapsed)
            
        case .dateDriven(let startAtKeyPath, let startDate):
            self[keyPath: startAtKeyPath] = startDate ?? Date()
            let elapsed = CalendarUtility.secondsSince(self[keyPath: startAtKeyPath])
            self[keyPath: remaining] = max(0, self[keyPath: total] - elapsed)
        }

        // schedule ticks
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            
            switch mode {
            case .decrementing:
                if self[keyPath: remaining] > 0 {
                    self[keyPath: remaining] -= 1
                } else {
                    timer.invalidate()
                    self[keyPath: isActive] = false
                }
                
            case .dateDriven(let startAtKeyPath, _):
                let elapsed = CalendarUtility.secondsSince(self[keyPath: startAtKeyPath])
                self[keyPath: remaining] = max(0, self[keyPath: total] - elapsed)
                if self[keyPath: remaining] <= 0 {
                    timer.invalidate()
                    self[keyPath: isActive] = false
                    self[keyPath: startAtKeyPath] = nil
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
        if let startAt {
            self[keyPath: startAt] = nil
        }
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
