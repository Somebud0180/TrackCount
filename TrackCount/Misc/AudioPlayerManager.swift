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
        // Initialize audio session immediately to prevent FigApplicationStateMonitor errors
        // This "primes" the audio session so first timer completions work properly
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .duckOthers)
            print("AudioPlayerManager: Audio session category set successfully during init")
        } catch {
            print("AudioPlayerManager: Error setting initial audio session category: \(error)")
        }
        
        // Remove timer completion notification listener since NotificationManager calls us directly
        // Only keep the stop audio notifications for cleanup purposes
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
    
    @objc private func handleStopTimerAudio(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let cardUUID = userInfo["cardUUID"] as? UUID else { return }
        
        stopTimerRingtone(for: cardUUID)
    }
    
    @objc private func handleStopAllTimerAudio(_ notification: Notification) {
        stopAllTimerRingtones()
    }
    
    func playTimerRingtone(for cardUUID: UUID, ringtone: String) {
        print("AudioPlayerManager: Attempting to play ringtone '\(ringtone)' for card \(cardUUID)")
        
        // Always clean up existing audio for this card first
        stopTimerRingtone(for: cardUUID)
        
        guard let asset = NSDataAsset(name: ringtone) else {
            print("AudioPlayerManager: Data asset not found for: \(ringtone)")
            return
        }
        
        // Create new audio player
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(ringtone)-\(cardUUID.uuidString).wav")
        try? asset.data.write(to: tempURL)
        let newPlayerItem = AVPlayerItem(url: tempURL)
        
        // Ensure we're on the main queue and force audio session setup
        DispatchQueue.main.async {
            do {
                // Always set up audio session properly - don't check if it's already active
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: .duckOthers)
                try session.setActive(true)
                
                let player = AVQueuePlayer()
                let looper = AVPlayerLooper(player: player, templateItem: newPlayerItem)
                
                self.audioPlayers[cardUUID] = player
                self.audioLoopers[cardUUID] = looper
                player.play()
                
                print("AudioPlayerManager: Successfully started playing ringtone '\(ringtone)' for card \(cardUUID)")
            } catch {
                print("AudioPlayerManager: Error setting up audio session: \(error)")
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
        
        // Only deactivate audio session if NO audio is playing (including preview)
        if audioPlayers.isEmpty && audioLoopers.isEmpty && player == nil {
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate AVAudioSession: \(error)")
                }
            }
        }
    }
    
    func stopAllTimerRingtones() {
        // Clean up all audio players and loopers efficiently
        for (_, looper) in audioLoopers {
            looper.disableLooping()
        }
        for (_, player) in audioPlayers {
            player.pause()
            player.removeAllItems()
        }
        audioPlayers.removeAll()
        audioLoopers.removeAll()
        
        // Only deactivate if no preview audio is playing
        if player == nil {
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate AVAudioSession: \(error)")
                }
            }
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
