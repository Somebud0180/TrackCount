//
//  CreateCardViewModel.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 12/25/24.
//


import SwiftUI
import SwiftData

class CreateCardViewModel: ObservableObject {
    @Published var newCardType: CardStore.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardCount: Int = 1
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newCardSymbol: String = ""
    @Published var validationError: [String] = []
    let minLimit = 1
    let maxLimit = 4096
    
    func initButton(with context: ModelContext) {
        // Double check card count if it exceeds limits
        if newCardCount > maxLimit {
            newCardCount = maxLimit
        } else if newCardCount < minLimit {
            newCardCount = minLimit
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
    
    func addCard(with context: ModelContext) {
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

        // Create and save the new card
        let newCard: CardStore
        
        if newCardType == .counter {
            // Setup card as a counter
            newCard = CardStore(uuid: UUID(),
                                    index: CardIndexManager.getNextAvailable(),
                                    type: newCardType,
                                    title: newCardTitle,
                                    count: newCardCount)
        } else if newCardType == .toggle {
            // Setup card as a toggle with toggle requirements
            newCard = CardStore(uuid: UUID(),
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

        do {
            try context.save()
        } catch {
            print("Failed to save new card: \(error.localizedDescription)")
        }

        resetFields()
    }

    private func resetFields() {
        newCardType = .counter
        newCardTitle = ""
        newButtonText = Array(repeating: "", count: 1)
        newCardCount = 1
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
    }
}
