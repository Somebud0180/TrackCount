//
//  JiggleViewModifier.swift
//  TrackCount
//
//  A wiggle animation similar to the Home Screen wiggle
//  via https://gist.github.com/markmals/075273b58a94db20917235fdd5cda3cc
//

import SwiftUI

extension View {
    @ViewBuilder
    func jiggle(amount: Double = 2, isEnabled: Bool = true) -> some View {
        if isEnabled {
            modifier(JiggleViewModifier(amount: amount))
        } else {
            self
        }
    }
}

private struct JiggleViewModifier: ViewModifier {
    let amount: Double

    @State private var isJiggling = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isJiggling ? amount : 0))
            .animation(
                .easeInOut(duration: randomize(interval: 0.14, withVariance: 0.025))
                .repeatForever(autoreverses: true),
                value: isJiggling
            )
            .animation(
                .easeInOut(duration: randomize(interval: 0.18, withVariance: 0.025))
                .repeatForever(autoreverses: true),
                value: isJiggling
            )
            .onAppear {
                isJiggling.toggle()
            }
    }

    private func randomize(interval: TimeInterval, withVariance variance: Double) -> TimeInterval {
         interval + variance * (Double.random(in: 500...1_000) / 500)
    }
}
