//
//  TimerViewModel.swift
//  TrackCount
//
//  Contains the logic of Timer cards for TrackView
//

import SwiftUI
import AVFoundation
import Combine

class TimerViewModel: ObservableObject {
    // Set variables
    @AppStorage("timerAlertEnabled") var isTimerAlertEnabled: Bool = DefaultSettings.timerAlertEnabled
    @AppStorage("timerDefaultRingtone") var timerDefaultRingtone: String = DefaultSettings.timerDefaultRingtone
    
    @Published var pausedTimers: Set<Int> = []
    @Published var selectedTimerIndex: Int = 0
    @Published var activeTimerValues: [UUID: Int] = [:]
    @Published var pausedTimerValues: [UUID: Int] = [:]
    @Published var timerSubscriptions: [UUID: AnyCancellable] = [:]
    
    @Published var playerItems: [UUID: AVPlayerItem] = [:]
    @Published var audioPlayers: [UUID: AVQueuePlayer] = [:]
    @Published var audioLoopers: [UUID: AVPlayerLooper] = [:]
    @Published var activeRingtones: [String: UUID] = [:]
    @Published var pausedRingtones: [String: [(UUID, AVQueuePlayer, AVPlayerLooper)]] = [:]
    
    enum audioMode {
        case play
        case stop
    }
    
    /// Creates the timer (custom) setup view
    func setupTimerView(_ card: DMStoredCard) -> some View {
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
                self.startTimer(card) // Start timer immediately when button is pressed
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
    func activeTimerView(_ card: DMStoredCard) -> some View {
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
                
                if (activeTimerValues[card.uuid] != nil) {
                    Text(currentValue.formatTime())
                        .font(.title)
                        .bold()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: currentValue)
                } else {
                    Text("Time's Up!")
                        .font(.title)
                        .bold()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: currentValue)
                }
            }
            .frame(height: 200)
            .padding()
            
            HStack {
                if (activeTimerValues[card.uuid] != nil) {
                    Button(action: {
                        self.stopTimer(for: card)
                        card.state?[0] = false
                        if card.type == .timer_custom {
                            card.timer?[0] = initialTime
                        } else {
                            card.timer?[self.selectedTimerIndex] = initialTime
                        }
                        self.pausedTimers.remove(card.index)
                    }) {
                        Text("Cancel")
                            .foregroundStyle(card.secondaryColor.color)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if isPaused {
                            self.pausedTimers.remove(card.index)
                            self.startTimer(card)
                        } else {
                            self.pausedTimers.insert(card.index)
                            self.pausedTimerValues[card.uuid] = self.activeTimerValues[card.uuid]
                            self.stopTimer(for: card)
                        }
                    }) {
                        Text(isPaused ? "Resume" : "Pause")
                            .foregroundStyle(card.secondaryColor.color)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(card.primaryColor.color)
                } else {
                    Spacer()
                    
                    Button(action: {
                        card.state?[0] = false
                        if card.type == .timer_custom {
                            card.timer?[0] = initialTime
                        } else {
                            card.timer?[self.selectedTimerIndex] = initialTime
                        }
                        self.pausedTimers.remove(card.index)
                        self.timerSound(card, mode: .stop)
                    }) {
                        Text("End")
                            .foregroundStyle(card.secondaryColor.color)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(card.primaryColor.color)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Starts the timer countdown
    func startTimer(_ card: DMStoredCard) {
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
            if let currentValue = self.activeTimerValues[card.uuid],
               currentValue > 0 {
                self.activeTimerValues[card.uuid] = currentValue - 1
            } else {
                timer.cancel()
                self.timerComplete(card)
            }
        }
        timer.resume()
        
        timerSubscriptions[card.uuid] = AnyCancellable { timer.cancel() }
    }
    
    /// Stops the timer countdown
    func stopTimer(for card: DMStoredCard) {
        timerSubscriptions[card.uuid]?.cancel()
        timerSubscriptions.removeValue(forKey: card.uuid)
    }
    
    /// Gracefully stops and cleans up the timer and invokes `playTimerSound()`
    func timerComplete(_ card: DMStoredCard) {
        stopTimer(for: card)
        activeTimerValues.removeValue(forKey: card.uuid)
        timerSound(card, mode: .play)
    }
    
    /// Plays the timer complete tone.
    /// Handles simultaneous playback of the same tone by pausing the existing timer tone and playing a new one, with the paused tone being resumed after the existing tone is cancelled.
    func timerSound(_ card: DMStoredCard, mode: audioMode) {
        if isTimerAlertEnabled {
            let ringtoneToPlay = card.timerRingtone ?? timerDefaultRingtone
            
            guard let asset = NSDataAsset(name: ringtoneToPlay) else {
                print("Data asset not found for: \(ringtoneToPlay)")
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ringtoneToPlay).wav")
            try? asset.data.write(to: tempURL)
            let newPlayerItem = AVPlayerItem(url: tempURL)
            playerItems[card.uuid] = newPlayerItem
            
            if mode == .play {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
                try? AVAudioSession.sharedInstance().setActive(true)
                
                let player = AVQueuePlayer()
                let looper = AVPlayerLooper(player: player, templateItem: newPlayerItem)
                
                // If ringtone is already playing, pause it and add to queue
                if let existingCardUUID = activeRingtones[ringtoneToPlay],
                   let existingPlayer = audioPlayers[existingCardUUID],
                   let existingLooper = audioLoopers[existingCardUUID] {
                    existingPlayer.pause()
                    // Add to paused queue with proper ordering
                    if pausedRingtones[ringtoneToPlay] == nil {
                        pausedRingtones[ringtoneToPlay] = []
                    }
                    pausedRingtones[ringtoneToPlay]?.append((existingCardUUID, existingPlayer, existingLooper))
                    
                    // Cleanup existing references
                    audioPlayers.removeValue(forKey: existingCardUUID)
                    audioLoopers.removeValue(forKey: existingCardUUID)
                }
                
                // Play new alert
                activeRingtones[ringtoneToPlay] = card.uuid
                audioPlayers[card.uuid] = player
                audioLoopers[card.uuid] = looper
                player.play()
            } else if mode == .stop {
                if let looper = audioLoopers[card.uuid] {
                    looper.disableLooping()
                }
                if let player = audioPlayers[card.uuid] {
                    player.pause()
                    player.removeAllItems()
                }
                
                // Remove from tracking
                if let ringtone = activeRingtones.first(where: { $0.value == card.uuid })?.key {
                    activeRingtones.removeValue(forKey: ringtone)
                    
                    // Resume first paused ringtone if available
                    if let (pausedUUID, pausedPlayer, pausedLooper) = pausedRingtones[ringtone]?.first {
                        activeRingtones[ringtone] = pausedUUID
                        audioPlayers[pausedUUID] = pausedPlayer
                        audioLoopers[pausedUUID] = pausedLooper
                        pausedPlayer.play()
                        pausedRingtones[ringtone]?.removeFirst()
                    }
                }
                
                audioPlayers.removeValue(forKey: card.uuid)
                audioLoopers.removeValue(forKey: card.uuid)
                playerItems.removeValue(forKey: card.uuid)
            }
        }
    }
    
    /// Cleans up timer-related variables
    func timerCleanup() {
        for subscription in timerSubscriptions.values {
            subscription.cancel()
        }
        timerSubscriptions.removeAll()
        pausedTimerValues.removeAll()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
