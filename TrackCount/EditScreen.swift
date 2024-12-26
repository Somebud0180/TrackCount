//
//  EditView.swift
//  TrackCount
//
//  Contains the screen for editing the tracker contents
//

import SwiftUI
import SwiftData

struct EditScreen: View {
    // Query saved cards
    @Query var savedCards: [CardStore]
    @Environment(\.modelContext) private var context
    
    // Set variable defaults
    @State private var isCardFormPresented: Bool = false
    @State private var validationError: [String] = []
    @State private var selectedCard: CardStore? = nil
    @State private var isEditingCard: Bool = false
    
    var body: some View {
        // List to preview, rearrange and delete created cards
        List {
            // Check if savedCards is empty and display a message if so
            if savedCards.isEmpty {
                Text("No cards created yet :O")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            } else {
                // Display each card sorted by their id
                ForEach(savedCards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
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
                        isCardFormPresented.toggle()
                    }
                }
                .onMove(perform: moveCard)
            }
            
            Button(action: {isCardFormPresented.toggle()}) {
                Text("Create a new card")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding()
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .sheet(isPresented: $isCardFormPresented) {
            CardForm(selectedCard)
                .presentationDetents([.fraction(0.99)])
                .onDisappear {
                    selectedCard = nil
                }
        }
    }
    
    private func moveCard(from source: IndexSet, to destination: Int) {
        // Extract the cards in a mutable array
        var mutableCards = savedCards.sorted(by: { $0.index < $1.index })
        
        // Perform the move in the mutable array
        mutableCards.move(fromOffsets: source, toOffset: destination)
        
        // Update the IDs to reflect the new order
        for index in mutableCards.indices {
            mutableCards[index].index = index
        }
        
        // Save the changes back to the context
        do {
            for card in mutableCards {
                if let existingCard = savedCards.first(where: { $0.uuid == card.uuid }) {
                    existingCard.index = card.index // Update the ID in the context
                }
            }
            try context.save() // Persist the changes
        } catch {
            print("Failed to save updated order: \(error.localizedDescription)")
        }
    }
    
    // Free the ID and remove card from the store
    private func removeCard(_ card: CardStore) {
        do {
            // Remove the card from the context
            context.delete(card)
            
            // Save the context after deletion
            try context.save()
            
            // Free up the ID using the CardIDManager
            CardIndexManager.freeIndex(card.index)
            
            // Update the IDs of remaining cards to fill the gap
            var mutableCards = savedCards.sorted(by: { $0.index < $1.index })
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
    EditScreen()
        .modelContainer(for: CardStore.self)
}
