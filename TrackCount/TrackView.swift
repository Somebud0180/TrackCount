//
//  TrackView.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct TrackView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject var viewModel: TimerViewModel
    var selectedGroup: DMCardGroup
    
    init(selectedGroup: DMCardGroup) {
        _viewModel = StateObject(wrappedValue: TimerViewModel())
        self.selectedGroup = selectedGroup
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Determine the number of columns based on device and orientation
                let columns = determineColumns()
                
                // Define the grid layout
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 4) {
                    if selectedGroup.cards.isEmpty {
                        // Display a message when there are no cards
                        Text("You have no cards yet")
                            .font(.title)
                            .foregroundStyle(.gray)
                    } else {
                        // Iterate through the sorted cards and display each card
                        ForEach(selectedGroup.cards.sorted(by: { $0.index < $1.index }), id: \.uuid) { card in
                            gridCard(card)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitleViewBuilder {
            if selectedGroup.groupTitle.isEmpty {
                Image(systemName: selectedGroup.groupSymbol)
            } else {
                Text(selectedGroup.groupTitle)
            }
        }
        .onDisappear {
            viewModel.timerCleanup() // Clean up timers on exit
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
            if selectedGroup.cards.count < 2 {
                // Display all cards if total card count is below default
                return selectedGroup.cards.count
            } else {
                return 2
            }
        case (.pad, true):
            // Portrait iPad
            if selectedGroup.cards.count < 2 {
                // Display all cards if total card count is below default
                return selectedGroup.cards.count
            } else {
                return 2
            }
        case (.pad, false):
            // Landscape iPad (Theoretially never the case)
            if selectedGroup.cards.count < 2 {
                // Display all cards if total card count is below default
                return selectedGroup.cards.count
            } else {
                return 2
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
                } else if card.type == .timer || card.type == .timer_custom {
                    timerCard(card)
                }
            }
                .padding()
        )
    }
    
    /// Creates the counter card contents from the inputted card.
    private func counterCard(_ card: DMStoredCard) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Increment Button(s)
            HStack {
                if let modifiers = card.modifier {
                    ForEach(0..<modifiers.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring) {
                                card.count += modifiers[index]
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.title)
                                    .minimumScaleFactor(0.5)
                                    .foregroundStyle(card.secondaryColor.color)
                                    .frame(height: 30)
                                if modifiers[index] != 1 {
                                    Text("\(modifiers[index])")
                                        .font(.title2)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(card.secondaryColor.color)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(card.primaryColor.color)
                        .accessibilityLabel("Increase \(card.title) by \(modifiers[index])")
                    }
                    .padding(.horizontal, 3)
                }
            }
            
            // Current Count
            Text(String(card.count))
                .font(.largeTitle)
                .contentTransition(.numericText())
                .animation(.spring, value: card.count)
                .accessibilityValue("\(card.count)")
            
            // Decrement Button
            HStack {
                if let modifiers = card.modifier {
                    ForEach(0..<modifiers.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring) {
                                card.count -= modifiers[index]
                            }
                        }) {
                            HStack {
                                Image(systemName: "minus")
                                    .font(.title)
                                    .foregroundStyle(card.secondaryColor.color)
                                    .frame(height: 30)
                                if modifiers[index] != 1 {
                                    Text("\(modifiers[index])")
                                        .font(.title)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(card.secondaryColor.color)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(card.primaryColor.color)
                        .accessibilityLabel("Reduce \(card.title) by \(modifiers[index])")
                    }
                    .padding(.horizontal, 3)
                }
            }
            
            Spacer()
        }
        .padding()
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
    
    /// Creates buttons with data from the inputted card and index.
    private func toggleButton(_ card: DMStoredCard, id: Int) -> some View {
        // Safely access state array
        let isActive = card.state?.indices.contains(id) == true ? card.state![id] : false
        
        return Button(action: {
            // Safely toggle state
            if card.state?.indices.contains(id) == true {
                card.state![id].toggle()
            }
        }) {
            HStack {
                if let buttonText = card.buttonText?[id], !buttonText.isEmpty {
                    Text(buttonText)
                        .font(.body)
                        .minimumScaleFactor(0.3)
                        .lineLimit(2)
                        .foregroundStyle(isActive ? card.secondaryColor.color : .black)
                }
                Image(systemName: card.symbol ?? "")
                    .font(.body)
                    .minimumScaleFactor(0.2)
                    .foregroundStyle(isActive ? card.secondaryColor.color : .black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(1)
        }
        .buttonStyle(.borderedProminent)
        .tint(isActive ? card.primaryColor.color : .secondary)
    }
    
    /// Creates the timer card contents from the inputted card.
    private func timerCard(_ card: DMStoredCard) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
            
            if card.type == .timer_custom {
                if card.state?[0] == false {
                    viewModel.setupTimerView(card)
                } else {
                    viewModel.activeTimerView(card)
                }
            } else if card.type == .timer {
                if card.state?[0] == false {
                    // Show grid of preset timers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(0..<card.count, id: \.self) { index in
                            Button(action: {
                                viewModel.selectedTimerIndex = index
                                card.state?[0] = true
                                viewModel.startTimer(card)
                            }) {
                                Circle()
                                    .stroke(lineWidth: 10)
                                    .opacity(0.3)
                                    .foregroundColor(card.primaryColor.color)
                                    .overlay(
                                        Text((card.timer?[index] ?? 0).formatTime())
                                            .font(.title2)
                                            .bold()
                                    )
                                    .frame(height: 100)
                                    .padding()
                            }
                        }
                    }
                } else {
                    // Show active timer
                    viewModel.activeTimerView(card)
                }
            }
        }
        .padding()
    }
}

/// Extends the Int type to format time in hours, minutes and seconds.
extension Int {
    func formatTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%02i:%02i", minutes, seconds)
        } else {
            return String(format: "%02i", seconds)
        }
    }
}

#Preview {
    // An example set of cards
    // Contains 1 of each type of card
    let exampleCards: [DMStoredCard] = [
        DMStoredCard(uuid: UUID(), index: 0, type: .counter, title: "Test Counter", count: 0, modifier: [1, 5], primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 1, type: .toggle, title: "Test Toggle", count: 5, state: Array(repeating: true, count: 5), buttonText: Array(repeating: "", count: 5), symbol: "trophy.fill", primaryColor: .gray, secondaryColor: .yellow),
        DMStoredCard(uuid: UUID(), index: 2, type: .timer, title: "Test Timer", count: 4, state: [false], timer: [5, 15, 60, 240], primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 3, type: .timer_custom, title: "Test Timer (Custom)", count: 1, state: [false], timer: [0], primaryColor: .blue, secondaryColor: .white),
    ]
    
    // An example group
    // Contains an example set of cards
    var exampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Test", groupSymbol: "", cards: exampleCards)
    }
    
    TrackView(selectedGroup: exampleGroup)
}
