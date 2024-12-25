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
    var buttonText: [String] // The text in button (toggle)
    var count: Int // The amount counted (counter) or amount of buttons (toggle)
    var state: [Bool] // The state of the button, either pressed or not (toggle)
    var symbol: String // The symbol of the button (toggle)
    
    // Initializes a new instance of GridStore.
    init(uuid: UUID, index: Int, type: Types, title: String, buttonText: [String], count: Int, state: [Bool], symbol: String) {
        self.uuid = uuid
        self.index = index
        self.type = type
        self.title = title
        self.buttonText = buttonText
        self.count = count
        self.state = state
        self.symbol = symbol
    }
}
