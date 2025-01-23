//
//  TimeFormattable.swift
//  TrackCount
//
//  Contains logic for formatting time integers to a human readable format.
//


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