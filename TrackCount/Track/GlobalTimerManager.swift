//
//  GlobalTimerManager.swift
//  TrackCount
//
//  Manages timer persistence across the entire app
//

import SwiftUI
import SwiftData
import Combine

class GlobalTimerManager: ObservableObject {
    static let shared = GlobalTimerManager()
    
    @Published var persistentTimerStates: [UUID: PersistentTimerState] = [:]
    @Published var isInTrackView: Bool = false
    @Published var currentGroupUUID: UUID?
    
    private var backgroundTimer: Timer?
    private var lastUpdateTime: Date = Date()
    
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
        var pauseReason: PauseReason
        var lastSavedAt: Date
        
        // Add CodingKeys to handle the new property
        enum CodingKeys: String, CodingKey {
            case timeRemaining, totalTime, timerIndex, isRunning
            case cardUUID, groupUUID, pausedAt, startedAt, pauseReason, lastSavedAt
        }
        
        init(timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool, cardUUID: UUID, groupUUID: UUID, pausedAt: Date?, startedAt: Date, pauseReason: PauseReason) {
            self.timeRemaining = timeRemaining
            self.totalTime = totalTime
            self.timerIndex = timerIndex
            self.isRunning = isRunning
            self.cardUUID = cardUUID
            self.groupUUID = groupUUID
            self.pausedAt = pausedAt
            self.startedAt = startedAt
            self.pauseReason = pauseReason
            self.lastSavedAt = Date()
        }
        
        // Handle decoding with fallback for missing lastSavedAt
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
            pauseReason = try container.decode(PauseReason.self, forKey: .pauseReason)
            lastSavedAt = try container.decodeIfPresent(Date.self, forKey: .lastSavedAt) ?? Date()
        }
    }
    
    enum PauseReason: String, Codable {
        case userPaused        // User manually paused the timer
        case navigationPaused  // Timer paused due to leaving TrackView
        case notPaused        // Timer is currently running
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
        
        for (uuid, state) in persistentTimerStates {
            guard state.isRunning && state.pausedAt == nil else { continue }
            
            let elapsed = currentTime.timeIntervalSince(lastUpdateTime)
            let newTimeRemaining = max(0, state.timeRemaining - elapsed)
            
            persistentTimerStates[uuid]?.timeRemaining = newTimeRemaining
            
            if newTimeRemaining <= 0 {
                persistentTimerStates[uuid]?.isRunning = false
                // Timer completed - could trigger notification here
            }
        }
        
        lastUpdateTime = currentTime
    }
    
    func saveTimerState(cardUUID: UUID, groupUUID: UUID, timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool) {
        persistentTimerStates[cardUUID] = PersistentTimerState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            timerIndex: timerIndex,
            isRunning: isRunning,
            cardUUID: cardUUID,
            groupUUID: groupUUID,
            pausedAt: nil,
            startedAt: Date(),
            pauseReason: .notPaused
        )
        persistTimerStates() // Persist state after saving
    }
    
    func pauseTimer(cardUUID: UUID) {
        persistentTimerStates[cardUUID]?.pausedAt = Date()
        persistentTimerStates[cardUUID]?.isRunning = false
        persistentTimerStates[cardUUID]?.pauseReason = .userPaused
        persistTimerStates() // Persist state after pausing
    }
    
    func resumeTimer(cardUUID: UUID) {
        persistentTimerStates[cardUUID]?.pausedAt = nil
        persistentTimerStates[cardUUID]?.isRunning = true
        persistentTimerStates[cardUUID]?.pauseReason = .notPaused
        persistTimerStates() // Persist state after resuming
    }
    
    func stopTimer(cardUUID: UUID) {
        persistentTimerStates.removeValue(forKey: cardUUID)
        persistTimerStates() // Persist state after stopping
    }
    
    func pauseAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.isRunning {
                persistentTimerStates[uuid]?.pausedAt = Date()
                persistentTimerStates[uuid]?.isRunning = false
                persistentTimerStates[uuid]?.pauseReason = .navigationPaused
            }
        }
        persistTimerStates() // Persist state after pausing all timers in group
    }
    
    func resumeAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.pausedAt != nil {
                persistentTimerStates[uuid]?.pausedAt = nil
                persistentTimerStates[uuid]?.isRunning = true
                persistentTimerStates[uuid]?.pauseReason = .notPaused
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
        
        if !isInTrackView {
            // Pause all timers when not in TrackView
            if let groupUUID = groupUUID {
                pauseAllTimersInGroup(groupUUID: groupUUID)
            }
        }
        // Remove the automatic resume logic - let TimerViewModel handle selective resuming
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
        // Save states when app goes to background
        persistTimerStates()
    }
    
    @objc private func appDidBecomeActive() {
        // Update timers when app becomes active
        updateTimersAfterAppLaunch()
    }
    
    deinit {
        backgroundTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
