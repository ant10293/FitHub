//
//  Cardio.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/23/25.
//

import Foundation
import SwiftUI

// TODO: should be init() from PeakMetric, PeakMetric should also be init() from these
// incline will be an ExerciseEquipment adjustment
struct TimeOrSpeed: Codable, Equatable, Hashable {
    var showing: InputKey = .speed
    var time: TimeSpan
    var speed: Speed
    
    // MARK: - Inits
    init(showing: InputKey, time: TimeSpan, speed: Speed) {
        self.showing = showing
        self.time = time
        self.speed = speed
    }
    init(time: TimeSpan, distance: Distance) {
        self.showing = .time
        self.time = time
        self.speed = Speed.speedFromTime(time, distance: distance)
    }
    init(speed: Speed, distance: Distance) {
        self.showing = .speed
        self.speed = speed
        self.time = Speed.timeFromSpeed(speed, distance: distance)
    }
    init() {
        self.showing = .time
        self.time = .init(seconds: 0)
        self.speed = .init(kmh: 0)
    }
    
    enum InputKey: String, Codable, Equatable, CaseIterable { case time, speed }

    // MARK: - Mutating setters
    mutating func updateTime(_ newTime: TimeSpan, distance: Distance, keyOverride: InputKey? = nil) {
        time = newTime
        // Update speed based on new time
        let key = keyOverride ?? showing
        if key == .time {
            guard distance.inKm > 0 else { return }
            speed = Speed.speedFromTime(newTime, distance: distance)
        }
    }
    mutating func updateSpeed(_ newSpeed: Speed, distance: Distance, keyOverride: InputKey? = nil) {
        speed = newSpeed
        // Update time based on new speed
        let key = keyOverride ?? showing
        if key == .speed {
            guard distance.inKm > 0 else { return }
            time = Speed.timeFromSpeed(newSpeed, distance: distance)
        }
    }
}

extension TimeOrSpeed {
    var label: String {
        switch showing {
        case .speed: return UnitSystem.current.speedUnit
        case .time: return "Time"
        }
    }
    
    var fieldString: String {
        switch showing {
        case .speed: return speed.fieldString
        case .time: return time.fieldString
        }
    }
    
    var actualValue: Double {
        switch showing {
        case .speed: return Double(speed.inKmH)
        case .time: return Double(time.inSeconds)
        }
    }
}
