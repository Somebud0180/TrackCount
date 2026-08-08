//
//  TimeWheelPickerView.swift
//  TrackCount
//
//  //  A time picker featuring a wheel style picker
//
//
import SwiftUI

struct TimeWheelPickerView: View {
    @Binding var timerArray: [Int] // Assumes array has 3 elements
    
    // Add array validation
    init(timerArray: Binding<[Int]>) {
        self._timerArray = timerArray
        // Validate array has 3 elements
        guard timerArray.wrappedValue.count == 3 else {
            fatalError("TimeWheelPickerView requires timerArray with exactly 3 elements")
        }
        // Initialize state from array
        _hours = State(initialValue: timerArray.wrappedValue[0])
        _minutes = State(initialValue: timerArray.wrappedValue[1])
        _seconds = State(initialValue: timerArray.wrappedValue[2])
    }
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var debounceTimer: Timer?
    @State private var hoursMoving: Bool = false
    @State private var minutesMoving: Bool = false
    @State private var secondsMoving: Bool = false
    
    let hoursRange = 0...23
    let minutesRange = 0...59
    let secondsRange = 0...59
    
    var body: some View {
        let isOneHour = timerArray[0] == 1
        
        HStack() {
            TimePickerView(title: isOneHour ? "hour" : "hours",
                           range: hoursRange,
                           binding: $hours)
            TimePickerView(title: "min",
                           range: minutesRange,
                           binding: $minutes)
            TimePickerView(title: "sec",
                           range: secondsRange,
                           binding: $seconds)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .onAppear {
            initializeFromTimerArray()
        }
        .onDisappear {
            debounceTimer?.invalidate()
            debounceTimer = nil
        }
    }
    
    /// Fills up with data from existing timer array into each separate wheel
    func initializeFromTimerArray() {
        if timerArray.count >= 3 {
            hours = min(max(timerArray[0], 0), 23)
            minutes = min(max(timerArray[1], 0), 59)
            seconds = min(max(timerArray[2], 0), 59)
        } else {
            hours = 0
            minutes = 0
            seconds = 0
            timerArray = [0, 0, 0]
        }
    }
}

#Preview {
    // Sample variable to pass to the picker
    @Previewable @State var previewtimerArray = [0, 0, 0]
    
    TimeWheelPickerView(
        timerArray: $previewtimerArray
    )
}
