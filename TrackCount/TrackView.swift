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
            return 2
        case (.pad, true):
            // Portrait iPad
            return 2
        case (.pad, false):
            // Landscape iPad
            return 3
        default:
            // Fallback to 2 columns
            return 2
        }
    }
    
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
                    .foregroundStyle(.primary)
                    .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
            
            // Current Count
            Text(String(card.count))
                .font(.title)
            
            // Decrement Button
            Button(action: { card.count -= 1 }) {
                Image(systemName: "minus")
                    .font(.title)
                    .foregroundStyle(.primary)
                    .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
    
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
                }
                Image(systemName: card.symbol!)
            }
            // Make the button fill available space
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.blue)
        // Change foreground style based on state
        .foregroundStyle(card.state![id] ? .white : .secondary)
    }
}

#Preview {
    GroupListView(viewBehaviour: .view)
        .modelContainer(for: DMCardGroup.self)
}
