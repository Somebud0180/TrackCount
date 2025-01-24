//
//  TimeWheelPickerView.swift
//  TrackCount
//
//  A time picker featuring a wheel style picker
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
    
    let hourRange = 0...23
    let minuteSecondRange = 0...59
    
    var body: some View {
        HStack {
            // Hours Picker and Text
            Picker("Hours", selection: $hours) {
                ForEach(hourRange, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                        .font(.title3)
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 80)
            .onChange(of: hours) {
                hours = min(max(hours, hourRange.lowerBound), hourRange.upperBound)
                timerArray[0] = hours
            }
            
            let isOneHour = timerArray[0] == 1
            Text(isOneHour ? "hr" : "hrs")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
                .accessibilityLabel("hours")
            
            Spacer()
            
            // Minutes Picker and Text
            Picker("Minutes", selection: $minutes) {
                ForEach(minuteSecondRange, id: \.self) { minute in
                    Text("\(minute)").tag(minute)
                        .font(.title3)
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 80)
            .onChange(of: minutes) {
                minutes = min(max(minutes, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
                timerArray[1] = minutes
            }
            
            Text("m")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
                .accessibilityLabel("minutes")
            
            Spacer()
            
            // Seconds Picker and Text
            Picker("Seconds", selection: $seconds) {
                ForEach(minuteSecondRange, id: \.self) { second in
                    Text("\(second)").tag(second)
                        .font(.title3)
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 80)
            .onChange(of: seconds) {
                seconds = min(max(seconds, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
                timerArray[2] = seconds
            }
            
            Text("s")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
                .accessibilityLabel("seconds")
        }
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
