//
//  NotificationManager.swift
//  TrackCount
//
//  Manages local notifications for timer completions
//

import UserNotifications
import AVFoundation
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    func scheduleTimerNotification(
        for cardUUID: UUID,
        cardTitle: String,
        groupTitle: String,
        timeRemaining: TimeInterval,
        ringtone: String
    ) {
        // Cancel any existing notification for this timer first
        cancelTimerNotification(for: cardUUID)
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        
        // Only include group name if it's not empty or blank
        if groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            content.body = "\(cardTitle) timer has finished!"
        } else {
            content.body = "\(groupTitle)'s \(cardTitle) timer has finished!"
        }
        
        content.badge = 1
        content.sound = .default
        
        // Add user info for identification
        content.userInfo = [
            "timerCardUUID": cardUUID.uuidString,
            "timerTitle": cardTitle,
            "groupTitle": groupTitle,
            "ringtone": ringtone
        ]
        
        // Schedule notification for when timer should complete
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(0.1, timeRemaining),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer-\(cardUUID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelTimerNotification(for cardUUID: UUID) {
        let identifier = "timer-\(cardUUID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
    }
    
    func cancelAllTimerNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadgeCount()
    }
    
    /// Clears the app badge count
    func clearBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Failed to clear badge count: \(error)")
            }
        }
    }
    
    /// Cancels all pending timer notifications (for when entering TrackView)
    func cancelAllPendingTimerNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationManager: Cancelled all pending timer notifications (entered TrackView)")
    }
    
    /// Reschedules notifications for all active timers in a group (for when leaving TrackView)
    func rescheduleNotificationsForGroup(groupUUID: UUID) {
        // Get all active timers from GlobalTimerManager and reschedule their notifications
        let globalTimerManager = GlobalTimerManager.shared
        
        for (cardUUID, timerState) in globalTimerManager.persistentTimerStates {
            // Only reschedule for timers in this group that are still running
            if timerState.groupUUID == groupUUID &&
                timerState.isRunning &&
                timerState.pausedAt == nil &&
                timerState.timeRemaining > 0 {
                
                scheduleTimerNotification(
                    for: cardUUID,
                    cardTitle: timerState.cardTitle,
                    groupTitle: timerState.groupTitle,
                    timeRemaining: timerState.timeRemaining,
                    ringtone: timerState.ringtone
                )
            }
        }
    }
    
    func handleTimerCompletion(cardUUID: UUID, cardTitle: String, groupTitle: String, ringtone: String) {
        let appState = UIApplication.shared.applicationState
        let isInBackground = appState != .active
        
        // Get the group UUID for this timer from GlobalTimerManager
        let globalTimerManager = GlobalTimerManager.shared
        let timerGroupUUID = globalTimerManager.persistentTimerStates[cardUUID]?.groupUUID
        
        // Check if user is viewing the same group where this timer completed
        let isViewingSameGroup = globalTimerManager.isInTrackView &&
        globalTimerManager.currentGroupUUID == timerGroupUUID
        
        if isInBackground || !isViewingSameGroup {
            // Show notification if app is backgrounded OR if user is not viewing this timer's group
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete"
            
            // Only include group name if it's not empty or blank
            if groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                content.body = "\(cardTitle) timer has finished!"
            } else {
                content.body = "\(groupTitle)'s \(cardTitle) timer has finished!"
            }
            
            content.badge = 1
            content.sound = .default // Always use default sound for notifications
            
            content.userInfo = [
                "timerCardUUID": cardUUID.uuidString,
                "timerTitle": cardTitle,
                "groupTitle": groupTitle,
                "completed": true
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "timer-completed-\(cardUUID.uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing completion notification: \(error)")
                }
            }
        } else {
            // App is active and user is viewing the same group - directly play ringtone via AudioPlayerManager
            AudioPlayerManager.shared.playTimerRingtone(for: cardUUID, ringtone: ringtone)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if this is a timer notification and if user is viewing the same group
        let userInfo = notification.request.content.userInfo
        
        if let cardUUIDString = userInfo["timerCardUUID"] as? String,
           let cardUUID = UUID(uuidString: cardUUIDString) {
            
            // Get the group UUID for this timer from GlobalTimerManager
            let globalTimerManager = GlobalTimerManager.shared
            let timerGroupUUID = globalTimerManager.persistentTimerStates[cardUUID]?.groupUUID
            
            // Check if user is viewing the same group where this timer completed
            let isViewingSameGroup = globalTimerManager.isInTrackView &&
            globalTimerManager.currentGroupUUID == timerGroupUUID
            
            if isViewingSameGroup {
                // User is viewing the same group - suppress the notification
                completionHandler([])
                return
            }
        }
        
        // Show notification for timers from other groups or non-timer notifications
        completionHandler([.banner, .list, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        if let cardUUIDString = userInfo["timerCardUUID"] as? String,
           let cardUUID = UUID(uuidString: cardUUIDString) {
            
            // Navigate to the timer or perform action
            DispatchQueue.main.async {
                // Post notification to inform app about timer completion interaction
                NotificationCenter.default.post(
                    name: NSNotification.Name("TimerNotificationTapped"),
                    object: nil,
                    userInfo: ["cardUUID": cardUUID]
                )
            }
        }
        
        completionHandler()
    }
}

