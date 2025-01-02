//
//  GroupCardView.swift
//  TrackCount
//
//  The card rendered in GroupListView's Navigation Links
//

import SwiftUI

/// A card containing a rounded rectangle with a gradient background, contains the group symbol and title
struct GroupCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var animateGradient: Bool
    let group: DMCardGroup
    var gradientColors: [Color] {
        colorScheme == .light ? [.blue, .white] : [.white, .black]
    }
    
    var body: some View {
        /// Variable that stores black in light mode and white in dark mode
        /// Used for items with non-white primary light mode colors (i.e. buttons)
        let primaryColor: Color = colorScheme == .light ? Color.black : Color.white
        let backgroundGradient: RadialGradient = RadialGradient(colors: gradientColors, center: .center, startRadius: animateGradient ? 15 : 25, endRadius: animateGradient ? 100 : 90)
        ZStack {
            // Background Gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                .shadow(radius: 5) // Adds a subtle shadow for depth
            
            // Background Glass
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial) // Applies the frosted glass effect
            
            // Content
            VStack {
                if !group.groupSymbol.isEmpty {
                    Image(systemName: group.groupSymbol)
                        .font(.system(size: 32))
                        .foregroundStyle(primaryColor.opacity(0.8))
                }
                
                if !group.groupTitle.isEmpty {
                    Text(group.groupTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(primaryColor.opacity(0.8))
                        .padding(.horizontal)
                }
            }
        }
    }
}
