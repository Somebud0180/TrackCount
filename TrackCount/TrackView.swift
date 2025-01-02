//
//  TrackView.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData

struct TrackView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var selectedGroup: DMCardGroup
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Determine the number of columns based on device and orientation
                let columns = determineColumns()
                
                // Define the grid layout
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns), spacing: 16) {
                    if selectedGroup.cards.isEmpty {
                        // Display a message when there are no cards
                        Text("You have no cards yet")
                            .font(.title)
                            .foregroundColor(.gray)
                    } else {
                        // Iterate through the sorted cards and display each card
                        ForEach(selectedGroup.cards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                            gridCard(card)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selectedGroup.groupTitle)
        }
    }
    
    /// Determines the number of columns based on device type and orientation.
    private func determineColumns() -> Int {
        let deviceIdiom = UIDevice.current.userInterfaceIdiom
        let isPortrait = verticalSizeClass == .regular
        
        switch (deviceIdiom, isPortrait) {
        case (.phone, true):
            // Portrait iPhone
            return 1
        case (.phone, false):
            // Landscape iPhone
            if selectedGroup.cards.count <= 2 {
                // Display all cards if total card count is below or equal to default
                return selectedGroup.cards.count
            } else {
                return 2
            }
        case (.pad, true):
            // Portrait iPad
            if selectedGroup.cards.count <= 2 {
                // Display all cards if total card count is below or equal to default
                return selectedGroup.cards.count
            } else {
                return 2
            }
        case (.pad, false):
            // Landscape iPad
            if selectedGroup.cards.count <= 2 {
                // Display all cards if total card count is below or equal to default
                return selectedGroup.cards.count
            } else {
                return 3
            }
        default:
            // Fallback to 2 columns
            return 2
        }
    }
    
    /// Builds the inputted card into a visible card according to it's type.
    private func gridCard(_ card: DMStoredCard) -> some View {
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundStyle(.thickMaterial)
                    .shadow(radius: 5)
                if card.type == .counter {
                    counterCard(card)
                } else if card.type == .toggle {
                    toggleCard(card)
                }
            }
                .padding()
        )
    }
    
    /// Creates the toggle card contents from the inputted card.
    private func toggleCard(_ card: DMStoredCard) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(0..<card.count, id: \.self) { index in
                    toggleButton(card, id: index)
                }
            }
            Spacer()
        }
        .padding()
    }
    
    /// Creates the counter card contents from the inputted card.
    private func counterCard(_ card: DMStoredCard) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Increment Button
            Button(action: { card.count += 1 }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(card.secondaryColor.color)
                    .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(card.primaryColor.color)
            
            // Current Count
            Text(String(card.count))
                .font(.title)
            
            // Decrement Button
            Button(action: { card.count -= 1 }) {
                Image(systemName: "minus")
                    .font(.title)
                    .foregroundStyle(card.secondaryColor.color)
                    .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(card.primaryColor.color)
            
            Spacer()
        }
        .padding()
    }
    
    /// Creates buttons with data from the inputted card and index
    private func toggleButton(_ card: DMStoredCard, id: Int) -> some View {
        Button(action: {
            card.state![id].toggle()
        }) {
            HStack {
                if let buttonText = card.buttonText?[id], !buttonText.isEmpty {
                    Text(buttonText)
                        .font(.body)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .foregroundStyle(card.state![id] ? card.secondaryColor.color : .black)
                }
                Image(systemName: card.symbol!)
                    .font(.body)
                    .minimumScaleFactor(0.2)
                    .foregroundStyle(card.state![id] ? card.secondaryColor.color : .black)
            }
            // Make the button fill available space
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(5)
        }
        .buttonStyle(.borderedProminent)
        .tint(card.state![id] ? card.primaryColor.color : .secondary)
    }
}

#Preview {
    // An example set of cards
    // Contains 1 counter card and 1 toggle card
    let exampleCards: [DMStoredCard] = [
        DMStoredCard(uuid: UUID(), index: 0, type: .counter, title: "Test Counter", count: 0, primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 1, type: .toggle, title: "Test Toggle", buttonText: ["", "", "", "", ""], count: 5, state: [true, true, true, true, true], symbol: "trophy.fill", primaryColor: .gray, secondaryColor: .yellow)
    ]
    
    // An example group
    // Contains an example set of cards
    var exampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Test", groupSymbol: "", cards: exampleCards)
    }
    
    TrackView(selectedGroup: exampleGroup)
}
