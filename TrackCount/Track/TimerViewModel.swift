//
//  TimerViewModel.swift
//  TrackCount
//
//  Contains the logic of Timer cards for TrackView
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

class TimerViewModel: ObservableObject {
    // Set variables
    @AppStorage("timerAlertEnabled") var isTimerAlertEnabled: Bool = DefaultSettings.timerAlertEnabled
    @AppStorage("timerDefaultRingtone") var timerDefaultRingtone: String = DefaultSettings.timerDefaultRingtone
    
    @Published var displayValues: [UUID: Double] = [:]
    @Published var selectedTimerIndex: [UUID : Int] = [:]
    @Published var activeTimerValues: [UUID: Double] = [:]
    @Published var pausedTimerValues: [UUID: Double] = [:]
    @Published var timerStates: [UUID: TimerState] = [:]
    
    @Published var audioPlayers: [UUID: AVQueuePlayer] = [:]
    @Published var audioLoopers: [UUID: AVPlayerLooper] = [:]
    
    private var lastTickTime: [UUID: Date] = [:]
    private var timerStartTime: [UUID: Date] = [:]
    private let timerPublisher = Timer.publish(every: 1/30.0, on: .main, in: .common).autoconnect()
    private var sharedTimerCancellable: AnyCancellable?
    private var globalTimerCancellable: AnyCancellable?
    private var storedCards: [UUID: DMStoredCard] = [:]
    
    // Reference to global timer manager
    private let globalTimerManager = GlobalTimerManager.shared
    
    enum audioMode {
        case play
        case stop
    }
    
    enum TimerState {
        case running
        case paused
        case stopped
    }
    
    init() {
        // Subscribe to global timer updates
        globalTimerCancellable = globalTimerManager.$persistentTimerStates
            .sink { [weak self] persistentStates in
                self?.syncWithGlobalTimers(persistentStates: persistentStates)
            }
    }
    
    /// Syncs local timer states with global persistent timers
    private func syncWithGlobalTimers(persistentStates: [UUID: GlobalTimerManager.PersistentTimerState]) {
        for (cardUUID, globalState) in persistentStates {
            // Only sync if we're currently in the TrackView for this group
            if globalTimerManager.isInTrackView && globalTimerManager.currentGroupUUID == globalState.groupUUID {
                displayValues[cardUUID] = globalState.timeRemaining
                selectedTimerIndex[cardUUID] = globalState.timerIndex
                
                if globalState.pausedAt != nil {
                    timerStates[cardUUID] = .paused
                } else if globalState.isRunning {
                    timerStates[cardUUID] = .running
                } else {
                    timerStates[cardUUID] = .stopped
                }
            }
        }
    }
    
    /// Creates the timer countdown view
    func activeTimerView(_ card: DMStoredCard) -> some View {
        let timerIndex = selectedTimerIndex[card.uuid] ?? 0
        let initialTime = card.type == .timer ?
        card.timer?[timerIndex].timerValue ?? 1 :
        card.timer?[0].timerValue ?? 1
        let displayValue = displayValues[card.uuid] ?? activeTimerValues[card.uuid] ?? 0
        let progress = Float(displayValue) / Float(initialTime)
        let isPaused = self.timerStates[card.uuid] == .paused
        
        return VStack {
            ZStack(alignment: .center) {
                Circle()
                    .stroke(lineWidth: 16)
                    .opacity(0.3)
                    .foregroundColor(card.primaryColor?.color ?? .white)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .foregroundColor(card.primaryColor?.color ?? .blue)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1/30), value: progress)
                
                if (self.timerStates[card.uuid] != .stopped) {
                    if displayValue.formatTime().count == 7 {
                        Text(displayValue.formatTime())
                            .font(.system(.title, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                            .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                            .minimumScaleFactor(0.3)
                            .frame(width: 130, alignment: .leading)
                    } else {
                        Text(displayValue.formatTime())
                            .font(.system(.largeTitle, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                            .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                            .minimumScaleFactor(0.3)
                            .frame(width: 100, alignment: .leading)
                    }
                } else {
                    Text("Time's Up!")
                        .font(.system(.title, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .dynamicTypeSize(DynamicTypeSize.xSmall ... DynamicTypeSize.xxLarge)
                        .minimumScaleFactor(0.3)
                }
            }
            .frame(height: 200)
            .padding()
            
            HStack {
                if (self.timerStates[card.uuid] != .stopped) {
                    Button(action: {
                        self.stopTimer(card)
                        card.state?[0] = CardState(state: false)
                    }) {
                        Text("Cancel")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: .secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if isPaused {
                            self.resumeTimer(card)
                        } else {
                            self.pauseTimer(card)
                        }
                    }) {
                        Text(isPaused ? "Resume" : "Pause")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: card.primaryColor?.color ?? .blue)
                } else {
                    Spacer()
                    
                    Button(action: {
                        card.state?[0] = CardState(state: false)
                        self.timerSound(card, mode: .stop)
                    }) {
                        Text("End")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: card.primaryColor?.color ?? .blue)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Starts the timer
    func startTimer(_ card: DMStoredCard) {
        let timerIndex = selectedTimerIndex[card.uuid] ?? 0
        var duration = 1.0
        if self.timerStates[card.uuid] == .paused {
            duration = pausedTimerValues[card.uuid] ?? 1.0
        } else {
            duration = card.type == .timer ?
            Double(card.timer?[timerIndex].timerValue ?? 1):
            Double(card.timer?[0].timerValue ?? 1)
        }
        
        activeTimerValues[card.uuid] = duration
        displayValues[card.uuid] = Double(duration)
        timerStates[card.uuid] = .running
        timerStartTime[card.uuid] = Date()
        lastTickTime[card.uuid] = Date()
        storedCards[card.uuid] = card
        
        // Save to global timer manager for persistence
        globalTimerManager.saveTimerState(
            cardUUID: card.uuid,
            groupUUID: card.group?.uuid ?? UUID(),
            timeRemaining: duration,
            totalTime: duration,
            timerIndex: timerIndex,
            isRunning: true
        )
        
        // Initialize shared timer if needed
        if sharedTimerCancellable == nil {
            sharedTimerCancellable = timerPublisher.sink { [weak self] _ in
                self?.updateAllTimers()
            }
        }
    }
    
    /// Stops the timer
    func stopTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .stopped
        displayValues[card.uuid] = 0
        pausedTimerValues.removeValue(forKey: card.uuid)
        
        // Remove from global timer manager
        globalTimerManager.stopTimer(cardUUID: card.uuid)
    }
    
    /// Pauses the timer
    func pauseTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .paused
        pausedTimerValues[card.uuid] = displayValues[card.uuid] ?? 0
        
        // Pause in global timer manager
        globalTimerManager.pauseTimer(cardUUID: card.uuid)
    }
    
    /// Resumes the timer
    func resumeTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .running
        lastTickTime[card.uuid] = Date()
        
        // Resume in global timer manager
        globalTimerManager.resumeTimer(cardUUID: card.uuid)
    }
    
    /// Updates timer countdown and syncs with global state
    private func updateAllTimers() {
        let currentTime = Date()
        
        for (uuid, state) in timerStates {
            guard state == .running else { continue }
            guard let lastTick = lastTickTime[uuid] else { continue }
            guard let card = storedCards[uuid] else { continue }
            
            let elapsed = currentTime.timeIntervalSince(lastTick)
            let currentValue = displayValues[uuid] ?? 0
            let newValue = max(0, currentValue - elapsed)
            
            displayValues[uuid] = newValue
            lastTickTime[uuid] = currentTime
            
            // Update global timer state
            let timerIndex = selectedTimerIndex[uuid] ?? 0
            let totalTime = activeTimerValues[uuid] ?? newValue
            globalTimerManager.saveTimerState(
                cardUUID: uuid,
                groupUUID: card.group?.uuid ?? UUID(),
                timeRemaining: newValue,
                totalTime: totalTime,
                timerIndex: timerIndex,
                isRunning: newValue > 0
            )
            
            if newValue <= 0 {
                handleTimerCompletion(card)
            }
        }
    }
    
    /// Loads timer state from global manager when entering TrackView
    func loadPersistedTimers(for group: DMCardGroup) {
        guard let cards = group.cards else { return }
        
        for card in cards {
            if let persistentState = globalTimerManager.getTimerState(cardUUID: card.uuid) {
                displayValues[card.uuid] = persistentState.timeRemaining
                selectedTimerIndex[card.uuid] = persistentState.timerIndex
                activeTimerValues[card.uuid] = persistentState.totalTime
                
                if persistentState.pausedAt != nil {
                    timerStates[card.uuid] = .paused
                    pausedTimerValues[card.uuid] = persistentState.timeRemaining
                } else if persistentState.isRunning && persistentState.timeRemaining > 0 {
                    timerStates[card.uuid] = .running
                    lastTickTime[card.uuid] = Date()
                    card.state?[0] = CardState(state: true)
                    storedCards[card.uuid] = card
                } else {
                    timerStates[card.uuid] = .stopped
                }
            }
        }
        
        // Start the timer publisher if we have running timers
        let hasRunningTimers = timerStates.values.contains(.running)
        if hasRunningTimers && sharedTimerCancellable == nil {
            sharedTimerCancellable = timerPublisher.sink { [weak self] _ in
                self?.updateAllTimers()
            }
        }
    }
    
    /// Handles the timer completion
    private func handleTimerCompletion(_ card: DMStoredCard) {
        if isTimerAlertEnabled {
            self.timerStates[card.uuid] = .stopped
            timerSound(card, mode: .play)
        }
    }
    
    /// Plays the timer complete tone.
    /// Handles simultaneous playback of the same tone by pausing the existing timer tone and playing a new one, with the paused tone being resumed after the existing tone is cancelled.
    func timerSound(_ card: DMStoredCard, mode: audioMode) {
        let ringtoneToPlay = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
        
        guard let asset = NSDataAsset(name: ringtoneToPlay) else {
            print("Data asset not found for: \(ringtoneToPlay)")
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ringtoneToPlay).wav")
        try? asset.data.write(to: tempURL)
        let newPlayerItem = AVPlayerItem(url: tempURL)
        
        if mode == .play {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
                try? AVAudioSession.sharedInstance().setActive(true)
                
                let player = AVQueuePlayer()
                let looper = AVPlayerLooper(player: player, templateItem: newPlayerItem)
                
                self.audioPlayers[card.uuid] = player
                self.audioLoopers[card.uuid] = looper
                player.play()
            }
        } else if mode == .stop {
            if let looper = audioLoopers[card.uuid] {
                looper.disableLooping()
            }
            if let player = audioPlayers[card.uuid] {
                player.pause()
                player.removeAllItems()
            }
            
            audioPlayers.removeValue(forKey: card.uuid)
            audioLoopers.removeValue(forKey: card.uuid)
            
            if audioPlayers.isEmpty && audioLoopers.isEmpty {
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate AVAudioSession: \(error)")
                }
            }
        }
    }
    
    /// Cleans up only audio resources without affecting timer persistence
    func cleanupAudioOnly() {
        // Clean up audio players and loopers
        for (_, player) in audioPlayers {
            player.pause()
            player.removeAllItems()
        }
        audioPlayers.removeAll()
        audioLoopers.removeAll()
        
        // Deactivate audio session if no audio is playing
        if audioPlayers.isEmpty && audioLoopers.isEmpty {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate AVAudioSession: \(error)")
            }
        }
    }
    
    /// Cleans up timer-related variables
    func timerCleanup(for context: ModelContext, group: DMCardGroup) {
        // Clear all timer-related state
        selectedTimerIndex.removeAll()
        pausedTimerValues.removeAll()
        activeTimerValues.removeAll()
        
        if let cards = group.cards {
            for card in cards {
                if card.type == .timer || card.type == .timer_custom {
                    card.state?[0] = CardState(state: false)
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save context after timer cleanup: \(error)")
        }
        
        // Clean up audio
        for (_, player) in audioPlayers {
            player.pause()
            player.removeAllItems()
        }
        audioPlayers.removeAll()
        audioLoopers.removeAll()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate AVAudioSession: \(error)")
        }
    }
    
    deinit {
        sharedTimerCancellable?.cancel()
        globalTimerCancellable?.cancel()
    }
}
