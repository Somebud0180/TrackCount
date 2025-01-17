//
//  TimeWheelPickerView.swift
//  TrackCount
//
//  A time picker featuring a wheel style picker
//


import SwiftUI

struct TimeWheelPickerView: View {
    enum ModifySeconds {
        case first(Int)
        case second([Int])
    }
    
    @Binding var modifySeconds: ModifySeconds
    @Binding var isPickerMoving: Bool
    
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
                isPickerMoving = true
                handlePickerChange()
            }
            
            let isOneHour = {
                switch modifySeconds {
                case .first(let total):
                    return total >= 3600 && total < 7199
                case .second(let array):
                    guard array.count >= 1 else { return false }
                    return array[0] == 1
                default:
                    return false
                }
            }()
            
            Text(isOneHour ? "hr" : "hrs")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            
            Spacer()
            
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
                isPickerMoving = true
                handlePickerChange()
            }
            
            Text("m")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            
            Spacer()
            
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
                isPickerMoving = true
                handlePickerChange()
            }
            
            Text("s")
                .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
        }
        .onAppear {
            initializeFromTotalSeconds()
        }
    }
    
    /// Handles simultaneous picker changes
    func handlePickerChange() {
        // Update total seconds immediately
        updateTotalSeconds()
        
        // Cancel any existing timer for picker movement state
        debounceTimer?.invalidate()
        
        // Create new timer that will fire after picker stops moving
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            isPickerMoving = false
        }
    }
    
    /// Updates total seconds with data combined from each separate wheel
    func updateTotalSeconds() {
        // Validate ranges
        hours = min(max(hours, hourRange.lowerBound), hourRange.upperBound)
        minutes = min(max(minutes, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
        seconds = min(max(seconds, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
        
        switch modifySeconds {
        case .first:
            let totalSeconds = hours * 3600 + minutes * 60 + seconds
            modifySeconds = .first(totalSeconds)
        case .second:
            modifySeconds = .second([hours, minutes, seconds])
        }
    }
    
    /// Fills up with data from existing totalSeconds into each separate wheel
    func initializeFromTotalSeconds() {
        switch modifySeconds {
        case .first(let total):
            hours = total / 3600
            minutes = (total % 3600) / 60
            seconds = total % 60
        case .second(let array):
            if array.count >= 3 {
                hours = min(max(array[0], 0), 23)
                minutes = min(max(array[1], 0), 59)
                seconds = min(max(array[2], 0), 59)
            } else {
                // Default values if array is incomplete
                hours = 0
                minutes = 0
                seconds = 0
            }
        }
        
        // Validate ranges
        hours = min(max(hours, hourRange.lowerBound), hourRange.upperBound)
        minutes = min(max(minutes, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
        seconds = min(max(seconds, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
    }
}

#Preview {
    // Sample variable to pass to the picker
    @Previewable @State var testSeconds = 0
    @Previewable @State var isPickerMoving = false
    
    TimeWheelPickerView(
        modifySeconds: Binding(
            get: { .first(testSeconds ?? 0) },
            set: { newValue in
                if case .first(let value) = newValue {
                    testSeconds = value
                }
            }
        ),
        isPickerMoving: $isPickerMoving
    )
}
