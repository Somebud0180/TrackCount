//
//  GroupCardView.swift
//  TrackCount
//
//  The card rendered in GroupListView's Navigation Links
//

import SwiftUI

/// A card containing a rounded rectangle with a gradient background, contains the group symbol and title
struct GroupCardView: View {
    @Environment(\.modelContext) private var context
    
    let group: DMCardGroup
    let backgroundGradient: RadialGradient
    let primaryColors: Color
    @Binding var selectedGroup: DMCardGroup?
    @Binding var animateGradient: Bool
    @Binding var isShowingDialog: Bool
    
    var body: some View {
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
                        .foregroundStyle(primaryColors.opacity(0.8))
                }
                
                if !group.groupTitle.isEmpty {
                    Text(group.groupTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(primaryColors.opacity(0.8))
                        .padding(.horizontal)
                }
            }
        }
    }
}
