//
//  TimerHeader.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/3/25.
//

import SwiftUI

struct TimerHeader: View {
    @ObservedObject var timer: TimerManager

    var body: some View {
        HStack {
            Text(Format.timeString(from: timer.secondsElapsed))
                .font(.largeTitle)
                .monospacedDigit()
                .padding()
            
            //playPauseButton
        }
    }
    
   /*private var playPauseButton: some View {
        Button(action: timerToggle) {
            Image(systemName: timer.isActive ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(timer.isActive ? .yellow : .green)
                .background(Circle().fill(Color.black))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
    
    private func timerToggle() {
        if timer.isActive {
            timer.stopTimer()
        } else {
            timer.startTimer()
        }
    }*/
}

