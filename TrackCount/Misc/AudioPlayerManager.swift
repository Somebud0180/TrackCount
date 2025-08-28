//
//  AudioPlayerManager.swift
//  TrackCount
//
//  Centralized audio manager for timer ringtones
//

import AVFoundation
import SwiftUI

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    
    @Published private var audioPlayers: [UUID: AVQueuePlayer] = [:]
    @Published private var audioLoopers: [UUID: AVPlayerLooper] = [:]
    
    // Add preview player for ringtone picker
    @Published var player: AVAudioPlayer?
    
    private init() {
        // Listen for timer completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerCompletion(_:)),
            name: NSNotification.Name("TimerCompletedInApp"),
            object: nil
        )
        
        // Listen for timer stop requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStopTimerAudio(_:)),
            name: NSNotification.Name("StopTimerAudio"),
            object: nil
        )
        
        // Listen for stop all timers audio request
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStopAllTimerAudio(_:)),
            name: NSNotification.Name("StopAllTimerAudio"),
            object: nil
        )
    }
    
    @objc private func handleTimerCompletion(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let cardUUID = userInfo["cardUUID"] as? UUID,
              let ringtone = userInfo["ringtone"] as? String else { return }
        
        playTimerRingtone(for: cardUUID, ringtone: ringtone)
    }
    
    @objc private func handleStopTimerAudio(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let cardUUID = userInfo["cardUUID"] as? UUID else { return }
        
        stopTimerRingtone(for: cardUUID)
    }
    
    @objc private func handleStopAllTimerAudio(_ notification: Notification) {
        stopAllTimerRingtones()
    }
    
    func playTimerRingtone(for cardUUID: UUID, ringtone: String) {
        // Always clean up existing audio for this card first
        stopTimerRingtone(for: cardUUID)
        
        guard let asset = NSDataAsset(name: ringtone) else {
            print("Data asset not found for: \(ringtone)")
            return
        }
        
        // Create new audio player
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ringtone)-\(cardUUID.uuidString).wav")
        try? asset.data.write(to: tempURL)
        let newPlayerItem = AVPlayerItem(url: tempURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let player = AVQueuePlayer()
                let looper = AVPlayerLooper(player: player, templateItem: newPlayerItem)
                
                self.audioPlayers[cardUUID] = player
                self.audioLoopers[cardUUID] = looper
                player.play()
                
                print("Playing timer ringtone '\(ringtone)' for card \(cardUUID)")
            } catch {
                print("Error setting up audio session: \(error)")
            }
        }
    }
    
    func stopTimerRingtone(for cardUUID: UUID) {
        // Clean up existing audio for this card
        if let existingLooper = audioLoopers[cardUUID] {
            existingLooper.disableLooping()
        }
        if let existingPlayer = audioPlayers[cardUUID] {
            existingPlayer.pause()
            existingPlayer.removeAllItems()
        }
        audioPlayers.removeValue(forKey: cardUUID)
        audioLoopers.removeValue(forKey: cardUUID)
        
        // Deactivate audio session if no other audio is playing
        if audioPlayers.isEmpty && audioLoopers.isEmpty {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate AVAudioSession: \(error)")
            }
        }
    }
    
    func stopAllTimerRingtones() {
        // Clean up all audio players and loopers
        for (_, player) in audioPlayers {
            player.pause()
            player.removeAllItems()
        }
        for (_, looper) in audioLoopers {
            looper.disableLooping()
        }
        audioPlayers.removeAll()
        audioLoopers.removeAll()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate AVAudioSession: \(error)")
        }
    }
    
    // MARK: - Ringtone Preview Methods (for RingtonePickerView)
    
    /// Plays a ringtone for preview purposes (used by RingtonePickerView)
    func playAudio(audio: String) {
        // Stop any existing preview audio
        stopAudio()
        
        let ringtoneToPlay = audio.isEmpty ? "Code" : audio // Use default if empty
        
        guard let asset = NSDataAsset(name: ringtoneToPlay) else {
            print("Data asset not found for preview: \(ringtoneToPlay)")
            return
        }
        
        do {
            // Set up audio session for preview
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create preview player
            player = try AVAudioPlayer(data: asset.data)
            player?.numberOfLoops = 0 // Play once for preview
            player?.play()
            
            print("Playing preview ringtone: \(ringtoneToPlay)")
        } catch {
            print("Error playing preview audio: \(error)")
        }
    }
    
    /// Stops the preview audio (used by RingtonePickerView)
    func stopAudio() {
        player?.stop()
        player = nil
        
        // Only deactivate audio session if no timer ringtones are playing
        if audioPlayers.isEmpty && audioLoopers.isEmpty {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate AVAudioSession: \(error)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopAllTimerRingtones()
        stopAudio()
    }
}
