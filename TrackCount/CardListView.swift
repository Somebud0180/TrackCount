//
//  CardListView.swift
//  TrackCount
//
//  A view containing the list of cards inside a group, given by passing an argument
//

import SwiftUI
import SwiftData

/// A view containing a list of cards in a selected group
struct CardListView: View {
    @Environment(\.modelContext) private var context
    
    // Set variable defaults
    var selectedGroup: DMCardGroup
    @State private var isPresentingCardFormView: Bool = false
    @State private var validationError: [String] = []
    @State private var selectedCard: DMStoredCard? = nil
    
    var body: some View {
        NavigationStack {
            // List to preview, rearrange and delete created cards
            List {
                // Check if selectedGroup.cards. is empty and display a message if so
                if selectedGroup.cards.isEmpty {
                    Text("No cards created yet :O")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                } else {
                    // Display each card sorted by their id
                    ForEach(selectedGroup.cards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                        HStack {
                            Image(systemName: "line.horizontal.3")
                                .foregroundColor(.secondary)
                            Text(card.title)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                removeCard(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            selectedCard = card
                            isPresentingCardFormView.toggle()
                        }
                    }
                    .onMove(perform: moveCard)
                }
                
                Button(action: {isPresentingCardFormView.toggle()}) {
                    Text("Create a new card")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding()
                .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationBarTitle(selectedGroup.groupTitle, displayMode: .inline)
        .sheet(isPresented: $isPresentingCardFormView) {
            CardFormView(selectedGroup: selectedGroup, selectedCard: selectedCard)
                .presentationDetents([.medium, .fraction(0.99)])
                .onDisappear {
                    selectedCard = nil
                }
        }
    }
    
    /// A function invoked at a list's onMove that handles the movement of the cards in the list.
    /// Copies the cards and stores them to a modifiable variable.
    /// Updates the card's index to reflect the new order.
    private func moveCard(from source: IndexSet, to destination: Int) {
        // Extract the cards in a mutable array
        var mutableCards = selectedGroup.cards.sorted(by: { $0.index < $1.index })
        
        // Perform the move in the mutable array
        mutableCards.move(fromOffsets: source, toOffset: destination)
        
        // Update the index of the card to reflect the new order
        for index in mutableCards.indices {
            mutableCards[index].index = index
        }
        
        // Save the changes back to the context
        do {
            for card in mutableCards {
                if let selectedCard = selectedGroup.cards.first(where: { $0.uuid == card.uuid }) {
                    selectedCard.index = card.index // Update the ID in the context
                }
            }
            try context.save() // Persist the changes
        } catch {
            print("Failed to save updated order: \(error.localizedDescription)")
        }
    }
    
    /// A function that removes the card from the data model entity
    /// Used to delete the card gracefully, adjusting existing card's indexes to take over a free index if applicable
    private func removeCard(_ card: DMStoredCard) {
        do {
            // Remove the card from the context
            context.delete(card)
            
            // Save the context after deletion
            try context.save()
            
            // Update the IDs of remaining cards to fill the gap
            var mutableCards = selectedGroup.cards.sorted(by: { $0.index < $1.index })
            mutableCards.removeAll { $0.uuid == card.uuid }
            
            // Reassign IDs to remaining cards
            for index in mutableCards.indices {
                mutableCards[index].index = index
            }
            
            // Save the changes back to the context
            try context.save()
            print("Card removed, ID freed, and remaining cards updated.")
        } catch {
            print("Failed to remove card and update IDs: \(error.localizedDescription)")
        }
    }
}

#Preview {
    // Sample DMCardGroup to pass into the preview
    var sampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Card 1", groupSymbol: "star.fill")
    }
    
    CardListView(selectedGroup: sampleGroup)
        .modelContainer(for: DMCardGroup.self)
}
