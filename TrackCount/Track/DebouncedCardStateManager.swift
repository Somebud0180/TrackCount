//
//  DebouncedCardStateManager.swift
//  TrackCount
//
//  Manages debounced card state changes to reduce CloudKit saves
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class DebouncedCardStateManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Temporary toggle states for immediate UI feedback (UUID -> [button index -> state])
    private var temporaryToggleStates: [UUID: [Int: Bool]] = [:]
    
    /// Cards that have pending changes (UUID -> card reference)
    private var pendingCards: [UUID: DMStoredCard] = [:]
    
    /// Debounce timers for each card (UUID -> Timer)
    private var saveTimers: [UUID: Timer] = [:]
    
    /// Delay before saving changes (in seconds)
    private let saveDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    init() {
        // Clean initialization
    }
    
    // MARK: - Public Methods
    
    /// Get the current effective state for a toggle button (temporary or actual card state)
    func getToggleState(for card: DMStoredCard, buttonIndex: Int) -> Bool {
        // Return temporary state if exists, otherwise return actual card state
        if let temporaryStates = temporaryToggleStates[card.uuid],
           let temporaryState = temporaryStates[buttonIndex] {
            return temporaryState
        }
        
        return card.state?[buttonIndex].state ?? false
    }
    
    /// Toggle a button state with debounced saving
    func toggleState(of card: DMStoredCard, at buttonIndex: Int, with context: ModelContext) {
        // Initialize temporary states for this card if needed
        if temporaryToggleStates[card.uuid] == nil {
            temporaryToggleStates[card.uuid] = [:]
        }
        
        // Store reference to the card for timer handling
        pendingCards[card.uuid] = card
        
        // Get current effective state and toggle it
        let currentState = getToggleState(for: card, buttonIndex: buttonIndex)
        let newState = !currentState
        
        // Store the new state temporarily for immediate UI feedback
        // Use non-published property to avoid triggering updates for other buttons
        temporaryToggleStates[card.uuid]?[buttonIndex] = newState
        
        // Directly update the card state for immediate UI feedback
        // This prevents flickering by ensuring the UI reads the correct state immediately
        if card.state?.indices.contains(buttonIndex) == true {
            card.state?[buttonIndex].state = newState
        }
        
        // Reset the debounce timer - when it fires, it will save to CloudKit
        resetSaveTimer(for: card.uuid, with: context)
    }
    
    /// Apply all temporary changes to actual card state and save
    func applyTemporaryChanges(for card: DMStoredCard, with context: ModelContext) {
        guard let temporaryStates = temporaryToggleStates[card.uuid] else { return }
        
        // Apply temporary changes to the actual card state
        for (buttonIndex, newState) in temporaryStates {
            if card.state?.indices.contains(buttonIndex) == true {
                card.state?[buttonIndex].state = newState
            }
        }
        
        // Clear temporary states and pending card reference
        temporaryToggleStates[card.uuid] = nil
        pendingCards[card.uuid] = nil
        
        // Clear and invalidate the timer for this specific card
        saveTimers[card.uuid]?.invalidate()
        saveTimers[card.uuid] = nil
        
        // Save to model context
        saveToContext(context)
    }
    
    /// Apply all temporary changes for all cards immediately
    func applyAllTemporaryChanges(with context: ModelContext) {
        // Apply all pending changes first
        for (cardUUID, card) in pendingCards {
            if let temporaryStates = temporaryToggleStates[cardUUID] {
                for (buttonIndex, newState) in temporaryStates {
                    if card.state?.indices.contains(buttonIndex) == true {
                        card.state?[buttonIndex].state = newState
                    }
                }
            }
        }
        
        // Invalidate all existing timers
        for timer in saveTimers.values {
            timer.invalidate()
        }
        saveTimers.removeAll()
        
        // Clear all temporary states and pending cards
        temporaryToggleStates.removeAll()
        pendingCards.removeAll()
        
        // Save to context
        saveToContext(context)
    }
    
    /// Check if a card has temporary changes
    func hasTemporaryChanges(for card: DMStoredCard) -> Bool {
        return temporaryToggleStates[card.uuid]?.isEmpty == false
    }
    
    /// Get all cards with temporary changes
    func getCardsWithTemporaryChanges() -> Set<UUID> {
        return Set(temporaryToggleStates.keys.filter { !temporaryToggleStates[$0]!.isEmpty })
    }
    
    // MARK: - Private Methods
    
    private func resetSaveTimer(for cardUUID: UUID, with context: ModelContext) {
        // Invalidate existing timer if any
        saveTimers[cardUUID]?.invalidate()
        
        // Create a new timer for the debounce interval that only saves, doesn't apply changes
        let timer = Timer.scheduledTimer(withTimeInterval: saveDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTimerFired(for: cardUUID)
            }
        }
        
        // Store the timer in the dictionary
        saveTimers[cardUUID] = timer
    }
    
    /// Handle timer firing for a specific card
    private func handleTimerFired(for cardUUID: UUID) {
        // When timer fires, just clear the temporary states since we've already applied changes immediately
        temporaryToggleStates[cardUUID] = nil
        pendingCards[cardUUID] = nil
        
        // Clear and invalidate the timer for this specific card
        saveTimers[cardUUID]?.invalidate()
        saveTimers[cardUUID] = nil
        
        // Note: We don't need to save here anymore since changes are applied immediately
        // The debounce only prevents rapid successive saves, not the state changes themselves
        print("Debounce timer completed for card \(cardUUID)")
    }
    
    private func saveToContext(_ context: ModelContext) {
        do {
            try context.save()
            print("Debounced card state changes saved successfully")
        } catch {
            print("Failed to save debounced card state changes: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Invalidate all timers on deinitialization
        for timer in saveTimers.values {
            timer.invalidate()
        }
    }
}
