//
//  TimeWheelPickerView.swift
//  TrackCount
//
//  A time picker featuring a wheel style picker
//


import SwiftUI

struct TimePickerView: View {
    @Binding var totalSeconds: Int
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    let hourRange = 0...23
    let minuteSecondRange = 0...59
    
    var body: some View {
        HStack {
            Picker("Hours", selection: $hours) {
                ForEach(hourRange, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 60)
            .onChange(of: hours) { updateTotalSeconds() }
            
            let isOneHour = totalSeconds >= 3600 && totalSeconds < 7199
            Text(isOneHour ? "hr" : "hrs")
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            
            Spacer()
            
            Picker("Minutes", selection: $minutes) {
                ForEach(minuteSecondRange, id: \.self) { minute in
                    Text("\(minute)").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 60)
            .onChange(of: minutes) { updateTotalSeconds() }
            
            Text("m")
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            
            Spacer()
            
            Picker("Seconds", selection: $seconds) {
                ForEach(minuteSecondRange, id: \.self) { second in
                    Text("\(second)").tag(second)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 45, maxWidth: 60)
            .onChange(of: seconds) { updateTotalSeconds() }
            
            Text("s")
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.2)
                .lineLimit(1)
        }
        .onAppear {
            initializeFromTotalSeconds()
        }
    }
    
    private func updateTotalSeconds() {
        totalSeconds = hours * 3600 + minutes * 60 + seconds
    }
    
    private func initializeFromTotalSeconds() {
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }
}

#Preview {
    // Sample variable to pass to the picker
    @Previewable @State var testSeconds = 0
    TimePickerView(totalSeconds: $testSeconds)
}
