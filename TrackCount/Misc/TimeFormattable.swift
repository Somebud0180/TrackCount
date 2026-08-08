//
//  TimeFormattable.swift
//  TrackCount
//
//  Contains logic for formatting time
//

import Foundation

func accessibleTimeFormat(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60
    
    let minuteString = "\(minutes) minute\(minutes == 1 ? "" : "s")"
    let secondString = "\(secs) second\(secs == 1 ? "" : "s")"
    
    if hours > 0 {
        let hourString = "\(hours) hour\(hours == 1 ? "" : "s")"
        return "\(hourString), \(minuteString), and \(secondString)"
    } else {
        return "\(minuteString) and \(secondString)"
    }
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
