//
//  GroupListView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

/// A view containing that lists all saved groups and provides access to editing the group's cards
struct GroupListView: View {
    enum Behaviour {
        case edit
        case view
    }
    
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    @State private var isPresentingGroupForm: Bool = false
    @State var animateGradient: Bool = false
    var viewBehaviour: Behaviour
    var gradientColors: [Color] {
        colorScheme == .light ? [animateGradient ? .blue : .purple, .white] : [.white, .black]
    }
    
    var body: some View {
        let columnLayout = [GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)]
        let backgroundGradient = RadialGradient(colors: gradientColors, center: .center, startRadius: animateGradient ? 15 : 25, endRadius: animateGradient ? 100 : 90)
        
        /// Variable that stores black in light mode and white in dark mode
        /// Used for items with non-white primary light mode colors (i.e. buttons)
        let primaryColors: Color = colorScheme == .light ? Color.black : Color.white
        
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columnLayout, spacing: 16) {
                    ForEach(savedGroups) { group in
                        NavigationLink(destination: destinationView(for: group)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(backgroundGradient)
                                    .onAppear {
                                        withAnimation(
                                            .easeInOut(duration: 3).repeatForever(autoreverses: true)
                                        ) {
                                            animateGradient.toggle()
                                        }
                                    }
                                
                                // Background styling
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.thinMaterial) // Applies the frosted glass effect
                                    .shadow(radius: 5) // Adds a subtle shadow for depth
                                
                                // Group 'card' contents
                                VStack {
                                    if !group.groupSymbol.isEmpty {
                                        Image(systemName: group.groupSymbol)
                                            .font(.system(size: 32))
                                            .foregroundStyle(primaryColors.opacity(0.8))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                            .padding()
                                    }
                                    
                                    if !group.groupTitle.isEmpty {
                                        Text(group.groupTitle)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(primaryColors.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }
                .padding()
                .navigationTitle("Your Groups")
                .toolbar {
                    if viewBehaviour == .edit {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { isPresentingGroupForm.toggle() }) {
                                Image(systemName: "plus")
                            }
                            .sheet(isPresented: $isPresentingGroupForm) {
                                GroupFormView()
                                    .presentationDetents([.fraction(0.40)])
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// A function that determines the destination based on the viewBehaviour
    private func destinationView(for group: DMCardGroup) -> some View {
        switch viewBehaviour {
        case .edit:
            return AnyView(CardListView(selectedGroup: group))
        case .view:
            return AnyView(TrackView(selectedGroup: group))
        }
    }
}

#Preview {
    GroupListView(viewBehaviour: .edit)
        .modelContainer(for: DMCardGroup.self)
}
