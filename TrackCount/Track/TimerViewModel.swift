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
    
    @State private var isCancelButtonPressed: Bool = false
    @State private var isPauseButtonPressed: Bool = false
    @State private var isEndButtonPressed: Bool = false
    
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
        
        // Subscribe to in-app timer completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppTimerCompletion(_:)),
            name: NSNotification.Name("TimerCompletedInApp"),
            object: nil
        )
    }
    
    /// Syncs local timer states with global persistent timers
    private func syncWithGlobalTimers(persistentStates: [UUID: GlobalTimerManager.PersistentTimerState]) {
        for (cardUUID, globalState) in persistentStates {
            // Only sync if we're currently in the TrackView for this group
            if globalTimerManager.isInTrackView && globalTimerManager.currentGroupUUID == globalState.groupUUID {
                // Use global timer as the single source of truth for display values
                displayValues[cardUUID] = globalState.timeRemaining
                selectedTimerIndex[cardUUID] = globalState.timerIndex
                
                // Update local timer state to match global state
                if globalState.pausedAt != nil {
                    timerStates[cardUUID] = .paused
                    pausedTimerValues[cardUUID] = globalState.timeRemaining
                } else if globalState.isRunning && globalState.timeRemaining > 0 {
                    timerStates[cardUUID] = .running
                    // Don't update lastTickTime here to avoid conflicts
                } else if globalState.timeRemaining <= 0 {
                    // Timer completed while app was closed - just update UI state
                    // Don't call handleTimerCompletion to avoid double audio playback
                    timerStates[cardUUID] = .stopped
                    displayValues[cardUUID] = 0
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
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isCancelButtonPressed = true
                        }
                        
                        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                            self.isCancelButtonPressed = false
                            self.stopTimer(card)
                            card.state?[0] = CardState(state: false)
                        }
                    }) {
                        Text("Cancel")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: .secondary, externalPressed: self.isCancelButtonPressed)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isPauseButtonPressed = true
                        }
                        
                        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                            self.isPauseButtonPressed = false
                            
                            if isPaused {
                                self.resumeTimer(card)
                            } else {
                                self.pauseTimer(card)
                            }
                        }
                    }) {
                        Text(isPaused ? "Resume" : "Pause")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: card.primaryColor?.color ?? .blue, externalPressed: self.isPauseButtonPressed)
                } else {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isPauseButtonPressed = true
                        }
                        
                        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                            self.isPauseButtonPressed = false
                            self.timerSound(card, mode: .stop)
                            card.state?[0] = CardState(state: false)
                            NotificationManager.shared.cancelTimerNotification(for: card.uuid)
                        }
                    }) {
                        Text("End")
                            .foregroundStyle(card.secondaryColor?.color ?? .white)
                    }
                    .padding()
                    .adaptiveGlassButton(tintColor: card.primaryColor?.color ?? .blue, externalPressed: self.isPauseButtonPressed)
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
        
        // Get ringtone for notifications
        let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
        
        // Save to global timer manager for persistence with notification info
        globalTimerManager.saveTimerState(
            cardUUID: card.uuid,
            groupUUID: card.group?.uuid ?? UUID(),
            timeRemaining: duration,
            totalTime: duration,
            timerIndex: timerIndex,
            isRunning: true,
            cardTitle: card.title,
            groupTitle: card.group?.groupTitle ?? "Group",
            ringtone: ringtone
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
        
        // Stop any playing audio for this timer immediately
        timerSound(card, mode: .stop)
        
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
        
        // Get ringtone for notifications
        let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
        
        // Resume in global timer manager with notification info
        globalTimerManager.resumeTimer(
            cardUUID: card.uuid,
            cardTitle: card.title,
            groupTitle: card.group?.groupTitle ?? "Group",
            ringtone: ringtone
        )
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
            
            // Always update display values for smooth countdown
            displayValues[uuid] = newValue
            lastTickTime[uuid] = currentTime
            
            // Check for completion BEFORE updating global state
            if newValue <= 0 && currentValue > 0 {
                // Timer just completed - handle it directly when in TrackView
                self.timerStates[uuid] = .stopped
                
                // Get ringtone for completion
                let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
                
                // If in TrackView, directly call NotificationManager since GlobalTimerManager won't detect completion
                if globalTimerManager.isInTrackView {
                    print("TimerViewModel: Timer completed in TrackView, directly calling NotificationManager")
                    NotificationManager.shared.handleTimerCompletion(
                        cardUUID: uuid,
                        cardTitle: card.title,
                        groupTitle: card.group?.groupTitle ?? "Group",
                        ringtone: ringtone
                    )
                }
            }
            
            // Update global timer state so it's synchronized
            let timerIndex = selectedTimerIndex[uuid] ?? 0
            let totalTime = activeTimerValues[uuid] ?? newValue
            globalTimerManager.saveTimerState(
                cardUUID: uuid,
                groupUUID: card.group?.uuid ?? UUID(),
                timeRemaining: newValue,
                totalTime: totalTime,
                timerIndex: timerIndex,
                isRunning: newValue > 0,
                cardTitle: card.title,
                groupTitle: card.group?.groupTitle ?? "Group",
                ringtone: (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
            )
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
                    // Timer is paused - keep it paused until user manually resumes
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
            // Send notification to centralized audio manager instead of local handling
            let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
            NotificationCenter.default.post(
                name: NSNotification.Name("TimerCompletedInApp"),
                object: nil,
                userInfo: [
                    "cardUUID": card.uuid,
                    "ringtone": ringtone
                ]
            )
        }
    }
    
    /// Stops timer audio by sending notification to centralized audio manager
    func timerSound(_ card: DMStoredCard, mode: audioMode) {
        if mode == .stop {
            // Send stop notification to centralized audio manager
            NotificationCenter.default.post(
                name: NSNotification.Name("StopTimerAudio"),
                object: nil,
                userInfo: ["cardUUID": card.uuid]
            )
        } else {
            // Send play notification to centralized audio manager
            let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
            NotificationCenter.default.post(
                name: NSNotification.Name("TimerCompletedInApp"),
                object: nil,
                userInfo: [
                    "cardUUID": card.uuid,
                    "ringtone": ringtone
                ]
            )
        }
    }
    
    /// Pauses all active timers in a specific group
    func pauseAllTimersInGroup(_ group: DMCardGroup) {
        guard let cards = group.cards else { return }
        
        for card in cards {
            // Only pause timers that are currently running
            if timerStates[card.uuid] == .running {
                pauseTimer(card)
            }
        }
    }
    
    /// Resumes all paused timers in a specific group
    func resumeAllTimersInGroup(_ group: DMCardGroup) {
        guard let cards = group.cards else { return }
        
        for card in cards {
            // Only resume timers that are currently paused and have a valid card state
            if timerStates[card.uuid] == .paused && card.state?[0].state == true {
                resumeTimer(card)
            }
        }
    }
    
    /// Cleans up only audio resources without affecting timer persistence
    func cleanupAudioOnly() {
        // Audio is now handled centrally by AudioPlayerManager
        // Just send notifications to stop all audio for cleanup
        NotificationCenter.default.post(
            name: NSNotification.Name("StopAllTimerAudio"),
            object: nil
        )
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
                    // Stop audio for each timer card
                    NotificationCenter.default.post(
                        name: NSNotification.Name("StopTimerAudio"),
                        object: nil,
                        userInfo: ["cardUUID": card.uuid]
                    )
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save context after timer cleanup: \(error)")
        }
    }
    
    deinit {
        sharedTimerCancellable?.cancel()
        globalTimerCancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleInAppTimerCompletion(_ notification: Notification) {
        // This method is no longer needed since AudioPlayerManager handles this directly
        // Keep it for backward compatibility but it won't do anything
    }
}
