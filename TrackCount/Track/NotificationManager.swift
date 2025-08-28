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
        requestNotificationPermission()
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
        content.body = "\(groupTitle)'s \(cardTitle) timer has finished!"
        content.badge = 1
        
        // Try to use custom sound if available, otherwise use default
        if let soundURL = getSoundURL(for: ringtone) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundURL.lastPathComponent))
        } else {
            content.sound = .default
        }
        
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
            } else {
                print("Successfully scheduled notification for timer: \(groupTitle)'s \(cardTitle) in \(timeRemaining) seconds")
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
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func getSoundURL(for ringtone: String) -> URL? {
        // Try to find the sound file in the app bundle
        if let bundleURL = Bundle.main.url(forResource: ringtone, withExtension: "wav") {
            return bundleURL
        }
        
        // iOS notification sounds must be:
        // - 30 seconds or less in duration
        // - In Linear PCM or IMA4 (IMA/ADPCM) format
        // - Packaged in a .caf, .aif, or .wav container file
        // - Located in the main bundle
        
        // For now, return nil to use default notification sound
        // Custom ringtones will play when the app is active via the regular audio system
        return nil
    }
    
    func handleTimerCompletion(cardUUID: UUID, cardTitle: String, groupTitle: String, ringtone: String) {
        let isInBackground = UIApplication.shared.applicationState != .active
        let isNotInTrackView = !GlobalTimerManager.shared.isInTrackView
        
        if isInBackground {
            // App is completely backgrounded - trigger immediate notification
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete"
            content.body = "\(groupTitle)'s \(cardTitle) timer has finished!"
            content.badge = 1
            content.sound = .default // Always use default sound for background notifications
            
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
                    print("Error showing background completion notification: \(error)")
                } else {
                    print("Background timer completion notification sent for \(cardTitle)")
                }
            }
        } else if isNotInTrackView {
            // App is active but user is not in TrackView - play custom ringtone via TimerViewModel
            // Post a notification that the TimerViewModel can handle to play the custom sound
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TimerCompletedInApp"),
                    object: nil,
                    userInfo: [
                        "cardUUID": cardUUID,
                        "cardTitle": cardTitle,
                        "groupTitle": groupTitle,
                        "ringtone": ringtone
                    ]
                )
            }
        }
        // If in TrackView, the TimerViewModel will handle completion directly
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .sound, .badge])
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
