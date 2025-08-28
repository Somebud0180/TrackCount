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
    
    struct PersistentTimerState {
        var timeRemaining: Double
        var totalTime: Double
        var timerIndex: Int
        var isRunning: Bool
        var cardUUID: UUID
        var groupUUID: UUID
        var pausedAt: Date?
        var startedAt: Date
    }
    
    private init() {
        startBackgroundTimer()
    }
    
    private func startBackgroundTimer() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
            startedAt: Date()
        )
    }
    
    func pauseTimer(cardUUID: UUID) {
        persistentTimerStates[cardUUID]?.pausedAt = Date()
        persistentTimerStates[cardUUID]?.isRunning = false
    }
    
    func resumeTimer(cardUUID: UUID) {
        persistentTimerStates[cardUUID]?.pausedAt = nil
        persistentTimerStates[cardUUID]?.isRunning = true
    }
    
    func stopTimer(cardUUID: UUID) {
        persistentTimerStates.removeValue(forKey: cardUUID)
    }
    
    func pauseAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.isRunning {
                persistentTimerStates[uuid]?.pausedAt = Date()
                persistentTimerStates[uuid]?.isRunning = false
            }
        }
    }
    
    func resumeAllTimersInGroup(groupUUID: UUID) {
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.pausedAt != nil {
                persistentTimerStates[uuid]?.pausedAt = nil
                persistentTimerStates[uuid]?.isRunning = true
            }
        }
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
        } else {
            // Resume timers when entering TrackView
            if let groupUUID = groupUUID {
                resumeAllTimersInGroup(groupUUID: groupUUID)
            }
        }
    }
    
    deinit {
        backgroundTimer?.invalidate()
    }
}