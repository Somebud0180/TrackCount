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
    /// A unique identifier for the group.
    @Attribute(.unique) var uuid: UUID
    
    /// The order the group appears.
    var index: Int
    
    /// The title of the group.
    var groupTitle: String
    
    /// The symbol of the group.
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
        
        // Validate group card after initialization
        validateCardGroup()
    }
    
    /// Checks if the card contains at least either one of two variables (groupTitle and groupSymbol).
    /// Checks if the card contains atlease either one of two variables (groupTitle and groupSymbol).
    private func validateCardGroup() {
        let titleIsEmpty = groupTitle.isEmpty
        let symbolIsEmpty = groupSymbol.isEmpty
        
        // If both title and symbol are empty, throw an error (or handle as needed)
        if titleIsEmpty && symbolIsEmpty {
            fatalError("Either the title or symbol must be provided")
        }
    }
    
    /// Packages the group and its cards into a shareable format.
    /// - Returns: Group encoded in JSON.
    func encodeForSharing() throws -> Data {
        let shareData = ShareableGroup(
            groupTitle: self.groupTitle,
            groupSymbol: self.groupSymbol,
            cards: self.cards.map { card in
                ShareableCard(
                    type: card.type,
                    title: card.title,
                    count: card.count,
                    modifier: card.modifier?.map { $0.modifier },
                    buttonText: card.buttonText?.map { $0.buttonText },
                    symbol: card.symbol,
                    timer: card.timer?.map { $0.timerValue },
                    primaryColor: card.primaryColor,
                    secondaryColor: card.secondaryColor
                )
            }
        )
        return try JSONEncoder().encode(shareData)
    }
    
    /// Unpacks the shareable format into the app's standard group and cards.
    /// - Parameters:
    ///   - data: The data to be decoded/unpacked.
    ///   - context: The context where the data is saved.
    /// - Returns: A standard group and card.
    static func decodeFromShared(_ data: Data, context: ModelContext) throws -> DMCardGroup {
        let shareData = try JSONDecoder().decode(ShareableGroup.self, from: data)
        let group = DMCardGroup(
            uuid: UUID(),
            index: 0, // Will be updated when added to context
            groupTitle: shareData.groupTitle,
            groupSymbol: shareData.groupSymbol
        )
        
        // Create cards from shared data
        group.cards = try shareData.cards.enumerated().map { index, cardData in
            if cardData.type == .counter {
                return DMStoredCard(
                    uuid: UUID(),
                    index: index,
                    type: cardData.type,
                    title: cardData.title,
                    count: cardData.count,
                    modifier: cardData.modifier,
                    primaryColor: cardData.primaryColor.color,
                    secondaryColor: cardData.secondaryColor.color
                )
            } else if cardData.type == .toggle {
                return DMStoredCard(
                    uuid: UUID(),
                    index: index,
                    type: cardData.type,
                    title: cardData.title,
                    count: cardData.count,
                    state: Array(repeating: true, count: cardData.count),
                    buttonText: cardData.buttonText,
                    symbol: cardData.symbol,
                    primaryColor: cardData.primaryColor.color,
                    secondaryColor: cardData.secondaryColor.color
                )
            } else if cardData.type == .timer || cardData.type == .timer_custom {
                return DMStoredCard(
                    uuid: UUID(),
                    index: index,
                    type: cardData.type,
                    title: cardData.title,
                    count: cardData.count,
                    state: Array(repeating: false, count: 1),
                    timer: cardData.timer,
                    primaryColor: cardData.primaryColor.color,
                    secondaryColor: cardData.secondaryColor.color
                )
            } else {
                throw NSError(domain: "Invalid card type", code: 0, userInfo: nil)
            }
        }
        
        return group
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
        case timer // A predefined timer
        case timer_custom // A timer set on the fly
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
    
    // Shared
    /// The amount counted (counter), amount of buttons (toggle) or amount of timers stored (timer).
    var count: Int
    
    /// The state of the button, either pressed or not (toggle) or the state of the timer, either paused or counting (timer).
    var state: [CardState]?
    
    // Counter-Specific
    /// The different modifiers for the counter.
    /// Example: [1] will add a button that modifies the variable by one
    var modifier: [CounterModifier]?
    
    // Button-Specific
    /// The text inside the button.
    var buttonText: [ButtonText]?
    
    /// The symbol of the button.
    var symbol: String?
    
    // Timer specific
    /// The countdown and saved value(s) for timers.
    var timer: [TimerValue]?
    
    /// The timer card custom ringtone
    var timerRingtone: String?
    
    // Colors
    /// The color used for buttons or progress bars.
    var primaryColor: CodableColor
    
    /// The color used for the button contents (text and symbols) and timer text.
    var secondaryColor: CodableColor
    
    /// Initializes a new instance of DMStoredCard.
    init(uuid: UUID,
         index: Int,
         type: Types,
         title: String,
         count: Int,
         state: [Bool]? = nil,
         modifier: [Int]? = nil,
         buttonText: [String]? = nil,
         symbol: String? = nil,
         timer: [Int]? = nil,
         timerRingtone: String? = nil,
         primaryColor: Color,
         secondaryColor: Color)
    {
        self.uuid = uuid
        self.index = index
        self.type = type
        self.title = title
        self.count = count
        self.state = state?.map { CardState(state: $0) }
        self.modifier = modifier?.map { CounterModifier(modifier: $0) }
        self.buttonText = buttonText?.map { ButtonText(buttonText: $0) }
        self.symbol = symbol
        self.timer = timer?.map { TimerValue(timerValue: $0) }
        self.timerRingtone = timerRingtone
        self.primaryColor = CodableColor(color: primaryColor)
        self.secondaryColor = CodableColor(color: secondaryColor)
        
        // Perform card validation after initialization
        validateStoredCard()
    }
    
    /// A function that checks the stored cards for any issues.
    /// Checks if a counter card contains extraneous variables or if a toggle card is missing required variables.
    /// In some cases, patches missing variables with defaults where possible.
    func validateStoredCard() {
        switch type {
        case .counter:
            // For Counter type, ensure counter-specific properties are filled
            assert(buttonText == nil, "buttonText should be nil for Counter type.")
            assert(state == nil, "state should be nil for Counter type.")
            assert(symbol == nil, "symbol should be nil for Counter type.")
            assert(timer == nil, "timer should be nil for Counter type.")
            
            if modifier == nil || modifier?.isEmpty == true {
                self.modifier = [CounterModifier(modifier: 1)]
            }
            
        case .toggle:
            // For Toggle type, ensure toggle-specific properties are filled
            assert(modifier == nil, "modifier should be nil for Timer type.")
            assert(timer == nil, "timer should be nil for Counter type.")
            
            guard let _ = buttonText else {
                fatalError("buttonText is empty but is required for Toggle type.")
            }
            guard let _ = state else {
                fatalError("state is empty but is required for Toggle type.")
            }
            guard let _ = symbol else {
                fatalError("symbol is empty but is required for Toggle type.")
            }
            
        case .timer, .timer_custom:
            // For Timer type, ensure timer-specific properties are filled
            assert(modifier == nil, "modifier should be nil for Timer type.")
            assert(buttonText == nil, "buttonText should be nil for Timer type.")
            assert(symbol == nil, "symbol should be nil for Timer type.")
            
            if state == nil || state?.isEmpty == true {
                self.state = [CardState(state: false)]
            }
            
            guard let _ = timer else {
                fatalError("timer is empty but is required for Timer type.")
            }
        }
    }
}

// Wrap types to conform to Codable, supresses CoreData faults
// via https://stackoverflow.com/a/79060754

struct CardState: Codable {
    var state: Bool
}

struct CounterModifier: Codable {
    let modifier: Int
}

struct ButtonText: Codable {
    let buttonText: String
}

struct TimerValue: Codable {
    let timerValue: Int
}

/// Definition for DMStoredCard types
extension DMStoredCard.Types {
    var typeDescription: String {
        switch self {
        case .counter:
            return "Contains a simple counter that can be increased or decreased with a defined amount."
        case .toggle:
            return "Contains buttons that can be toggled with customizable text and symbols."
        case .timer:
            return "Contains up to 4 preset timers that can be started with a tap."
        case .timer_custom:
            return "Contains a single customizable timer."
        default:
            return "A card type"
        }
    }
}


/// Codable group structure for sharing.
struct ShareableGroup: Codable {
    let groupTitle: String
    let groupSymbol: String
    let cards: [ShareableCard]
}

/// Codable card structure for sharing.
struct ShareableCard: Codable {
    let type: DMStoredCard.Types
    let title: String
    let count: Int
    let modifier: [Int]?
    let buttonText: [String]?
    let symbol: String?
    let timer: [Int]?
    let primaryColor: CodableColor
    let secondaryColor: CodableColor
}
