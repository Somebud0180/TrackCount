//
//  GridStore.swift
//  TrackCount
//
//  Represents a store for the trackers in the grid.
//

import Foundation
import SwiftData

@Model
class GridStore {
    // Types of tracker
    enum Types: String, Codable, CaseIterable {
        case counter
        case toggle
    }
    
    var id: Int // The order the card is displayed
    var type: Types // Either a counter or toggle
    var text: String // The title for the card
    var buttonText: String // The text in button (toggle)
    var count: Int // The amount counted (counter)
    var state: [Bool] // The boolean of the button (toggle)
    var symbol: String // The boolean of the button (toggle)
    
    // Initializes a new instance of GridStore.
    init(id: Int, type: Types, text: String, buttonText: String, count: Int, state: [Bool], symbol: String) {
        self.id = id
        self.type = type
        self.text = text
        self.buttonText = buttonText
        self.count = count
        self.state = state
        self.symbol = symbol
    }
}
