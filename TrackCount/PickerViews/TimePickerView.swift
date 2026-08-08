//
//  TimePickerView.swift
//  TrackCount
//
//  Referenced from https://digitalbunker.dev/recreating-the-ios-timer-in-swiftui/
//  By Aryaman Sharda
//

import SwiftUI

struct TimePickerView: View {
    // This is used to tighten up the spacing between the Picker and its
    // respective label
    //
    // This allows us to avoid having to use custom
    private let pickerViewTitlePadding: CGFloat = 4.0

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
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.trailing, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(timeIncrement) \(title)")
                }
            }
            .pickerStyle(InlinePickerStyle())
            .frame(minWidth: 45, maxWidth: 80)

            Text(title)
                .fontWeight(.bold)
                .accessibilityHidden(true)
        }
    }
}
