//
//  GroupCardView.swift
//  TrackCount
//
//  The card rendered in GroupListView's Navigation Links
//

import SwiftUI

/// A card containing a rounded rectangle with a gradient background, group symbol, and title.
struct GroupCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gradientInDarkGroup") private var isGradientInDarkGroup: Bool = DefaultSettings.gradientInDarkGroup
    @AppStorage("primaryThemeColor") private var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    @ObservedObject private var timerManager = GlobalTimerManager.shared
    
    @State private var isHovering = false
    let group: DMCardGroup
    
    // MARK: - Computed Properties
    private var finalScale: CGFloat {
        isHovering ? 1.02 : 1.0
    }
    
    private var gradientColors: [Color] {
        if colorScheme == .light {
            return [primaryThemeColor.color, .white]
        } else {
            return [isGradientInDarkGroup ? primaryThemeColor.color : .white, .black]
        }
    }
    
    private var hasRunningTimer: Bool {
        guard let cards = group.cards else { return false }
        return cards.contains { card in
            (card.type == .timer || card.type == .timer_custom) &&
            timerManager.persistentTimerStates.values.contains { $0.groupUUID == group.uuid && $0.isRunning }
        }
    }
    
    private var hasCompletedTimer: Bool {
        guard let cards = group.cards else { return false }
        return cards.contains { card in
            (card.type == .timer || card.type == .timer_custom) &&
            (timerManager.persistentTimerStates[card.uuid]?.totalTime ?? 0) > 0 &&
            (timerManager.persistentTimerStates[card.uuid]?.timeRemaining ?? 1) <= 0
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 6) {
            if let symbol = group.groupSymbol, !symbol.isEmpty {
                Image(systemName: symbol)
                    .font(.largeTitle)
            }
            
            if let title = group.groupTitle, !title.isEmpty {
                Text(title)
                    .font(.system(.title3, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
            }
        }
        .minimumScaleFactor(0.5)
        .foregroundStyle(.primary.opacity(0.8))
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackground)
        .overlay {
            if hasRunningTimer {
                TimerProgressRing(color: primaryThemeColor.color)
            }
        }
        .overlay(alignment: .topTrailing) {
            if hasCompletedTimer {
                completedTimerBadge
            }
        }
        .scaleEffect(finalScale)
        .animation(.easeInOut(duration: 0.15), value: finalScale)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Subviews
    private var cardBackground: some View {
        ZStack {
            // Translucent Outer Outline
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary.opacity(0.25))
            
            // Gradient & Glass Card Body
            ZStack {
                AnimatedGradientBackground(colors: gradientColors)
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(2)
        }
    }
    
    private var completedTimerBadge: some View {
        Circle()
            .fill(primaryThemeColor.color.gradient)
            .stroke(.thinMaterial, lineWidth: 2)
            .overlay(
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.readableOn(primaryThemeColor.color))
            )
            .frame(width: 24, height: 24)
            .padding(4)
            .accessibilityLabel(Text("Completed timer"))
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Isolated Animation Components
/// Handles the smooth breathing gradient animation isolated from parent re-renders.
private struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var gradientPhase: Double = 0.0
    
    var body: some View {
        RadialGradient(
            colors: colors,
            center: .center,
            startRadius: 15 + (1 - gradientPhase) * 15,
            endRadius: 85 + gradientPhase * 15
        )
        .task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 3)) {
                    gradientPhase = gradientPhase == 0 ? 1 : 0
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
}

/// Handles the looping timer border stroke isolated from parent view updates.
private struct TimerProgressRing: View {
    let color: Color
    
    @State private var progressValue: Double = 0.0
    @State private var clearValue: Double = 0.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .trim(from: clearValue, to: progressValue)
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .padding(1)
            .task {
                while !Task.isCancelled {
                    progressValue = 0.0
                    clearValue = 0.0
                    
                    withAnimation(.linear(duration: 3.0)) { progressValue = 1.0 }
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    
                    withAnimation(.linear(duration: 3.0)) { clearValue = 1.0 }
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
            }
    }
}
