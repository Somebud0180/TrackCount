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
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "\(groupTitle)'s \(cardTitle) timer has finished!"
        content.badge = 1
        
        // Use default notification sound for reliability
        // Custom ringtones will play when app is active
        content.sound = .default
        
        // Add user info for identification
        content.userInfo = [
            "timerCardUUID": cardUUID.uuidString,
            "timerTitle": cardTitle,
            "groupTitle": groupTitle,
            "ringtone": ringtone // Store for potential future use
        ]
        
        // Schedule notification for when timer should complete
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, timeRemaining),
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
                print("Successfully scheduled notification for timer: \(groupTitle)'s \(cardTitle)")
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
    }
    
    private func getSoundURL(for ringtone: String) -> URL? {
        // For iOS notifications, custom sounds must be in specific formats and locations
        // The simplest approach is to use the default sound for notifications
        // and rely on in-app audio for custom ringtones when the app is active
        
        // iOS notification sounds must be:
        // - 30 seconds or less in duration
        // - In Linear PCM or IMA4 (IMA/ADPCM) format
        // - Packaged in a .caf, .aif, or .wav container file
        // - Located in the main bundle or Documents directory
        
        // Try to find the sound file in the bundle first
        if let bundleURL = Bundle.main.url(forResource: ringtone, withExtension: "wav") {
            return bundleURL
        }
        
        // For now, return nil to use default notification sound
        // Custom ringtones will play when the app is active via the regular audio system
        return nil
    }
    
    func handleTimerCompletion(cardUUID: UUID, cardTitle: String, ringtone: String) {
        // If app is in background or user is not in TrackView, show notification
        let isInBackground = UIApplication.shared.applicationState != .active
        let isNotInTrackView = !GlobalTimerManager.shared.isInTrackView
        
        if isInBackground || isNotInTrackView {
            // Schedule immediate notification for timer completion
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete"
            content.body = "\(cardTitle) timer has finished!"
            content.badge = 1
            
            // Set custom sound
            if let soundURL = getSoundURL(for: ringtone) {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
            } else {
                content.sound = .default
            }
            
            content.userInfo = [
                "timerCardUUID": cardUUID.uuidString,
                "timerTitle": cardTitle,
                "completed": true
            ]
            
            // Immediate notification
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
