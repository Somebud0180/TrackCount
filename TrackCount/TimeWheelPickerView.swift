//
//  TimeWheelPickerView.swift
//  TrackCount
//
//  A time picker featuring a wheel style picker
//


import SwiftUI

struct TimePickerView: View {
    @Binding var totalSeconds: Int
    @Binding var isPickerMoving: Bool

    @State var hours: Int = 0
    @State var minutes: Int = 0
    @State var seconds: Int = 0
    @State var debounceTimer: Timer?
    
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
            .onChange(of: hours) { handlePickerChange() }
            
            let isOneHour = totalSeconds >= 3600 && totalSeconds < 7199
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
            .onChange(of: minutes) { handlePickerChange() }
            
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
            .onChange(of: seconds) { handlePickerChange() }
            
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
        // Set flag to indicate picker is moving
        isPickerMoving = true

        // Cancel any existing timer
        debounceTimer?.invalidate()
        
        // Create new timer that will fire after picker stops moving
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            updateTotalSeconds()
        }
    }
    
    /// Updates total seconds with data combined from each separate wheel
    func updateTotalSeconds() {
        // Clamp values as a safeguard
        hours = min(max(hours, hourRange.lowerBound), hourRange.upperBound)
        minutes = min(max(minutes, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
        seconds = min(max(seconds, minuteSecondRange.lowerBound), minuteSecondRange.upperBound)
        totalSeconds = hours * 3600 + minutes * 60 + seconds
    }
    
    /// Fills up with data from existing totalSeconds into each separate wheel
    func initializeFromTotalSeconds() {
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }
    
}

#Preview {
    // Sample variable to pass to the picker
    @Previewable @State var testSeconds = 0
    @Previewable @State var isPickerMoving = false
    TimePickerView(totalSeconds: $testSeconds, isPickerMoving: $isPickerMoving)
}
