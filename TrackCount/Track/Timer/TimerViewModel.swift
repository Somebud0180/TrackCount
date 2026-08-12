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
    
    @Published var isCancelButtonPressed: Bool = false
    @Published var isPauseButtonPressed: Bool = false
    @Published var isEndButtonPressed: Bool = false
    
    private var globalTimerCancellable: AnyCancellable?
    private var storedCards: [UUID: DMStoredCard] = [:]
    
    // Reference to global timer manager
    private let globalTimerManager = GlobalTimerManager.shared
    
    enum audioMode {
        case play
        case stop
    }
    
    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }
    
    init() {
        // Subscribe to global timer updates via objectWillChange
        globalTimerCancellable = globalTimerManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    if let states = self?.globalTimerManager.persistentTimerStates {
                        self?.syncWithGlobalTimers(persistentStates: states)
                    }
                }
            }
        
        // Subscribe to in-app timer completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppTimerCompletion(_:)),
            name: NSNotification.Name("TimerCompletedInApp"),
            object: nil
        )
        
        // Observe card edits to cancel any running timers for that card
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerCardEdited(_:)),
            name: NSNotification.Name("TimerCardEdited"),
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
                if globalState.pausedAt != nil || (!globalState.isRunning && (globalState.pausedRemainingTime ?? 0) > 0) {
                    timerStates[cardUUID] = .paused
                    pausedTimerValues[cardUUID] = globalState.timeRemaining
                } else if globalState.isRunning && globalState.timeRemaining > 0 {
                    timerStates[cardUUID] = .running
                } else if globalState.timeRemaining <= 0 && globalState.totalTime > 0 {
                    timerStates[cardUUID] = .completed
                    displayValues[cardUUID] = 0
                } else {
                    timerStates[cardUUID] = .idle
                }
            }
        }
    }
    
    /// Creates the timer countdown view
    func activeTimerView(_ card: DMStoredCard) -> some View {
        let state = timerStates[card.uuid] ?? .idle
        let persistentState = globalTimerManager.getTimerState(cardUUID: card.uuid)
        
        let totalTime = persistentState?.totalTime ?? 1.0
        let targetEndDate = persistentState?.targetEndDate
        let pausedRemaining = persistentState?.pausedRemainingTime ?? displayValues[card.uuid] ?? totalTime
        let isPaused = state == .paused
        let isCompleted = state == .completed
        
        return VStack {
            ActiveTimerView(
                cardTitle: card.title,
                targetEndDate: targetEndDate,
                totalTime: totalTime,
                isPaused: isPaused,
                pausedRemaining: pausedRemaining,
                primaryColor: card.primaryColor?.color ?? .blue,
                secondaryColor: card.secondaryColor?.color ?? .white,
                isCompleted: isCompleted
            )
            .frame(height: 200)
            .padding()
            
            HStack {
                switch state {
                case .running, .paused:
                    Button(
                        action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                self.isCancelButtonPressed = true
                                self.stopTimer(card)
                            }
                            withAnimation(.easeInOut(duration: 0.1).delay(0.1))
                            { self.isCancelButtonPressed = false }
                        },
                        label: {
                            Text("Cancel").foregroundStyle(
                                card.secondaryColor?.color ?? .white
                            )
                        }
                    )
                    .padding()
                    .adaptiveGlassButton(
                        tintColor: .secondary,
                        externalPressed: self.isCancelButtonPressed
                    )
                    
                    Spacer()
                    
                    Button(
                        action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                self.isPauseButtonPressed = true
                                if isPaused {
                                    self.resumeTimer(card)
                                } else {
                                    self.pauseTimer(card)
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.1).delay(0.1))
                            { self.isPauseButtonPressed = false }
                        },
                        label: {
                            Text(isPaused ? "Resume" : "Pause").foregroundStyle(
                                card.secondaryColor?.color ?? .white
                            )
                        }
                    )
                    .padding()
                    .adaptiveGlassButton(
                        tintColor: card.primaryColor?.color ?? .blue,
                        externalPressed: self.isPauseButtonPressed
                    )
                    
                case .completed:
                    Spacer()
                    
                    Button(
                        action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                self.isPauseButtonPressed = true
                                self.stopTimer(card)
                                NotificationManager.shared
                                    .cancelTimerNotification(for: card.uuid)
                            }
                            withAnimation(.easeInOut(duration: 0.1).delay(0.1))
                            { self.isPauseButtonPressed = false }
                        },
                        label: {
                            Text("End").foregroundStyle(
                                card.secondaryColor?.color ?? .white
                            )
                        }
                    )
                    .padding()
                    .adaptiveGlassButton(
                        tintColor: card.primaryColor?.color ?? .blue,
                        externalPressed: self.isPauseButtonPressed
                    )
                    
                default:
                    EmptyView()
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
            Double(card.timer?[timerIndex].timerValue ?? 1) :
            Double(card.timer?[0].timerValue ?? 1)
        }
        activeTimerValues[card.uuid] = duration
        displayValues[card.uuid] = Double(duration)
        timerStates[card.uuid] = .running
        storedCards[card.uuid] = card
        
        let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
        
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
    }
    
    /// Stops the timer
    func stopTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .idle
        displayValues[card.uuid] = 0
        pausedTimerValues.removeValue(forKey: card.uuid)
        activeTimerValues.removeValue(forKey: card.uuid)
        storedCards.removeValue(forKey: card.uuid)
        
        timerSound(card, mode: .stop)
        globalTimerManager.stopTimer(cardUUID: card.uuid)
    }
    
    /// Stops a timer using only its UUID (when DMStoredCard reference may not exist)
    private func stopTimer(for uuid: UUID) {
        timerStates[uuid] = .idle
        displayValues[uuid] = 0
        pausedTimerValues.removeValue(forKey: uuid)
        activeTimerValues.removeValue(forKey: uuid)
        storedCards.removeValue(forKey: uuid)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("StopTimerAudio"),
            object: nil,
            userInfo: ["cardUUID": uuid]
        )
        globalTimerManager.stopTimer(cardUUID: uuid)
    }
    
    /// Pauses the timer
    func pauseTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .paused
        pausedTimerValues[card.uuid] = displayValues[card.uuid] ?? 0
        globalTimerManager.pauseTimer(cardUUID: card.uuid)
    }
    
    /// Resumes the timer
    func resumeTimer(_ card: DMStoredCard) {
        timerStates[card.uuid] = .running
        let ringtone = (card.timerRingtone?.isEmpty ?? true) ? timerDefaultRingtone : (card.timerRingtone ?? timerDefaultRingtone)
        globalTimerManager.resumeTimer(
            cardUUID: card.uuid,
            cardTitle: card.title,
            groupTitle: card.group?.groupTitle ?? "Group",
            ringtone: ringtone
        )
    }
    
    /// Loads timer state from global manager when entering TrackView
    func loadPersistedTimers(for group: DMCardGroup) {
        guard let cards = group.cards else { return }
        
        for card in cards {
            if let persistentState = globalTimerManager.getTimerState(cardUUID: card.uuid) {
                displayValues[card.uuid] = persistentState.timeRemaining
                selectedTimerIndex[card.uuid] = persistentState.timerIndex
                activeTimerValues[card.uuid] = persistentState.totalTime
                
                if persistentState.pausedAt != nil || (!persistentState.isRunning && (persistentState.pausedRemainingTime ?? 0) > 0) {
                    timerStates[card.uuid] = .paused
                    pausedTimerValues[card.uuid] = persistentState.timeRemaining
                } else if persistentState.isRunning && persistentState.timeRemaining > 0 {
                    timerStates[card.uuid] = .running
                    storedCards[card.uuid] = card
                } else if persistentState.timeRemaining <= 0 && persistentState.totalTime > 0 {
                    timerStates[card.uuid] = .completed
                    displayValues[card.uuid] = 0
                } else {
                    timerStates[card.uuid] = .idle
                }
            }
        }
        
        syncWithGlobalTimers(persistentStates: globalTimerManager.persistentTimerStates)
    }
    
    /// Handles the timer completion
    private func handleTimerCompletion(_ card: DMStoredCard) {
        if isTimerAlertEnabled {
            self.timerStates[card.uuid] = .completed
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
            NotificationCenter.default.post(
                name: NSNotification.Name("StopTimerAudio"),
                object: nil,
                userInfo: ["cardUUID": card.uuid]
            )
        } else {
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
            if timerStates[card.uuid] == .running {
                pauseTimer(card)
            }
        }
    }
    
    /// Resumes all paused timers in a specific group
    func resumeAllTimersInGroup(_ group: DMCardGroup) {
        guard let cards = group.cards else { return }
        
        for card in cards where timerStates[card.uuid] == .paused {
            resumeTimer(card)
        }
    }
    
    /// Cleans up only audio resources without affecting timer persistence
    func cleanupAudioOnly() {
        NotificationCenter.default.post(
            name: NSNotification.Name("StopAllTimerAudio"),
            object: nil
        )
    }
    
    /// Cleans up timer-related variables
    func timerCleanup(for context: ModelContext, group: DMCardGroup) {
        selectedTimerIndex.removeAll()
        pausedTimerValues.removeAll()
        activeTimerValues.removeAll()
        timerStates.removeAll()
        
        if let cards = group.cards {
            for card in cards where card.type == .timer || card.type == .timer_custom {
                NotificationCenter.default.post(
                    name: NSNotification.Name("StopTimerAudio"),
                    object: nil,
                    userInfo: ["cardUUID": card.uuid]
                )
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context after timer cleanup: \(error)")
        }
    }
    
    deinit {
        globalTimerCancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleInAppTimerCompletion(_ notification: Notification) {
        // Backward compatibility
    }
    
    /// Handles a timer card being edited; cancels any running/paused timers for that card
    @objc private func handleTimerCardEdited(_ notification: Notification) {
        guard let uuid = notification.userInfo?["cardUUID"] as? UUID else { return }
        if let card = storedCards[uuid] {
            stopTimer(card)
        } else {
            stopTimer(for: uuid)
        }
    }
}
