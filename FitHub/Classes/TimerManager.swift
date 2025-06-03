//
//  TimerManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation


class TimerManager: ObservableObject {
    @Published var secondsElapsed: Int = 0
    @Published var timerIsActive: Bool = false
    private var timer: Timer?
    
    // new “rest clock”
    @Published var restTimeRemaining: Int = 0
    @Published var restIsActive: Bool = false
    private var restTimer: Timer?
    
    func startTimer() {
        // 1. Invalidate any existing timer
        timer?.invalidate()

        // 2. Flip the flag (will redraw your play/pause button)
        timerIsActive = true

        // 3. Schedule a 1-s repeating timer…
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsElapsed += 1
        }

        // 4. Add to the main run-loop in the common mode so it fires during scrolling, sheets, etc.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    
    func stopTimer() {
        timerIsActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        stopTimer()
        secondsElapsed = 0
    }
    
    /// start a rest countdown
    func startRest(for seconds: Int) {
      restTimer?.invalidate()
      restTimeRemaining = seconds
      restIsActive = true

      // add to .common to survive scrolls, modal changes, etc.
      let t = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
        guard let self = self else { timer.invalidate(); return }
        if self.restTimeRemaining > 0 {
          self.restTimeRemaining -= 1
        } else {
          timer.invalidate()
          self.restIsActive = false
        }
      }
      restTimer = t
      RunLoop.main.add(t, forMode: .common)
    }

    /// cancel a rest countdown
    func stopRest() {
      restTimer?.invalidate()
      restTimer = nil
      restIsActive = false
      restTimeRemaining = 0
    }
    
    deinit {
        timer?.invalidate()
        print("TimerManager deallocated")
    }
}

