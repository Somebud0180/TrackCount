//
//  CardStore.swift
//  TrackCount
//
//  Represents a store for the tracking cards and its contents.
//

import Foundation
import SwiftData

@Model
final class CardStore {
    // Types of tracker
    enum Types: String, Codable, CaseIterable {
        case counter // A number counter
        case toggle // A toggle button
    }
    
    @Attribute(.unique) var uuid: UUID? // Unique identifier for the card
    @Attribute(.unique) var index: Int // The order the card appears
    var type: Types // The card type, either a counter or toggle
    var title: String // The title for the card
    var buttonText: [String]? // The text in button (toggle)
    var count: Int // The amount counted (counter) or amount of buttons (toggle)
    var state: [Bool]? // The state of the button, either pressed or not (toggle)
    var symbol: String? // The symbol of the button (toggle)
    
    // Initializes a new instance of GridStore.
    init(uuid: UUID, index: Int, type: Types, title: String, buttonText: [String]? = nil, count: Int, state: [Bool]? = nil, symbol: String? = nil) {
        self.uuid = uuid
        self.index = index
        self.type = type
        self.title = title
        self.buttonText = buttonText
        self.count = count
        self.state = state
        self.symbol = symbol
        
        // Perform validation after initialization
        validateCardType()
    }
    
    // Function to validate required properties based on type
    private func validateCardType() {
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
