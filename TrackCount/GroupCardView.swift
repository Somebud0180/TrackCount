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
    @State private var animateGradient: Bool = false
    let group: DMCardGroup
    
    /// Dynamically computes gradient colors based on colorScheme.
    private var gradientColors: [Color] {
        colorScheme == .light ? [.blue, .white] : [.white, .black]
    }
    
    var body: some View {
        /// Variable that stores black in light mode and white in dark mode.
        /// Used for items with non-white primary light mode colors (i.e. buttons).
        let primaryColor: Color = colorScheme == .light ? Color.black : Color.white
        
        // Automatically updates when colorScheme changes, eliminating the need for onChange.
        let backgroundGradient = RadialGradient(
            colors: gradientColors,
            center: .center,
            startRadius: animateGradient ? 15 : 30,
            endRadius: animateGradient ? 100 : 85
        )
        
        ZStack {
            // Background Gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .shadow(radius: 5) // Adds a subtle shadow for depth
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateGradient.toggle()
                    }
                }
                .onDisappear {
                    // Stop animation when view disappears
                    animateGradient = false
                }
            
            // Background Glass
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial) // Applies the frosted glass effect
            
            // Content
            VStack {
                if !group.groupSymbol.isEmpty {
                    Image(systemName: group.groupSymbol)
                        .font(.largeTitle)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(primaryColor.opacity(0.8))
                }
                
                if !group.groupTitle.isEmpty {
                    Text(group.groupTitle)
                        .font(.system(.title3, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .foregroundStyle(primaryColor.opacity(0.8))
                        .padding(.horizontal)
                }
            }
        }
    }
}
