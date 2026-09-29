//
//  TimePickerView.swift
//  TrackCount
//
//  Referenced from https://digitalbunker.dev/recreating-the-ios-timer-in-swiftui/
//  By Aryaman Sharda
//

import SwiftUI

struct TimePickerView: View {
    private let pickerViewTitlePadding: CGFloat = 4

    let title: String
    let range: ClosedRange<Int>
    let binding: Binding<Int>

    var body: some View {
        HStack(spacing: -pickerViewTitlePadding) {
            Picker(title, selection: binding) {
                ForEach(range, id: \.self) { timeIncrement in
                    HStack {
                        Spacer(minLength: 0)
                        Text("\(timeIncrement)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.trailing, 4)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(timeIncrement) \(title)")
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: 80)

            Text(title)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}
