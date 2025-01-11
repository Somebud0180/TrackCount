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
    @State private var timerSubscription: AnyCancellable?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var pausedTimers: Set<Int> = []
    @State private var completedTimers: Set<Int> = []
    
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
            }
        }
        .padding()
        .onChange(of: card.state?[0]) {
            if card.state?[0] == true {
                startTimer(card)
            } else {
                stopTimer()
            }
        }
    }
    
    // Add these helper functions
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
                card.state?[0].toggle()
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
    
    private func activeTimerView(_ card: DMStoredCard) -> some View {
        let timeRemaining = card.timer?[0] ?? 0
        let initialTime = card.timer?[0] ?? 1
        let progress = Float(timeRemaining) / Float(initialTime)
        let isPaused = pausedTimers.contains(card.index)
        
        return VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(card.primaryColor.color)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(card.primaryColor.color)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                Text(timeRemaining.formatTime())
                    .font(.largeTitle)
                    .bold()
            }
            .padding()
            
            HStack {
                Button(action: {
                    stopTimer()
                    card.state?[0].toggle()
                    card.timer?[0] = initialTime
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
                        stopTimer()
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
    
    private func startTimer(_ card: DMStoredCard) {
        stopTimer()
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard var time = card.timer?[0], time > 0 else {
                    timerComplete(card)
                    return
                }
                time -= 1
                card.timer?[0] = time
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func timerComplete(_ card: DMStoredCard) {
        completedTimers.insert(card.index)
        card.state?[0] = false
        card.timer?[0] = 0
        playTimerSound()
    }
    
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
            print("Could not play sound: \(error)")
        }
        
        // Play haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func cleanup() {
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
    // Contains 1 counter card and 1 toggle card
    let exampleCards: [DMStoredCard] = [
        DMStoredCard(uuid: UUID(), index: 0, type: .counter, title: "Test Counter", count: 0, primaryColor: .blue, secondaryColor: .white),
        DMStoredCard(uuid: UUID(), index: 1, type: .toggle, title: "Test Toggle", count: 5, buttonText: ["", "", "", "", ""], state: [true, true, true, true, true], symbol: "trophy.fill", primaryColor: .gray, secondaryColor: .yellow),
        DMStoredCard(uuid: UUID(), index: 2, type: .timer_custom, title: "Test Timer", count: 1, state: [false], timer: [0], primaryColor: .blue, secondaryColor: .white),
    ]
    
    // An example group
    // Contains an example set of cards
    var exampleGroup: DMCardGroup {
        DMCardGroup(uuid: UUID(), index: 0, groupTitle: "Test", groupSymbol: "", cards: exampleCards)
    }
    
    TrackView(selectedGroup: exampleGroup)
}
