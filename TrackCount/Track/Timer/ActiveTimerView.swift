//
//  ActiveTimerView.swift
//  TrackCount
//
//  A view containing the timer ring and time remaining
//

import SwiftUI

struct ActiveTimerView: View {
    let cardTitle: String
    let targetEndDate: Date?
    let totalTime: Double
    let isPaused: Bool
    let pausedRemaining: Double
    let primaryColor: Color
    let secondaryColor: Color
    let isCompleted: Bool
    
    var body: some View {
        TimelineView(.animation(paused: isPaused || isCompleted)) { context in
            let remainingTime: Double = {
                if isCompleted {
                    return 0
                } else if isPaused {
                    return pausedRemaining
                } else if let targetEndDate = targetEndDate {
                    return max(0, targetEndDate.timeIntervalSince(context.date))
                } else {
                    return 0
                }
            }()
            
            let progress = Float(remainingTime / max(1, totalTime))
            
            ZStack(alignment: .center) {
                // Background Track
                Circle()
                    .stroke(lineWidth: 16)
                    .opacity(0.3)
                    .foregroundColor(primaryColor)
                
                // Continuous Smooth Progress Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .foregroundColor(primaryColor)
                    .rotationEffect(.degrees(-90))
                
                // Countdown Text
                if isCompleted {
                    Text("Time's Up!")
                        .font(.system(.title, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                } else {
                    Text(remainingTime.formatTime())
                        .font(.system(.largeTitle, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(cardTitle) Timer")
            .accessibilityValue(isCompleted ? "Time's Up!" : accessibleTimeFormat(remainingTime))
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
