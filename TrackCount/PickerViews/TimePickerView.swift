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
                        // Forces the text in the Picker to be
                        // right-aligned
                        Spacer()
                        Text("\(timeIncrement)")
                            .multilineTextAlignment(.trailing)
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
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}
