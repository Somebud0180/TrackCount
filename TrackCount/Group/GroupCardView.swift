//
//  GroupCardView.swift
//  TrackCount
//
//  The card rendered in GroupListView's Navigation Links
//

import SwiftUI

/// A card containing a rounded rectangle with a gradient background, contains the group symbol and title.
struct GroupCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("gradientInDarkGroup") var isGradientInDarkGroup: Bool = DefaultSettings.gradientInDarkGroup
    @AppStorage("primaryThemeColor") var primaryThemeColor: RawColor = DefaultSettings.primaryThemeColor
    // Replaces implicit repeatForever animation with a controlled phase driven by a Task loop to avoid jumpy resets.
    @State private var gradientPhase: Double = 0.0
    @State private var gradientAnimationTask: Task<Void, Never>? = nil
    @State private var progressValue: Double = 0.0
    @State private var clearValue: Double = 0.0
    @State private var isClearing: Bool = false
    @State private var animationTask: Task<Void, Never>?
    @ObservedObject private var timerManager = GlobalTimerManager.shared
    let group: DMCardGroup
    
    /// Dynamically computes gradient colors based on colorScheme.
    private var gradientColors: [Color] {
        colorScheme == .light ? [primaryThemeColor.color, .white] : [isGradientInDarkGroup ? primaryThemeColor.color : .white, .black]
    }
    
    /// Checks if any timer in this group is currently running
    private var hasRunningTimer: Bool {
        guard let cards = group.cards else { return false }
        
        for card in cards {
            // Check if card has timer type
            if card.type == .timer || card.type == .timer_custom {
                // Check GlobalTimerManager for running timers in this group
                for (_, timerState) in timerManager.persistentTimerStates {
                    if timerState.groupUUID == group.uuid && timerState.isRunning {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// Checks if any timer in this group has completed (timeRemaining <= 0 with a valid totalTime)
    private var hasCompletedTimer: Bool {
        guard let cards = group.cards else { return false }
        for card in cards {
            if card.type == .timer || card.type == .timer_custom {
                if let state = timerManager.persistentTimerStates[card.uuid] {
                    if state.totalTime > 0 && state.timeRemaining <= 0 { return true }
                }
            }
        }
        return false
    }
    
    var body: some View {
        /// Variable that stores black in light mode and white in dark mode.
        /// Used for items with non-white primary light mode colors (i.e. buttons).
        let primaryColor: Color = colorScheme == .light ? Color.black : Color.white
        
        // Automatically updates when colorScheme changes, eliminating the need for onChange.
        let backgroundGradient = RadialGradient(
            colors: gradientColors,
            center: .center,
            startRadius: 15 + (1 - gradientPhase) * 15,
            endRadius: 85 + gradientPhase * 15
        )
        
        // Card stack without outer ZStack alignment wrapper; badge applied via .if overlay
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 5)
            
            // Background Gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .onAppear { startGradientAnimation() }
                .onDisappear {
                    gradientAnimationTask?.cancel()
                    gradientAnimationTask = nil
                    gradientPhase = 0.0
                    progressValue = 0.0
                    clearValue = 0.0
                    animationTask?.cancel()
                }
            
            // Timer Progress Ring
            if hasRunningTimer {
                RoundedRectangle(cornerRadius: 12)
                    .trim(from: clearValue, to: progressValue)
                    .stroke(
                        primaryThemeColor.color,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .onAppear { startProgressAnimation() }
                    .onChange(of: hasRunningTimer) { _, newValue in
                        if newValue { startProgressAnimation() } else {
                            animationTask?.cancel()
                            withAnimation(.easeOut(duration: 0.5)) {
                                progressValue = 0.0
                                clearValue = 0.0
                                isClearing = false
                            }
                        }
                    }
            }
            
            // Background Glass
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .if(hasCompletedTimer) {
                    $0.overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(primaryThemeColor.color.gradient)
                            .stroke(.thinMaterial, lineWidth: 2)
                            .overlay(
                                Image(systemName: "timer")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white.readableOn(primaryThemeColor.color))
                            )
                            .frame(width: 24, height: 24)
                            .offset(x: 10, y: -10) // Exceed outside top-right corner
                            .accessibilityLabel(Text("Completed timer"))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            
            // Content
            VStack {
                if (group.groupSymbol?.isEmpty == false) {
                    Image(systemName: group.groupSymbol ?? "")
                        .font(.largeTitle)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(primaryColor.opacity(0.8))
                }
                if (group.groupTitle?.isEmpty == false) {
                    Text(group.groupTitle ?? "")
                        .font(.system(.title3, weight: .bold))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .foregroundStyle(primaryColor.opacity(0.8))
                        .padding(.horizontal)
                }
            }
        }
    }
    
    /// Starts the progress animation for the timer.
    private func startProgressAnimation() {
        // Cancel any existing animation task
        animationTask?.cancel()
        
        // Immediately reset values without animation to prevent any residual state
        clearValue = 0.0
        progressValue = 0.0
        isClearing = false
        
        // Use Task to manage the entire animation cycle
        animationTask = Task {
            do {
                // Wait a tiny moment to ensure state is clean
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                // Check if task was cancelled or timer stopped
                try Task.checkCancellation()
                
                // Start the fill phase
                withAnimation(.linear(duration: 3.0)) {
                    progressValue = 1.0
                }
                
                // Wait for fill phase to complete
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                // Check if task was cancelled or timer stopped
                try Task.checkCancellation()
                
                if hasRunningTimer {
                    // Start the clear phase
                    withAnimation(.linear(duration: 3.0)) {
                        clearValue = 1.0
                    }
                    
                    // Wait for clear phase to complete
                    try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    
                    // Check if task was cancelled or timer stopped
                    try Task.checkCancellation()
                    
                    // Reset for next cycle - do this immediately without animation
                    clearValue = 0.0
                    progressValue = 0.0
                    
                    // Restart if timer is still running
                    if hasRunningTimer {
                        startProgressAnimation()
                    }
                }
            } catch {
                // Task was cancelled, clean up
                withAnimation(.easeOut(duration: 0.5)) {
                    progressValue = 0.0
                    clearValue = 0.0
                    isClearing = false
                }
            }
        }
    }
    
    /// Starts a smooth, continuously breathing gradient animation using a controllable Task instead of repeatForever to prevent jumpy inversion.
    private func startGradientAnimation() {
        if gradientAnimationTask != nil { return } // Prevent multiple tasks
        gradientAnimationTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 3)) {
                    gradientPhase = gradientPhase == 0 ? 1 : 0
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
