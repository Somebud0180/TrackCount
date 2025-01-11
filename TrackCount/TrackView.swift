//
//  TrackView.swift
//  TrackCount
//
//  Contains the screen for displaying the trackers
//

import SwiftUI
import SwiftData
import AudioToolbox
import AVFoundation
import Combine

struct TrackView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var audioPlayer: AVAudioPlayer?
    @State private var pausedTimers: Set<Int> = []
    @State private var selectedTimerIndex: Int = 0
    @State private var activeTimerValues: [UUID: Int] = [:]
    @State private var pausedTimerValues: [UUID: Int] = [:]
    @State private var timerSubscriptions: [UUID: AnyCancellable] = [:]
    
    var selectedGroup: DMCardGroup
    
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
                timerCleanup() // Clean up timers on exit
            }
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
            
            // Increment Button
            Button(action: { card.count += 1 }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(card.secondaryColor.color)
                    .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(card.primaryColor.color)
            
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
        Button(action: {
            card.state![id].toggle()
        }) {
            HStack {
                if let buttonText = card.buttonText?[id], !buttonText.isEmpty {
                    Text(buttonText)
                        .font(.body)
                        .minimumScaleFactor(0.3)
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
            .padding(1)
        }
        .buttonStyle(.borderedProminent)
        .tint(card.state![id] ? card.primaryColor.color : .secondary)
    }
    
    /// Creates the timer card contents from the inputted card.
    private func timerCard(_ card: DMStoredCard) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
            
            if card.type == .timer_custom {
                if card.state?[0] == false {
                    setupTimerView(card)
                } else {
                    activeTimerView(card)
                }
            } else if card.type == .timer {
                if card.state?[0] == false {
                    // Show grid of preset timers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(0..<card.count, id: \.self) { index in
                            Button(action: {
                                selectedTimerIndex = index
                                card.state?[0] = true
                                startTimer(card)
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
                    activeTimerView(card)
                }
            }
        }
        .padding()
    }
    
    /// Creates the timer (custom) setup view
    private func setupTimerView(_ card: DMStoredCard) -> some View {
        VStack {
            Text("Set Timer")
                .font(.headline)
            
            TimePickerView(totalSeconds: Binding(
                get: { card.timer?[0] ?? 0 },
                set: { card.timer?[0] = $0 }
            ))
            .frame(height: 150)
            
            Button(action: {
                card.state?[0] = true
                startTimer(card) // Start timer immediately when button is pressed
            }) {
                Text("Start")
                    .foregroundStyle(card.secondaryColor.color)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(card.primaryColor.color)
            .disabled(card.timer?[0] == 0)
        }
    }
    
    /// Creates the timer countdown view
    private func activeTimerView(_ card: DMStoredCard) -> some View {
        let initialTime = card.type == .timer ? card.timer?[selectedTimerIndex] ?? 1 : card.timer?[0] ?? 1
        let currentValue = activeTimerValues[card.uuid] ?? 0
        let progress = Float(currentValue) / Float(initialTime)
        let isPaused = pausedTimers.contains(card.index)
        
        return VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(card.primaryColor.color)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .foregroundColor(card.primaryColor.color)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                Text(currentValue.formatTime())
                    .font(.title)
                    .bold()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: currentValue)
            }
            .frame(height: 200)
            .padding()
            
            HStack {
                Button(action: {
                    stopTimer(for: card)
                    card.state?[0] = false
                    card.timer?[selectedTimerIndex] = initialTime
                    pausedTimers.remove(card.index)
                }) {
                    Text("Cancel")
                        .foregroundStyle(card.secondaryColor.color)
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                
                Spacer()
                
                Button(action: {
                    if isPaused {
                        pausedTimers.remove(card.index)
                        startTimer(card)
                    } else {
                        pausedTimers.insert(card.index)
                        pausedTimerValues[card.uuid] = activeTimerValues[card.uuid]
                        stopTimer(for: card)
                    }
                }) {
                    Text(isPaused ? "Resume" : "Pause")
                        .foregroundStyle(card.secondaryColor.color)
                }
                .buttonStyle(.borderedProminent)
                .tint(card.primaryColor.color)
            }
            .padding(.horizontal)
        }
    }

    /// Starts the timer countdown
    private func startTimer(_ card: DMStoredCard) {
        stopTimer(for: card)
        
        // Initialize temp value or resume from paused value
        if let pausedValue = pausedTimerValues[card.uuid] {
            activeTimerValues[card.uuid] = pausedValue
            pausedTimerValues.removeValue(forKey: card.uuid)
        } else if card.type == .timer_custom {
            activeTimerValues[card.uuid] = card.timer?[0] ?? 0
        } else {
            activeTimerValues[card.uuid] = card.timer?[selectedTimerIndex] ?? 0
        }
        
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            if let currentValue = activeTimerValues[card.uuid],
               currentValue > 0 {
                activeTimerValues[card.uuid] = currentValue - 1
            } else {
                timer.cancel()
                timerComplete(card)
            }
        }
        timer.resume()
        
        timerSubscriptions[card.uuid] = AnyCancellable { timer.cancel() }
    }

    /// Stops the timer countdown
    private func stopTimer(for card: DMStoredCard) {
        timerSubscriptions[card.uuid]?.cancel()
        timerSubscriptions.removeValue(forKey: card.uuid)
    }

    /// Gracefully stops and cleans up the timer and invokes `playTimerSound()`
    private func timerComplete(_ card: DMStoredCard) {
        stopTimer(for: card)
        card.state?[0] = false
        activeTimerValues.removeValue(forKey: card.uuid)
        playTimerSound()
    }
    
    /// Plays the timer complete tone
    private func playTimerSound() {
        // Setup audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Play system sound
        let url = URL(fileURLWithPath: "/Library/Ringtones/Radial-EncoreInfinitum.m4r")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Could not play sound from URL \(url): \(error.localizedDescription)")
        }
    }
    
    /// Cleans up timer-related variables
    private func timerCleanup() {
        for subscription in timerSubscriptions.values {
            subscription.cancel()
        }
        timerSubscriptions.removeAll()
        pausedTimerValues.removeAll()
        try? AVAudioSession.sharedInstance().setActive(false)
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
        DMStoredCard(uuid: UUID(), index: 0, type: .counter, title: "Test Counter", count: 0, primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 1, type: .toggle, title: "Test Toggle", count: 5, buttonText: ["", "", "", "", ""], state: [true, true, true, true, true], symbol: "trophy.fill", primaryColor: .gray, secondaryColor: .yellow),
        DMStoredCard(uuid: UUID(), index: 2, type: .timer, title: "Test Timer", count: 4, state: [false], timer: [60, 120, 144, 240], primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 3, type: .timer_custom, title: "Test Timer (Custom)", count: 1, state: [false], timer: [0], primaryColor: .blue, secondaryColor: .white),
    ]
    
    // An example group
    // Contains an example set of cards
    var exampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Test", groupSymbol: "", cards: exampleCards)
    }
    
    TrackView(selectedGroup: exampleGroup)
}
