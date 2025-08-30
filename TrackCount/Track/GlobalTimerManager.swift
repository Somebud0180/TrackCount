//
//  GlobalTimerManager.swift
//  TrackCount
//
//  Manages timer persistence across the entire app
//

import SwiftUI
import SwiftData
import Combine
import BackgroundTasks

class GlobalTimerManager: ObservableObject {
    static let shared = GlobalTimerManager()
    
    @Published var persistentTimerStates: [UUID: PersistentTimerState] = [:]
    @Published var isInTrackView: Bool = false
    @Published var currentGroupUUID: UUID?
    
    private var backgroundTimer: Timer?
    private var lastUpdateTime: Date = Date()
    private let notificationManager = NotificationManager.shared
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.trackcount.timerUpdate"
    
    // UserDefaults key for persisting timer states
    private let timerStatesKey = "com.trackcount.timerStates"
    
    struct PersistentTimerState: Codable {
        var timeRemaining: Double
        var totalTime: Double
        var timerIndex: Int
        var isRunning: Bool
        var cardUUID: UUID
        var groupUUID: UUID
        var pausedAt: Date?
        var startedAt: Date
        var lastSavedAt: Date
        var cardTitle: String
        var groupTitle: String
        var ringtone: String
        
        // Remove pauseReason since it's redundant with card state
        enum CodingKeys: String, CodingKey {
            case timeRemaining, totalTime, timerIndex, isRunning
            case cardUUID, groupUUID, pausedAt, startedAt, lastSavedAt
            case cardTitle, groupTitle, ringtone
        }
        
        init(timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool, cardUUID: UUID, groupUUID: UUID, pausedAt: Date?, startedAt: Date, cardTitle: String, groupTitle: String, ringtone: String) {
            self.timeRemaining = timeRemaining
            self.totalTime = totalTime
            self.timerIndex = timerIndex
            self.isRunning = isRunning
            self.cardUUID = cardUUID
            self.groupUUID = groupUUID
            self.pausedAt = pausedAt
            self.startedAt = startedAt
            self.lastSavedAt = Date()
            self.cardTitle = cardTitle
            self.groupTitle = groupTitle
            self.ringtone = ringtone
        }
        
        // Handle decoding with fallback for missing properties
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            timeRemaining = try container.decode(Double.self, forKey: .timeRemaining)
            totalTime = try container.decode(Double.self, forKey: .totalTime)
            timerIndex = try container.decode(Int.self, forKey: .timerIndex)
            isRunning = try container.decode(Bool.self, forKey: .isRunning)
            cardUUID = try container.decode(UUID.self, forKey: .cardUUID)
            groupUUID = try container.decode(UUID.self, forKey: .groupUUID)
            pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
            startedAt = try container.decode(Date.self, forKey: .startedAt)
            lastSavedAt = try container.decodeIfPresent(Date.self, forKey: .lastSavedAt) ?? Date()
            cardTitle = try container.decodeIfPresent(String.self, forKey: .cardTitle) ?? "Timer"
            groupTitle = try container.decodeIfPresent(String.self, forKey: .groupTitle) ?? "Group"
            ringtone = try container.decodeIfPresent(String.self, forKey: .ringtone) ?? "Code"
        }
    }
    
    private init() {
        loadPersistedStates()
        updateTimersAfterAppLaunch()
        startBackgroundTimer()
        
        // Save states when app goes to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Update timers when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func startBackgroundTimer() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { [weak self] _ in
            self?.updateBackgroundTimers()
        }
    }
    
    private func updateBackgroundTimers() {
        let currentTime = Date()
        var completedTimers = 0
        
        for (uuid, state) in persistentTimerStates {
            guard state.isRunning && state.pausedAt == nil else { continue }
            
            let elapsed = currentTime.timeIntervalSince(lastUpdateTime)
            let newTimeRemaining = max(0, state.timeRemaining - elapsed)
            
            persistentTimerStates[uuid]?.timeRemaining = newTimeRemaining
            
            if newTimeRemaining <= 0 && state.timeRemaining > 0 {
                // Timer just completed
                persistentTimerStates[uuid]?.isRunning = false
                completedTimers += 1
                
                // Cancel any scheduled notification since timer has completed
                notificationManager.cancelTimerNotification(for: uuid)
                
                // Always trigger completion notification - GlobalTimerManager handles ALL completions
                // This ensures ringtones play regardless of which view you're in
                notificationManager.handleTimerCompletion(
                    cardUUID: uuid,
                    cardTitle: state.cardTitle,
                    groupTitle: state.groupTitle,
                    ringtone: state.ringtone
                )
            }
        }
        
        lastUpdateTime = currentTime
    }
    
    // Helper method to get card info for notifications
    private func getCardInfo(for cardUUID: UUID) -> (title: String, ringtone: String)? {
        // Since we don't store card info in persistent state, we'll use defaults
        // In a real implementation, you might want to store title and ringtone in PersistentTimerState
        return ("Timer", "Code") // Default values
    }
    
    func saveTimerState(cardUUID: UUID, groupUUID: UUID, timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool, cardTitle: String? = nil, groupTitle: String? = nil, ringtone: String? = nil) {
        persistentTimerStates[cardUUID] = PersistentTimerState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            timerIndex: timerIndex,
            isRunning: isRunning,
            cardUUID: cardUUID,
            groupUUID: groupUUID,
            pausedAt: nil,
            startedAt: Date(),
            cardTitle: cardTitle ?? "Timer",
            groupTitle: groupTitle ?? "Group",
            ringtone: ringtone ?? "Code"
        )
        
        // Schedule notification for when this timer should complete
        if isRunning && timeRemaining > 0 {
            notificationManager.scheduleTimerNotification(
                for: cardUUID,
                cardTitle: cardTitle ?? "Timer",
                groupTitle: groupTitle ?? "Group",
                timeRemaining: timeRemaining,
                ringtone: ringtone ?? "Code"
            )
        }
        
        persistTimerStates() // Persist state after saving
    }
    
    func pauseTimer(cardUUID: UUID) {
        persistentTimerStates[cardUUID]?.pausedAt = Date()
        persistentTimerStates[cardUUID]?.isRunning = false
        
        // Cancel scheduled notification since timer is paused
        notificationManager.cancelTimerNotification(for: cardUUID)
        
        persistTimerStates() // Persist state after pausing
    }
    
    func resumeTimer(cardUUID: UUID, cardTitle: String? = nil, groupTitle: String? = nil, ringtone: String? = nil) {
        guard let state = persistentTimerStates[cardUUID] else { return }
        
        persistentTimerStates[cardUUID]?.pausedAt = nil
        persistentTimerStates[cardUUID]?.isRunning = true
        
        // Reschedule notification with remaining time
        if state.timeRemaining > 0 {
            if let cardTitle = cardTitle, let groupTitle = groupTitle, let ringtone = ringtone {
                notificationManager.scheduleTimerNotification(
                    for: cardUUID,
                    cardTitle: cardTitle,
                    groupTitle: groupTitle,
                    timeRemaining: state.timeRemaining,
                    ringtone: ringtone
                )
            }
        }
        
        persistTimerStates() // Persist state after resuming
    }
    
    func stopTimer(cardUUID: UUID) {
        // Cancel any scheduled notifications
        notificationManager.cancelTimerNotification(for: cardUUID)
        
        persistentTimerStates.removeValue(forKey: cardUUID)
        
        // Clear badge if no more active timers
        if persistentTimerStates.isEmpty {
            notificationManager.clearBadgeCount()
        }
        
        persistTimerStates() // Persist state after stopping
    }
    
    func pauseAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.isRunning {
                persistentTimerStates[uuid]?.pausedAt = Date()
                persistentTimerStates[uuid]?.isRunning = false
            }
        }
        persistTimerStates() // Persist state after pausing all timers in group
    }
    
    func resumeAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.pausedAt != nil {
                persistentTimerStates[uuid]?.pausedAt = nil
                persistentTimerStates[uuid]?.isRunning = true
            }
        }
        persistTimerStates() // Persist state after resuming all timers in group
    }
    
    func getTimerState(cardUUID: UUID) -> PersistentTimerState? {
        return persistentTimerStates[cardUUID]
    }
    
    func setNavigationState(isInTrackView: Bool, groupUUID: UUID?) {
        self.isInTrackView = isInTrackView
        self.currentGroupUUID = groupUUID
    }
    
    private func persistTimerStates() {
        // Convert the timer states to Data and save to UserDefaults
        do {
            let data = try JSONEncoder().encode(persistentTimerStates.map { $0.value })
            UserDefaults.standard.set(data, forKey: timerStatesKey)
        } catch {
            print("Error encoding timer states: \(error)")
        }
    }
    
    private func loadPersistedStates() {
        // Load timer states from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: timerStatesKey) else { return }
        
        do {
            let decodedStates = try JSONDecoder().decode([PersistentTimerState].self, from: data)
            persistentTimerStates = Dictionary(uniqueKeysWithValues: decodedStates.map { ($0.cardUUID, $0) })
        } catch {
            print("Error decoding timer states: \(error)")
        }
    }
    
    private func updateTimersAfterAppLaunch() {
        let currentTime = Date()
        
        for (uuid, state) in persistentTimerStates {
            // Check if the timer was running and not paused at app launch
            if state.isRunning && state.pausedAt == nil {
                let elapsed = currentTime.timeIntervalSince(state.startedAt)
                let newTimeRemaining = max(0, state.timeRemaining - elapsed)
                
                persistentTimerStates[uuid]?.timeRemaining = newTimeRemaining
                
                if newTimeRemaining <= 0 {
                    persistentTimerStates[uuid]?.isRunning = false
                    // Timer completed - could trigger notification here
                }
            }
        }
    }
    
    @objc private func appWillResignActive() {
        // Update all timer states and schedule notifications for background
        scheduleBackgroundNotifications()
        // Save states when app goes to background
        persistTimerStates()
    }
    
    @objc private func appDidBecomeActive() {
        // Update timers when app becomes active
        updateTimersAfterAppLaunch()
        // Cancel scheduled notifications since we're back in foreground
        cancelScheduledNotifications()
        // Clear badge when app becomes active (handled in TrackCountApp now)
    }
    
    /// Schedule notifications for all running timers when app goes to background
    private func scheduleBackgroundNotifications() {
        for (uuid, state) in persistentTimerStates {
            if state.isRunning && state.pausedAt == nil && state.timeRemaining > 0 {
                notificationManager.scheduleTimerNotification(
                    for: uuid,
                    cardTitle: state.cardTitle,
                    groupTitle: state.groupTitle,
                    timeRemaining: state.timeRemaining,
                    ringtone: state.ringtone
                )
            }
        }
    }
    
    /// Cancel all scheduled timer notifications when app becomes active
    private func cancelScheduledNotifications() {
        for uuid in persistentTimerStates.keys {
            notificationManager.cancelTimerNotification(for: uuid)
        }
    }
    
    /// Clears all timer states and notifications - useful for cleanup
    func clearAllTimers() {
        persistentTimerStates.removeAll()
        notificationManager.cancelAllTimerNotifications()
        persistTimerStates()
    }
    
    deinit {
        backgroundTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
