//
//  TimeFormattable.swift
//  TrackCount
//
//  Contains logic for formatting time
//

import Foundation

func accessibleTimeFormat(_ seconds: TimeInterval, secondsOnZero: Bool = false) -> String {
    let total = Int(seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60
    
    var components: [String] = []
    
    if hours > 0 {
        components.append("\(hours) hour\(hours == 1 ? "" : "s")")
    }
    if minutes > 0 {
        components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
    }
    if secs > 0 {
        components.append("\(secs) second\(secs == 1 ? "" : "s")")
    }
    
    if components.isEmpty {
        return secondsOnZero ? "0 seconds" : "0"
    }
    
    if components.count == 1 {
        return components[0]
    }
    
    let last = components.removeLast()
    return components.joined(separator: ", ") + " and " + last
}

protocol TimeFormattable {
    func wholeSeconds() -> Int
}

extension TimeFormattable {
    func formatTime() -> String {
        let totalSeconds = wholeSeconds()
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}

extension Int: TimeFormattable {
    func wholeSeconds() -> Int {
        return self
    }
}

extension Double: TimeFormattable {
    func wholeSeconds() -> Int {
        return Int(self)
    }
}
