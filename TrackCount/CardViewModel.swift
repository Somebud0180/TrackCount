//
//  CardViewModel.swift
//  TrackCount
//
//  Contains most of the logic related to cards
//


import Foundation
import SwiftData
import SwiftUI

class CardViewModel: ObservableObject {
    // Set variable defaults
    @Environment(\.self) var environment
    @Published var selectedGroup: DMCardGroup
    @Published var selectedCard: DMStoredCard? = nil
    @Published var newIndex: Int = 0
    @Published var newCardType: DMStoredCard.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardCount: Int = 1
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newCardSymbol: String = ""
    @Published var newCardPrimary: Color = .blue
    @Published var newCardSecondary: Color = .white
    @Published var validationError: [String] = []
    
    // Button limit
    let minButtonLimit = 1
    let maxButtonLimit = 4096
    
    /// Initializes the selectedGroup and selectedCard variable for editing
    /// - Parameters:
    ///   - selectedGroup: accepts DMCardGroup entities, reference for which group to store the card
    ///   - selectedCard: (optional) accepts DMStoredCard entities, edits the entity that is passed over
    init(selectedGroup: DMCardGroup, selectedCard: DMStoredCard? = nil) {
        self.selectedGroup = selectedGroup
        self.selectedCard = selectedCard
    }
    
    /// A function that grabs the saved data from a selected card.
    /// Used to populate the temporary variables within CardViewModel with the variables from the selected card.
    func initEditCard() {
        print("Initializing edit card: \(selectedCard?.title ?? "No card selected")")
        guard let card = selectedCard else { return }
        self.newCardType = card.type
        self.newCardTitle = card.title
        self.newCardCount = card.count
        self.newButtonText = card.buttonText ?? Array(repeating: "", count: 1)
        self.newCardState = card.state ?? Array(repeating: true, count: 1)
        self.newCardSymbol = card.symbol ?? ""
        self.newCardPrimary = card.primaryColor.color
        self.newCardSecondary = card.secondaryColor.color
    }
    
    /// A function that adjusts variables related to buttons.
    /// Used to adjust the arrays 'newButtonText' and 'newCardState' to match the newCardCount.
    /// Also clamps newCardCount to stay within limits.
    func initButton(with context: ModelContext) {
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minButtonLimit), maxButtonLimit)
        
        // Adjust `newButtonText` array size
        if newButtonText.count < newCardCount {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
        } else if newButtonText.count > newCardCount {
            newButtonText.removeLast(newButtonText.count - newCardCount)
        }
        
        // Adjust `newCardState` array size
        if newCardState.count < newCardCount {
            newCardState.append(contentsOf: Array(repeating: true, count: newCardCount - newCardState.count))
        } else if newCardState.count > newCardCount {
            newCardState.removeLast(newCardState.count - newCardCount)
        }
    }
    
    /// A function that stores the temporary variables to a card and saves it to the data model entity.
    /// Used to save the set variables into the cards within the selected group.
    /// Also checks the card contents and throws errors, if any, to validationError.
    /// Also provides the card's index and uuid on save.
    func saveCard(with context: ModelContext) {
        // Validate the form before saving
        validateForm()
        guard validationError.isEmpty else {
            return
        }
        
        // Check if there are any existing cards
        if selectedGroup.cards.count == 0 {
            newIndex = 0 // Set new index to 0 if there are no cards
        } else {
            newIndex = selectedGroup.cards.count + 1 // Set new index to the next highest number
        }
        
        if let card = selectedCard {
            // Update the existing card
            card.title = newCardTitle
            card.type = newCardType
            card.count = newCardCount
            card.buttonText = newButtonText.prefix(newCardCount).map { $0 }
            card.state = newCardState.prefix(newCardCount).map { $0 }
            card.symbol = newCardSymbol
            card.primaryColor = CodableColor(color: newCardPrimary)
            card.secondaryColor = CodableColor(color: newCardSecondary)
        } else {
            // Create a new card
            let newCard = DMStoredCard(
                uuid: UUID(),
                index: newIndex,
                type: newCardType,
                title: newCardTitle,
                buttonText: newCardType == .toggle ? newButtonText.prefix(newCardCount).map { $0 } : nil,
                count: newCardType == .counter ? newCardCount : 0,
                state: newCardType == .toggle ? newCardState.prefix(newCardCount).map { $0 } : nil,
                symbol: newCardType == .toggle ? newCardSymbol : nil,
                primaryColor: newCardPrimary,
                secondaryColor: newCardSecondary
            )
            selectedGroup.cards.append(newCard) // Save the new card to the selected group
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            validationError.append("Failed to save the card: \(error.localizedDescription)")
        }
        
        resetFields()
    }

    /// A function that checks the card's contents for any issues.
    /// Prevents empty titles for all card types and empty symbols for toggle cards.
    /// Appends errors to validationError.
    private func validateForm() {
        validationError.removeAll()
        
        if newCardTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError.append("Card title cannot be empty.")
        }
        
        if newCardType == .toggle {
            if newCardSymbol.trimmingCharacters(in: .whitespaces).isEmpty {
                validationError.append("Symbol cannot be empty for toggle type.")
            }
        }
    }
    
    /// A function that sets the temporary fields to defaults.
    /// Used to reset the contents after saving a card to free the fields for a new card.
    private func resetFields() {
        selectedCard = nil
        newCardType = .counter
        newCardTitle = ""
        newButtonText = Array(repeating: "", count: 1)
        newCardCount = 1
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
        newCardPrimary = .blue
        newCardSecondary = .white
    }
}
