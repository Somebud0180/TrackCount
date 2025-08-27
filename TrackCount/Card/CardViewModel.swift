//
//  CardViewModel.swift
//  TrackCount
//
//  Contains most of the logic related to cards
//


import Foundation
import SwiftData
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    // Set variable defaults
    @Query var storedCards: [DMStoredCard]
    @Published var selectedGroup: DMCardGroup
    @Published var selectedCard: DMStoredCard?
    @Published var newCardIndex: Int = 0
    @Published var newCardType: DMStoredCard.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newCardCount: Int = 1
    @Published var newCardModifier: [Int] = [1, 0, 0]
    @Published var newCardModifierText: [String] = ["1", "0", "0"]
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newTimerValues: [Int : [Int]] = [0 : [0, 0 ,0]]
    @Published var newCardTimer: [Int] = [0]
    @Published var newCardRingtone: String = ""
    @Published var newCardSymbol: String = ""
    @Published var newCardPrimary: Color = .blue
    @Published var newCardSecondary: Color = .white
    @Published var validationError: [String] = []
    @Published var warnError: [String] = []
    
    enum resetFor {
        case viewModel
        case dismiss
    }
    
    enum initFor {
        case switchType
        case validation
    }
    
    // Counter limit
    let minModifierLimit = 0
    
    // Button limit
    let buttonTextLimit = 20
    let minButtonLimit = 1
    let maxButtonLimit = 4096
    
    // Timer limit
    let minTimerAmount = 1
    let maxTimerAmount = 4
    let minTimerLimit = 1
    let maxTimerLimit = 86399
    
    /// Initializes the `selectedGroup` and `selectedCard` variable for editing.
    /// - Parameters:
    ///   - selectedGroup: accepts `DMCardGroup` entities, reference for which group to store the card.
    ///   - selectedCard: (optional) accepts `DMStoredCard` entities, edits the entity that is passed over.
    init(selectedGroup: DMCardGroup, selectedCard: DMStoredCard? = nil) {
        self.selectedGroup = selectedGroup
        self.selectedCard = selectedCard
        let groupID = selectedGroup.uuid
        _storedCards = Query(filter: #Predicate<DMStoredCard> { $0.group?.uuid == groupID }, sort: \DMStoredCard.index, order: .forward)
    }
    
    /// A function that grabs the saved data from a selected card.
    /// Used to populate the temporary variables within `CardViewModel` with the variables from the selected card.
    func fetchCard() {
        guard let card = selectedCard else { return }
        self.newCardType = card.type ?? .counter
        self.newCardTitle = card.title
        self.newCardCount = card.count
        self.newCardState = card.state?.isEmpty == false ? card.state!.map { $0.state } : Array(repeating: true, count: 1)
        self.newCardModifier = card.modifier?.isEmpty == false ? card.modifier!.map { $0.modifier } : [1]
        self.newCardModifierText = card.modifier?.isEmpty == false ? card.modifier!.map { String($0.modifier) } : ["1", "0", "0"]
        self.newButtonText = card.buttonText?.isEmpty == false ? card.buttonText!.map { $0.buttonText } : Array(repeating: "", count: 1)
        self.newCardSymbol = card.symbol ?? ""
        self.newCardTimer = card.timer?.isEmpty == false ? card.timer!.map { $0.timerValue } : Array(repeating: 0, count: 1)
        self.newCardRingtone = card.timerRingtone ?? ""
        self.newCardPrimary = card.primaryColor?.color ?? .blue
        self.newCardSecondary = card.secondaryColor?.color ?? .white
        
        if card.type == .timer || card.type == .timer_custom {
            // Convert timer values back to [h,m,s] format for each timer
            for i in 0..<(card.timer?.count ?? 0) {
                if let seconds = card.timer?[i].timerValue {
                    let h = seconds / 3600
                    let m = (seconds % 3600) / 60
                    let s = seconds % 60
                    newTimerValues[i] = [h, m, s]
                }
            }
        }
    }
    
    /// A function that calls the corresponding initializers dynamically based on the type
    func initTypes(for behaviour: initFor) {
        // When switching cards, reset errors and shared values
        validationError.removeAll()
        if behaviour == .switchType {
            newCardCount = 1
        }
        if newCardType == .counter {
            initCounter()
        }
        else if newCardType == .toggle {
            initButton()
        } else if newCardType == .timer || newCardType == .timer_custom {
            initTimer()
        }
    }
    
    func initCounter() {
        for i in 0..<newCardModifier.count {
            // Convert the string to an integer and then validate
            if let value = Int(newCardModifierText[i]) {
                newCardModifier[i] = max(value, 0)
            } else {
                // Reset to a default value 1 if conversion fails
                newCardModifier[i] = 0
                newCardModifierText[i] = "0"
            }
        }
    }
    
    /// A function that adjusts variables related to buttons.
    /// Used to adjust the arrays `newButtonText` and `newCardState` to match the `newCardCount`.
    /// Also clamps `newCardCount` to stay within limits.
    func initButton() {
        // Validate newCardCount
        guard newCardCount >= minButtonLimit && newCardCount <= maxButtonLimit else {
            validateForm()
            return
        }
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minButtonLimit), maxButtonLimit)
        
        // Adjust `newButtonText` array size
        if newButtonText.count < newCardCount {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
        } else if newButtonText.count > newCardCount {
            newButtonText.removeLast(newButtonText.count - newCardCount)
        }
        
        // Adjust `newCardState` array size
        newCardState = Array(repeating: true, count: newCardCount)
    }
    
    /// Used to adjust the array `newCardTimer` to match the `newCardCount` and prep `newCardState`.
    /// Also clamps `newCardCount` to stay within limits
    func initTimer() {
        // Validate newCardCount
        guard newCardCount >= minTimerAmount && newCardCount <= maxTimerAmount else {
            validateForm()
            return
        }
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minTimerAmount), maxTimerAmount)
        
        // Convert time arrays to total seconds
        let timerTotals = Array(0..<4).map { index in
            convertToTotalSeconds(newTimerValues[index] ?? [0, 0, 0])
        }
        
        // Adjust newCardTimer array size and populate with total seconds
        newCardTimer = Array(timerTotals.prefix(newCardCount))
        
        // Set newCardState for timer
        newCardState = Array(repeating: false, count: 1)
        
        // Validate timer values
        if newCardTimer.isEmpty {
            newCardTimer = Array(repeating: 0, count: newCardCount)
        }
    }
    
    /// A function that converts the timer values [hour, minute, second] into total seconds.
    /// - Parameter timeArray: Timer array to turn into total seconds
    /// - Returns: Returns an integer containing the total seconds
    private func convertToTotalSeconds(_ timeArray: [Int]) -> Int {
        guard timeArray.count >= 3 else { return 0 }
        return timeArray[0] * 3600 + timeArray[1] * 60 + timeArray[2]
    }
    
    /// A function that updates the timer values based on the index.
    func updateTimerValue(index: Int, hours: Int, minutes: Int, seconds: Int) {
        // Input validation
        let validatedHours = max(0, min(hours, 23))
        let validatedMinutes = max(0, min(minutes, 59))
        let validatedSeconds = max(0, min(seconds, 59))
        
        newTimerValues[index] = [validatedHours, validatedMinutes, validatedSeconds]
        initTimer() // Recalculate timer values
    }
    
    /// A function that stores the temporary variables to a card and saves it to the data model entity.
    /// Used to save the set variables into the cards within the selected group.
    /// Also checks the card contents and throws errors, if any, to `validationError`.
    /// Also provides the card's index and uuid on save.
    func saveCard(with context: ModelContext) {
        // Validate types and update them before saving
        initTypes(for: .validation)
        
        // Validate the form before saving
        validateForm()
        guard validationError.isEmpty else {
            return
        }
        
        // Check if there are any existing cards
        if storedCards.count == 0 {
            newCardIndex = 0 // Set new index to 0 if there are no cards
        } else {
            newCardIndex = storedCards.count // Set new index to the next highest number
        }
        
        do {
            if let card = selectedCard {
                // Update the existing card
                card.title = newCardTitle
                card.count = (newCardType == .counter && card.type != .counter) ? 0 : newCardCount // Check card count first due to type check, to avoid reseting an existing counter card
                card.type = newCardType
                card.state = newCardType == .toggle ? newCardState.prefix(newCardCount).map { CardState(state: $0) } : (newCardType == .timer || newCardType == .timer_custom) ? [CardState(state: false)] : nil
                card.modifier = newCardType == .counter ? newCardModifier.map { CounterModifier(modifier: $0) } : nil
                card.buttonText = newCardType == .toggle ? newButtonText.prefix(newCardCount).map { ButtonText(buttonText: $0) } : nil
                card.symbol = newCardType == .toggle ? newCardSymbol : nil
                card.timer = (newCardType == .timer || newCardType == .timer_custom) ? newCardTimer.map { TimerValue(timerValue: $0) } : nil
                card.timerRingtone = (newCardType == .timer || newCardType == .timer_custom) ? newCardRingtone : nil
                card.primaryColor = CodableColor(color: newCardPrimary)
                card.secondaryColor = CodableColor(color: newCardSecondary)
                card.group = selectedGroup
            } else {
                // Create a new card
                let newCard = DMStoredCard(
                    index: newCardIndex,
                    type: newCardType,
                    title: newCardTitle,
                    count: newCardType == .counter ? 0 : newCardCount,
                    state: newCardType == .toggle ? newCardState.prefix(newCardCount).map { $0 } :
                        (newCardType == .timer || newCardType == .timer_custom) ? [false] : nil,
                    modifier: newCardType == .counter ? newCardModifier : nil,
                    buttonText: newCardType == .toggle ? newButtonText.prefix(newCardCount).map { $0 } : nil,
                    symbol: newCardType == .toggle ? newCardSymbol : nil,
                    timer: (newCardType == .timer || newCardType == .timer_custom) ? newCardTimer : nil,
                    timerRingtone: (newCardType == .timer || newCardType == .timer_custom) ? newCardRingtone : nil,
                    primaryColor: newCardPrimary,
                    secondaryColor: newCardSecondary,
                    group: selectedGroup
                )
                
                // Ensure the relationship array exists then append for ordering
                if selectedGroup.cards == nil { selectedGroup.cards = [] }
                selectedGroup.cards?.append(newCard)
                
                // Insert into the model context so it persists
                context.insert(newCard)
            }
            
            // Save the context
            try context.save()
            resetFields(.viewModel)
        } catch {
            warnError.removeAll()
            warnError.append("Failed to save the card: \(error.localizedDescription)")
        }
    }
    
    /// A function that removes the card from the data model entity.
    /// Used to delete the card gracefully, adjusting existing card's indexes to take over a free index if applicable.
    func removeCard(_ card: DMStoredCard, with context: ModelContext) {
        do {
            // Remove the card from the context
            context.delete(card)
            
            // Remove the card from the group`s cards array
            selectedGroup.cards?.removeAll { $0.uuid == card.uuid }
            
            // Update indices of remaining cards
            let sortedCards = selectedGroup.cards!.sorted(by: { $0.index! < $1.index! })
            for (index, card) in sortedCards.enumerated() {
                card.index = index
            }
            
            // Save the context
            try context.save()
        } catch {
            warnError.removeAll()
            warnError.append("Failed to remove card: \(error.localizedDescription)")
        }
    }
    
    /// A function that checks the card's contents for any issues.
    /// Prevents empty titles for all card types and empty symbols for toggle cards.
    /// Appends errors to `validationError`.
    func validateForm() {
        withAnimation(.easeInOut(duration: 1.0)) {
            validationError.removeAll()
            
            if newCardTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                validationError.append("CardTitleEmpty")
            }
            
            if newCardType == .counter {
                for (index, modifierValue) in newCardModifier.enumerated() {
                    if modifierValue < 0 {
                        validationError.append("Modifier\(index)Negative")
                    }
                }
                if !newCardModifier.contains(where: { $0 > 0 }) {
                    validationError.append("ModifierLessThanOne")
                }
            } else if newCardType == .toggle {
                if newCardSymbol.trimmingCharacters(in: .whitespaces).isEmpty {
                    validationError.append("SymbolEmpty")
                }
                if newCardCount < minButtonLimit {
                    validationError.append("ButtonLessThanMin")
                } else if newCardCount > maxButtonLimit {
                    validationError.append("ButtonMoreThanMax")
                }
            } else if newCardType == .timer {
                if newCardCount < minTimerAmount || newCardCount > maxTimerAmount {
                    validationError.append("TimerExceedsLimits")
                }
                for (index, timerValue) in newCardTimer.enumerated() {
                    if timerValue < minTimerLimit {
                        validationError.append("Timer\(index)LessThanMin")
                    } else if timerValue > maxTimerLimit {
                        validationError.append("Timer\(index)MoreThanMax")
                    }
                }
            }
        }
    }
    
    /// A function that sets the temporary fields to defaults.
    /// Used to reset the contents after saving a card to free the fields for a new card.
    func resetFields(_ behaviour: resetFor? = .dismiss) {
        if behaviour == .dismiss {
            selectedCard = nil
        }
        newCardType = .counter
        newCardTitle = ""
        newCardCount = 1
        newCardModifier = [1, 0, 0]
        newButtonText = Array(repeating: "", count: 1)
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
        newTimerValues = [0 : [0, 0 ,0]]
        newCardTimer = Array(repeating: 0, count: 1)
        newCardRingtone = ""
        newCardPrimary = .blue
        newCardSecondary = .white
    }
}
