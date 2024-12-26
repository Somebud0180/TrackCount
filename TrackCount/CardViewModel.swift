//
//  CardViewModel.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 12/25/24.
//


import SwiftUI
import SwiftData

class CardViewModel: ObservableObject {
    // Initialize variables
    @Published var newGroupTitle: String = ""
    @Published var newCardType: CardStore.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardCount: Int = 1
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newCardSymbol: String = ""
    @Published var validationError: [String] = []
    @Published var existingCard: CardStore? = nil
    @Published var savedCards: [CardStore] = []
    
    // Button limit
    let minButtonLimit = 1
    let maxButtonLimit = 4096
    
    init(existingCard: CardStore? = nil) {
        self.existingCard = existingCard
    }
    
    func initEditCard(with context: ModelContext) {
        guard let card = existingCard else { return }
        self.newCardType = card.type
        self.newCardTitle = card.title
        self.newCardCount = card.count
        self.newButtonText = card.buttonText ?? Array(repeating: "", count: 1)
        self.newCardState = card.state ?? Array(repeating: true, count: 1)
        self.newCardSymbol = card.symbol ?? ""
    }
    
    // Adjust saved strings and boolean (states) for created buttons
    func initButton(with context: ModelContext) {
        // Double check card count if it exceeds limits
        if newCardCount > maxButtonLimit {
            newCardCount = maxButtonLimit
        } else if newCardCount < minButtonLimit {
            newCardCount = minButtonLimit
        }
        
        // Adjust amount of strings in array to accomodate button text
        if newCardCount > newButtonText.count {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
        } else if newCardCount < newButtonText.count {
            newButtonText.removeLast(newButtonText.count - newCardCount)
        }

        // Adjust amount of strings in array to accomodate button states
        if newCardCount > newCardState.count {
            newCardState.append(contentsOf: Array(repeating: true, count: newCardCount - newCardState.count))
        } else if newCardCount < newCardState.count {
            newCardState.removeLast(newCardState.count - newCardCount)
        }
    }
    
    // Validates cards and saves them to storage
    func saveCard(with context: ModelContext) {
        validationError.removeAll()
        if newCardTitle.isEmpty {
            validationError.append("Title")
        }
        
        if newCardType == .toggle && newCardSymbol.isEmpty {
            validationError.append("Button Symbol")
        }
        
        if !validationError.isEmpty {
            return
        }
        
        if let card = existingCard {
            // Update the existing card
            card.title = newCardTitle
            card.type = newCardType
            card.count = newCardCount
            card.buttonText = newButtonText
            card.state = newCardState
            card.symbol = newCardSymbol
        } else {
            // Create and save the new card
            let newCard: CardStore
            
            if newCardType == .counter {
                // Setup card as a counter
                newCard = CardStore(uuid: UUID(),
                                    groupTitle: newGroupTitle,
                                    index: CardIndexManager.getNextAvailable(),
                                    type: newCardType,
                                    title: newCardTitle,
                                    count: newCardCount)
            } else if newCardType == .toggle {
                // Setup card as a toggle with toggle requirements
                newCard = CardStore(uuid: UUID(),
                                    groupTitle: newGroupTitle,
                                    index: CardIndexManager.getNextAvailable(),
                                    type: newCardType,
                                    title: newCardTitle,
                                    buttonText: newButtonText,
                                    count: newCardCount,
                                    state: newCardState,
                                    symbol: newCardSymbol)
            } else {
                // Handle unexpected card types if necessary
                fatalError("Unsupported card type: \(newCardType)")
            }
            
            context.insert(newCard)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save new card: \(error.localizedDescription)")
        }
        
        resetFields()
    }
    
    func moveCard(from source: IndexSet, to destination: Int, with context: ModelContext) {
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
    func removeCard(_ card: CardStore, with context: ModelContext) {
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

    // Resets the previously set values to default
    private func resetFields() {
        newCardType = .counter
        newCardTitle = ""
        newButtonText = Array(repeating: "", count: 1)
        newCardCount = 1
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
    }
}
