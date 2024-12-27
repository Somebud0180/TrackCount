//
//  EditScreenView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

/// A view containing that lists all saved groups and provides access to editing the group's cards
struct EditScreenView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DMCardGroup.index, order: .forward) private var savedGroups: [DMCardGroup]
    
    @State private var isPresentingGroupForm: Bool = false
    
    let columnLayout = [GridItem(.adaptive(minimum: 110, maximum: 200), spacing: 16)]
    let backgroundGradient = RadialGradient(colors: [.primary, .secondary], center: .center, startRadius: 15, endRadius: 100)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columnLayout, spacing: 16) {
                    ForEach(savedGroups) { group in
                        NavigationLink(destination: CardListView(selectedGroup: group)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(backgroundGradient)
                                
                                // Background styling
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.thinMaterial) // Applies the frosted glass effect
                                    .shadow(radius: 10) // Adds a subtle shadow for depth
                                
                                // Group 'card' contents
                                VStack {
                                    if !group.groupSymbol.isEmpty {
                                        Image(systemName: group.groupSymbol)
                                            .font(.system(size: 32))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                            .padding()
                                    }
                                    
                                    if !group.groupTitle.isEmpty {
                                        Text(group.groupTitle)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
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
                .navigationBarTitle("Card Groups")
                .navigationBarItems(trailing: Button(action: {isPresentingGroupForm.toggle()}) {
                    Image(systemName: "plus")
                })
                .sheet(isPresented: $isPresentingGroupForm) {
                    GroupFormView()
                        .presentationDetents([.fraction(0.40)])
                }
            }
        }
    }
}

#Preview {
    EditScreenView()
        .modelContainer(for: DMCardGroup.self)
}
