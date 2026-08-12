//
//  GlobalTimerManager.swift
//  TrackCount
//
//  Manages timer persistence across the entire app with absolute target date accuracy
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
    private let notificationManager = NotificationManager.shared
    
    // UserDefaults key for persisting timer states
    private let timerStatesKey = "com.trackcount.timerStates"
    
    struct PersistentTimerState: Codable {
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
        
        /// Absolute target completion date (nil if paused or not running)
        var targetEndDate: Date?
        
        /// Remaining duration saved when paused
        var pausedRemainingTime: Double?
        
        /// Legacy property stored for backwards compatibility when decoding old persisted states
        private var storedTimeRemaining: Double?
        
        enum CodingKeys: String, CodingKey {
            case timeRemaining, totalTime, timerIndex, isRunning
            case cardUUID, groupUUID, pausedAt, startedAt, lastSavedAt
            case cardTitle, groupTitle, ringtone
            case targetEndDate, pausedRemainingTime
        }
        
        /// Dynamically computed remaining time based on absolute target date
        var timeRemaining: Double {
            if isRunning, let targetEndDate = targetEndDate {
                return max(0, targetEndDate.timeIntervalSinceNow)
            } else if let pausedRemainingTime = pausedRemainingTime {
                return max(0, pausedRemainingTime)
            } else if let stored = storedTimeRemaining {
                return max(0, stored)
            } else {
                return 0
            }
        }
        
        init(timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool, cardUUID: UUID, groupUUID: UUID, pausedAt: Date?, startedAt: Date, cardTitle: String, groupTitle: String, ringtone: String, targetEndDate: Date? = nil, pausedRemainingTime: Double? = nil) {
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
            self.targetEndDate = targetEndDate
            self.pausedRemainingTime = pausedRemainingTime
            self.storedTimeRemaining = timeRemaining
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let decodedTimeRemaining = try? container.decode(Double.self, forKey: .timeRemaining)
            totalTime = (try? container.decode(Double.self, forKey: .totalTime)) ?? 0
            timerIndex = (try? container.decode(Int.self, forKey: .timerIndex)) ?? 0
            isRunning = (try? container.decode(Bool.self, forKey: .isRunning)) ?? false
            cardUUID = try container.decode(UUID.self, forKey: .cardUUID)
            groupUUID = try container.decode(UUID.self, forKey: .groupUUID)
            pausedAt = try? container.decodeIfPresent(Date.self, forKey: .pausedAt)
            startedAt = (try? container.decode(Date.self, forKey: .startedAt)) ?? Date()
            lastSavedAt = (try? container.decodeIfPresent(Date.self, forKey: .lastSavedAt)) ?? Date()
            cardTitle = (try? container.decodeIfPresent(String.self, forKey: .cardTitle)) ?? "Timer"
            groupTitle = (try? container.decodeIfPresent(String.self, forKey: .groupTitle)) ?? "Group"
            ringtone = (try? container.decodeIfPresent(String.self, forKey: .ringtone)) ?? "Code"
            
            targetEndDate = try? container.decodeIfPresent(Date.self, forKey: .targetEndDate)
            pausedRemainingTime = try? container.decodeIfPresent(Double.self, forKey: .pausedRemainingTime)
            
            // Migration logic for old format persisted states
            if targetEndDate == nil && isRunning && pausedAt == nil {
                let remaining = decodedTimeRemaining ?? totalTime
                if remaining > 0 {
                    let elapsedSinceLastSave = Date().timeIntervalSince(lastSavedAt)
                    let actualRemaining = max(0, remaining - elapsedSinceLastSave)
                    if actualRemaining > 0 {
                        targetEndDate = Date().addingTimeInterval(actualRemaining)
                    } else {
                        isRunning = false
                        storedTimeRemaining = 0
                    }
                } else {
                    isRunning = false
                    storedTimeRemaining = 0
                }
            } else if pausedAt != nil {
                pausedRemainingTime = pausedRemainingTime ?? decodedTimeRemaining
            } else {
                storedTimeRemaining = decodedTimeRemaining
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(timeRemaining, forKey: .timeRemaining)
            try container.encode(totalTime, forKey: .totalTime)
            try container.encode(timerIndex, forKey: .timerIndex)
            try container.encode(isRunning, forKey: .isRunning)
            try container.encode(cardUUID, forKey: .cardUUID)
            try container.encode(groupUUID, forKey: .groupUUID)
            try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
            try container.encode(startedAt, forKey: .startedAt)
            try container.encode(lastSavedAt, forKey: .lastSavedAt)
            try container.encode(cardTitle, forKey: .cardTitle)
            try container.encode(groupTitle, forKey: .groupTitle)
            try container.encode(ringtone, forKey: .ringtone)
            try container.encodeIfPresent(targetEndDate, forKey: .targetEndDate)
            try container.encodeIfPresent(pausedRemainingTime, forKey: .pausedRemainingTime)
        }
    }
    
    private init() {
        loadPersistedStates()
        updateTimersAfterAppLaunch()
        checkAndManageTimer()
        
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
    
    /// Starts or stops the lightweight background timer based on active running timers
    private func checkAndManageTimer() {
        let hasRunningTimers = persistentTimerStates.values.contains { $0.isRunning && $0.timeRemaining > 0 }
        
        if hasRunningTimers {
            if backgroundTimer == nil {
                backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateBackgroundTimers()
                }
            }
        } else {
            backgroundTimer?.invalidate()
            backgroundTimer = nil
        }
    }

    
    private func updateBackgroundTimers() {
        var completedUUIDs: [UUID] = []
        
        for (uuid, state) in persistentTimerStates {
            guard state.isRunning else { continue }
            
            if state.timeRemaining <= 0 {
                completedUUIDs.append(uuid)
            }
        }
        
        if !completedUUIDs.isEmpty {
            for uuid in completedUUIDs {
                persistentTimerStates[uuid]?.isRunning = false
                persistentTimerStates[uuid]?.targetEndDate = nil
                persistentTimerStates[uuid]?.pausedRemainingTime = 0
                
                guard let state = persistentTimerStates[uuid] else { continue }
                
                // Cancel scheduled notification since timer completed
                notificationManager.cancelTimerNotification(for: uuid)
                
                // Trigger completion notification/audio
                notificationManager.handleTimerCompletion(
                    cardUUID: uuid,
                    cardTitle: state.cardTitle,
                    groupTitle: state.groupTitle,
                    ringtone: state.ringtone
                )
            }
            
            persistTimerStates()
            checkAndManageTimer()
        }
        
        // Notify subscribers (UI views) of current time remaining without disk I/O
        objectWillChange.send()
    }
    
    func saveTimerState(cardUUID: UUID, groupUUID: UUID, timeRemaining: Double, totalTime: Double, timerIndex: Int, isRunning: Bool, cardTitle: String? = nil, groupTitle: String? = nil, ringtone: String? = nil) {
        let now = Date()
        let targetEnd = isRunning ? now.addingTimeInterval(timeRemaining) : nil
        let pausedTime = isRunning ? nil : timeRemaining
        
        persistentTimerStates[cardUUID] = PersistentTimerState(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            timerIndex: timerIndex,
            isRunning: isRunning,
            cardUUID: cardUUID,
            groupUUID: groupUUID,
            pausedAt: isRunning ? nil : now,
            startedAt: now,
            cardTitle: cardTitle ?? "Timer",
            groupTitle: groupTitle ?? "Group",
            ringtone: ringtone ?? "Code",
            targetEndDate: targetEnd,
            pausedRemainingTime: pausedTime
        )
        
        if isRunning && timeRemaining > 0 {
            notificationManager.scheduleTimerNotification(
                for: cardUUID,
                cardTitle: cardTitle ?? "Timer",
                groupTitle: groupTitle ?? "Group",
                timeRemaining: timeRemaining,
                ringtone: ringtone ?? "Code"
            )
        } else {
            notificationManager.cancelTimerNotification(for: cardUUID)
        }
        
        persistTimerStates()
        checkAndManageTimer()
    }
    
    func pauseTimer(cardUUID: UUID) {
        guard var state = persistentTimerStates[cardUUID], state.isRunning else { return }
        let remaining = state.timeRemaining
        let now = Date()
        
        state.pausedAt = now
        state.isRunning = false
        state.targetEndDate = nil
        state.pausedRemainingTime = remaining
        
        persistentTimerStates[cardUUID] = state
        notificationManager.cancelTimerNotification(for: cardUUID)
        
        persistTimerStates()
        checkAndManageTimer()
    }
    
    func resumeTimer(cardUUID: UUID, cardTitle: String? = nil, groupTitle: String? = nil, ringtone: String? = nil) {
        guard var state = persistentTimerStates[cardUUID] else { return }
        let remaining = state.timeRemaining
        guard remaining > 0 else { return }
        
        let now = Date()
        let targetEnd = now.addingTimeInterval(remaining)
        
        if let cardTitle = cardTitle { state.cardTitle = cardTitle }
        if let groupTitle = groupTitle { state.groupTitle = groupTitle }
        if let ringtone = ringtone { state.ringtone = ringtone }
        
        state.pausedAt = nil
        state.isRunning = true
        state.targetEndDate = targetEnd
        state.pausedRemainingTime = nil
        
        persistentTimerStates[cardUUID] = state
        
        notificationManager.scheduleTimerNotification(
            for: cardUUID,
            cardTitle: state.cardTitle,
            groupTitle: state.groupTitle,
            timeRemaining: remaining,
            ringtone: state.ringtone
        )
        
        persistTimerStates()
        checkAndManageTimer()
    }
    
    func stopTimer(cardUUID: UUID) {
        notificationManager.cancelTimerNotification(for: cardUUID)
        persistentTimerStates.removeValue(forKey: cardUUID)
        
        if persistentTimerStates.isEmpty {
            notificationManager.clearBadgeCount()
        }
        
        persistTimerStates()
        checkAndManageTimer()
    }
    
    func pauseAllTimersInGroup(groupUUID: UUID) {
        let now = Date()
        var changed = false
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && state.isRunning {
                let remaining = state.timeRemaining
                persistentTimerStates[uuid]?.pausedAt = now
                persistentTimerStates[uuid]?.isRunning = false
                persistentTimerStates[uuid]?.targetEndDate = nil
                persistentTimerStates[uuid]?.pausedRemainingTime = remaining
                notificationManager.cancelTimerNotification(for: uuid)
                changed = true
            }
        }
        if changed {
            persistTimerStates()
            checkAndManageTimer()
        }
    }
    
    func resumeAllTimersInGroup(groupUUID: UUID) {
        let now = Date()
        var changed = false
        for (uuid, state) in persistentTimerStates {
            if state.groupUUID == groupUUID && !state.isRunning && (state.pausedAt != nil || (state.pausedRemainingTime ?? 0) > 0) {
                let remaining = state.timeRemaining
                if remaining > 0 {
                    persistentTimerStates[uuid]?.pausedAt = nil
                    persistentTimerStates[uuid]?.isRunning = true
                    persistentTimerStates[uuid]?.targetEndDate = now.addingTimeInterval(remaining)
                    persistentTimerStates[uuid]?.pausedRemainingTime = nil
                    notificationManager.scheduleTimerNotification(
                        for: uuid,
                        cardTitle: state.cardTitle,
                        groupTitle: state.groupTitle,
                        timeRemaining: remaining,
                        ringtone: state.ringtone
                    )
                    changed = true
                }
            }
        }
        if changed {
            persistTimerStates()
            checkAndManageTimer()
        }
    }
    
    func getTimerState(cardUUID: UUID) -> PersistentTimerState? {
        return persistentTimerStates[cardUUID]
    }
    
    func setNavigationState(isInTrackView: Bool, groupUUID: UUID?) {
        self.isInTrackView = isInTrackView
        self.currentGroupUUID = groupUUID
    }
    
    private func persistTimerStates() {
        do {
            let data = try JSONEncoder().encode(persistentTimerStates.map { $0.value })
            UserDefaults.standard.set(data, forKey: timerStatesKey)
        } catch {
            print("Error encoding timer states: \(error)")
        }
    }
    
    private func loadPersistedStates() {
        guard let data = UserDefaults.standard.data(forKey: timerStatesKey) else { return }
        
        do {
            let decodedStates = try JSONDecoder().decode([PersistentTimerState].self, from: data)
            persistentTimerStates = Dictionary(uniqueKeysWithValues: decodedStates.map { ($0.cardUUID, $0) })
        } catch {
            print("Error decoding timer states: \(error)")
        }
    }
    
    private func updateTimersAfterAppLaunch() {
        var completedUUIDs: [UUID] = []
        for (uuid, state) in persistentTimerStates {
            if state.isRunning && state.pausedAt == nil {
                if state.timeRemaining <= 0 {
                    persistentTimerStates[uuid]?.isRunning = false
                    persistentTimerStates[uuid]?.targetEndDate = nil
                    persistentTimerStates[uuid]?.pausedRemainingTime = 0
                    completedUUIDs.append(uuid)
                }
            }
        }
        if !completedUUIDs.isEmpty {
            persistTimerStates()
        }
        checkAndManageTimer()
    }
    
    @objc private func appWillResignActive() {
        let now = Date()
        for uuid in persistentTimerStates.keys {
            persistentTimerStates[uuid]?.lastSavedAt = now
        }
        scheduleBackgroundNotifications()
        persistTimerStates()
        // Pause tick timer while backgrounded to save CPU & battery
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }
    
    @objc private func appDidBecomeActive() {
        updateTimersAfterAppLaunch()
        cancelScheduledNotifications()
        checkAndManageTimer()
    }
    
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
    
    private func cancelScheduledNotifications() {
        for uuid in persistentTimerStates.keys {
            notificationManager.cancelTimerNotification(for: uuid)
        }
    }
    
    func clearAllTimers() {
        persistentTimerStates.removeAll()
        notificationManager.cancelAllTimerNotifications()
        persistTimerStates()
        checkAndManageTimer()
    }
    
    deinit {
        backgroundTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
