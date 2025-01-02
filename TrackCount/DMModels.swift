//
//  DMModels.swift
//  TrackCount
//
//  Represents a store for the card groups and the tracking cards.
//

import Foundation
import SwiftData
import SwiftUI

/// A data model entity representing a group of cards in the app's database.
/// Includes metadata like group title, symbol, and the associated cards.
@Model
final class DMCardGroup: Identifiable {
    
    /// A unique identifier for the group
    @Attribute(.unique) var uuid: UUID
    
    /// The order the group appears
    var index: Int
    
    /// The title of the group
    var groupTitle: String
    
    /// The symbol of the group
    var groupSymbol: String
    
    /// The list of cards associated with the group.
    @Relationship(deleteRule: .cascade) var cards: [DMStoredCard] = []
    
    /// Initializes a new instance of DMCardGroup.
    init(uuid: UUID, index: Int, groupTitle: String, groupSymbol: String, cards: [DMStoredCard] = []) {
        self.uuid = uuid
        self.index = index
        self.groupTitle = groupTitle
        self.groupSymbol = groupSymbol
        self.cards = cards
        
        validateCardGroup() // Validate group card after initialization
    }
    
    /// A function that checks the card group for any issues.
    /// Checks if the card contains atlease either one of two variables (groupTitle and groupSymbol).
    private func validateCardGroup() {
        let titleIsEmpty = groupTitle.isEmpty
        let symbolIsEmpty = groupSymbol.isEmpty
        
        // If both title and symbol are empty, throw an error (or handle as needed)
        if titleIsEmpty && symbolIsEmpty {
            fatalError("Either the title or symbol must be provided")
        }
    }
}

/// A data model entity representing the cards in the app's database.
/// Includes metadata like the card's index, type, title, and other contents.
@Model
final class DMStoredCard: Identifiable {
    // Types of tracker
    enum Types: String, Codable, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case counter // A number counter
        case toggle // A toggle button
    }
    
    /// A unique identifier for the card.
    /// Allows referencing the card without conflicts.
    @Attribute(.unique) var uuid: UUID
    
    /// A variable that stores the order the card appears.
    var index: Int
    
    /// The card type, either a counter or toggle.
    var type: Types
    
    /// The title of the card.
    var title: String
    
    /// The text inside the button (toggle).
    var buttonText: [String]?
    
    /// The amount counted (counter) or amount of buttons (toggle).
    var count: Int
    
    /// The state of the button, either pressed or not (toggle).
    var state: [Bool]?
    
    /// The symbol of the button (toggle).
    var symbol: String?
    
    /// The color used for buttons
    var primaryColor: CodableColor
    
    /// The color used for the button contents (text and symbols)
    var secondaryColor: CodableColor
    
    /// Initializes a new instance of DMStoredCard.
    init(uuid: UUID, index: Int, type: Types, title: String, buttonText: [String]? = nil, count: Int, state: [Bool]? = nil, symbol: String? = nil, primaryColor: Color = .blue, secondaryColor: Color = .white) {
        self.uuid = uuid
        self.index = index
        self.type = type
        self.title = title
        self.buttonText = buttonText
        self.count = count
        self.state = state
        self.symbol = symbol
        self.primaryColor = CodableColor(color: primaryColor)
        self.secondaryColor = CodableColor(color: secondaryColor)
        
        validateStoredCard() // Perform card validation after initialization
    }
    
    /// A function that checks the stored cards for any issues.
    /// Checks if a counter card contains extraneous variables or if a toggle card is missing required variables.
    private func validateStoredCard() {
        switch type {
        case .counter:
            // For Counter type, ensure toggle-specific properties are nil
            assert(buttonText == nil, "buttonText should be nil for Counter type.")
            assert(state == nil, "state should be nil for Counter type.")
            assert(symbol == nil, "symbol should be nil for Counter type.")
            
        case .toggle:
            // For Toggle type, ensure toggle-specific properties are not nil
            guard let _ = buttonText,
                  let _ = state,
                  let _ = symbol else {
                fatalError("buttonText, state, and symbol are required for Toggle type.")
            }
        }
    }
}
