//
//  DataModels.swift
//  TrackCount
//
//  Contains the data models for groups and cards.
//

import Foundation
import SwiftData
import SwiftUI

/// A data model entity representing a group of cards in the app's database.
/// Includes metadata like group title, symbol, and the associated cards.
@Model
class DMCardGroup: Identifiable {
    /// A unique identifier for the group.
    var uuid: UUID = UUID()
    
    /// The order the group appears.
    var index: Int? = 0
    
    /// The title of the group.
    var groupTitle: String? = ""
    
    /// The symbol of the group.
    var groupSymbol: String? = ""
    
    /// The list of cards associated with the group.
    @Relationship(deleteRule: .cascade, inverse: \DMStoredCard.group) var cards: [DMStoredCard]? = []
    
    /// Initializes a new instance of DMCardGroup.
    init(uuid: UUID = UUID(), index: Int, groupTitle: String = "", groupSymbol: String = "", cards: [DMStoredCard] = []) {
        self.uuid = uuid
        self.index = index
        self.groupTitle = groupTitle
        self.groupSymbol = groupSymbol
        self.cards = cards
    }
}

/// A data model entity representing the cards in the app's database.
/// Includes metadata like the card's index, type, title, and other contents.
@Model
class DMStoredCard: Identifiable {
    // Types of tracker
    enum Types: String, Codable, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case counter // A number counter
        case toggle // A toggle button
        case timer // A predefined timer
        case timer_custom // A timer set on the fly
    }
    
    /// Allows referencing the card without conflicts.
    var uuid: UUID = UUID()
    
    /// A variable that stores the order the card appears.
    var index: Int? = 0
    
    /// The card type, either a counter or toggle.
    var type: Types?
    
    /// The title of the card.
    var title: String = ""
    
    // Shared
    /// The amount counted (counter), amount of buttons (toggle) or amount of timers stored (timer).
    var count: Int = 1
    
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
    var primaryColor: CodableColor?
    
    /// The color used for the button contents (text and symbols) and timer text.
    var secondaryColor: CodableColor?
    
    /// The group this card belongs to.
    var group: DMCardGroup?
    
    /// Initializes a new instance of DMStoredCard.
    init(uuid: UUID = UUID(),
         index: Int,
         type: Types,
         title: String,
         count: Int,
         state: [Bool]? = [],
         modifier: [Int]? = [],
         buttonText: [String]? = [],
         symbol: String? = "",
         timer: [Int]? = [],
         timerRingtone: String? = "",
         primaryColor: Color,
         secondaryColor: Color,
         group: DMCardGroup)
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
        self.group = group
    }
}

extension DMCardGroup {
    /// Packages the group and its cards into a shareable format.
    /// - Returns: Group encoded in JSON.
    func encodeForSharing() throws -> Data {
        let shareData = ShareableGroup(
            groupTitle: self.groupTitle ?? "",
            groupSymbol: self.groupSymbol ?? "",
            cards: self.cards?.map { card in
                ShareableCard(
                    type: card.type,
                    title: card.title,
                    count: card.count,
                    modifier: card.modifier?.map { $0.modifier },
                    buttonText: card.buttonText?.map { $0.buttonText },
                    symbol: card.symbol,
                    timer: card.timer?.map { $0.timerValue },
                    timerRingtone: card.timerRingtone,
                    primaryColor: card.primaryColor,
                    secondaryColor: card.secondaryColor
                )
            }
        )
        return try JSONEncoder().encode(shareData)
    }
    
    /// Creates a temporary preview model from shared data without SwiftData context
    /// - Parameter data: The data to be decoded/unpacked.
    /// - Returns: A preview group that can be displayed without database insertion.
    static func createPreviewFromShared(_ data: Data) throws -> PreviewCardGroup {
        let shareData = try JSONDecoder().decode(ShareableGroup.self, from: data)
        
        let previewCards = shareData.cards?.map { cardData in
            PreviewCard(
                type: cardData.type ?? .counter,
                title: cardData.title ?? "",
                count: cardData.count ?? 1,
                modifier: cardData.modifier,
                buttonText: cardData.buttonText,
                symbol: cardData.symbol,
                timer: cardData.timer,
                timerRingtone: cardData.timerRingtone,
                primaryColor: cardData.primaryColor,
                secondaryColor: cardData.secondaryColor
            )
        } ?? []
        
        return PreviewCardGroup(
            groupTitle: shareData.groupTitle ?? "",
            groupSymbol: shareData.groupSymbol ?? "",
            cards: previewCards
        )
    }
}

// Wrap types to conform to Codable, supresses CoreData faults
// via https://stackoverflow.com/a/79060754

struct CardState: Codable, Equatable {
    var state: Bool
}

struct CounterModifier: Codable {
    let modifier: Int
}

struct ButtonText: Codable {
    let buttonText: String
}

struct TimerValue: Codable {
    var timerValue: Int
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
        }
    }
}

// MARK: - Sharing Structures
/// Codable group structure for sharing.
struct ShareableGroup: Codable {
    let groupTitle: String?
    let groupSymbol: String?
    let cards: [ShareableCard]?
}

/// Codable card structure for sharing.
struct ShareableCard: Codable {
    let type: DMStoredCard.Types?
    let title: String?
    let count: Int?
    let modifier: [Int]?
    let buttonText: [String]?
    let symbol: String?
    let timer: [Int]?
    let timerRingtone: String?
    let primaryColor: CodableColor?
    let secondaryColor: CodableColor?
}

/// Temporary preview models for import that don't require SwiftData context
/// These are used for displaying import previews without database insertion
class PreviewCardGroup: ObservableObject, Identifiable {
    let id = UUID()
    let groupTitle: String
    let groupSymbol: String
    let cards: [PreviewCard]
    
    init(groupTitle: String, groupSymbol: String, cards: [PreviewCard]) {
        self.groupTitle = groupTitle
        self.groupSymbol = groupSymbol
        self.cards = cards
    }
}

class PreviewCard: ObservableObject, Identifiable {
    let id = UUID()
    let type: DMStoredCard.Types
    let title: String
    let count: Int
    let modifier: [Int]?
    let buttonText: [String]?
    let symbol: String?
    let timer: [Int]?
    let timerRingtone: String?
    let primaryColor: CodableColor?
    let secondaryColor: CodableColor?
    
    init(type: DMStoredCard.Types, title: String, count: Int, modifier: [Int]? = nil,
         buttonText: [String]? = nil, symbol: String? = nil, timer: [Int]? = nil,
         timerRingtone: String? = nil, primaryColor: CodableColor? = nil,
         secondaryColor: CodableColor? = nil) {
        self.type = type
        self.title = title
        self.count = count
        self.modifier = modifier
        self.buttonText = buttonText
        self.symbol = symbol
        self.timer = timer
        self.timerRingtone = timerRingtone
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
}

extension PreviewCardGroup {
    /// Convert to actual SwiftData model for database insertion
    func toSwiftDataModel(context: ModelContext) throws -> DMCardGroup {
        let group = DMCardGroup(
            uuid: UUID(),
            index: 0, // Will be updated when added to context
            groupTitle: groupTitle,
            groupSymbol: groupSymbol
        )
        
        // Insert the group first to establish it in the context
        context.insert(group)
        
        // Now create and insert cards one by one
        for (index, previewCard) in cards.enumerated() {
            let card = previewCard.toSwiftDataModel(index: index, group: group)
            context.insert(card)
            
            // Add to group's cards array after both objects are in context
            if group.cards == nil {
                group.cards = []
            }
            group.cards?.append(card)
        }
        
        return group
    }
}

extension PreviewCard {
    /// Convert to actual SwiftData model for database insertion
    func toSwiftDataModel(index: Int, group: DMCardGroup) -> DMStoredCard {
        return DMStoredCard(
            uuid: UUID(),
            index: index,
            type: type,
            title: title,
            count: count,
            state: type == .toggle ? Array(repeating: true, count: count) :
                (type == .timer || type == .timer_custom ? Array(repeating: false, count: 1) : []),
            modifier: modifier,
            buttonText: buttonText,
            symbol: symbol,
            timer: timer,
            timerRingtone: timerRingtone,
            primaryColor: primaryColor?.color ?? .blue,
            secondaryColor: secondaryColor?.color ?? .white,
            group: group
        )
    }
}
