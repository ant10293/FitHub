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
    var showing: InputKey
    var time: TimeSpan
    var speed: Speed
    
    enum InputKey: String, Codable, Equatable { case time, speed }
    
    // Computed properties for the non-key value (distance passed as parameter)
    func computedTime(distance: Distance) -> TimeSpan {
        switch showing {
        case .time: return time
        case .speed: return Speed.timeFromSpeed(speed, distance: distance)
        }
    }
    
    func computedSpeed(distance: Distance) -> Speed {
        switch showing {
        case .time: return Speed.speedFromTime(time, distance: distance)
        case .speed: return speed
        }
    }
    
    func getMetric(for key: InputKey, distance: Distance) -> Any {
        switch key {
        case .time: return computedTime(distance: distance)
        case .speed: return computedSpeed(distance: distance)
        }
    }
    
    // Mutating methods to update the key value
    mutating func updateTime(_ newTime: TimeSpan, distance: Distance) {
        time = newTime
        // Update speed based on new time
        if showing == .time {
            speed = Speed.speedFromTime(newTime, distance: distance)
        }
    }
    
    mutating func updateSpeed(_ newSpeed: Speed, distance: Distance) {
        speed = newSpeed
        // Update time based on new speed
        if showing == .speed {
            time = Speed.timeFromSpeed(newSpeed, distance: distance)
        }
    }
    
    // Validation
    func isValid(distance: Distance) -> Bool {
        switch showing {
        case .time: return time.inSeconds > 0
        case .speed: return speed.inKmH > 0
        }
    }
    
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
}
extension TimeOrSpeed {
    var label: String {
        switch showing {
        case .speed:
            return UnitSystem.current.speedUnit
        case .time:
            return "Time"
        }
    }
    
    var fieldString: String {
        switch showing {
        case .speed:
            return speed.inKmH > 0 ? speed.displayString : ""
        case .time:
            return speed.inKmH > 0 ? time.displayStringCompact : ""
        }
    }
    
    var actualValue: Double {
        switch showing {
        case .speed:
            return Double(speed.inKmH)
        case .time:
            return Double(time.inSeconds)
        }
    }
}
