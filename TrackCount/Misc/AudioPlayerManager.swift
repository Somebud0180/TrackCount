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
    
    // Shared AVAudioSession instance
    private let audioSession = AVAudioSession.sharedInstance()
    
    // Dedicated serial queue for non-blocking audio session setup and file operations
    private let audioQueue = DispatchQueue(label: "com.trackcount.AudioPlayerManager", qos: .userInitiated)
    
    @Published private var audioPlayers: [UUID: AVQueuePlayer] = [:]
    @Published private var audioLoopers: [UUID: AVPlayerLooper] = [:]
    private var tempFileURLs: [UUID: URL] = [:]
    
    // Preview player for ringtone picker
    @Published var player: AVAudioPlayer?
    
    private init() {
        // Initial setup of AVAudioSession on manager initialization
        configureAudioSession()
        
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
    
    // MARK: - Audio Session Management
    
    /// Initial configuration for the shared AVAudioSession during manager initialization
    private func configureAudioSession() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
                print("AudioPlayerManager: Audio session category set successfully during init")
            } catch {
                print("AudioPlayerManager: Error setting initial audio session category: \(error)")
            }
        }
    }
    
    /// Activates the shared AVAudioSession asynchronously to prevent UI blocking
    private func activateAudioSession(completion: (() -> Void)? = nil) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
                try self.audioSession.setActive(true)
            } catch {
                print("AudioPlayerManager: Error activating audio session: \(error)")
            }
            completion?()
        }
    }
    
    /// Deactivates the shared AVAudioSession off the main thread if no audio is playing
    private func deactivateAudioSessionIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let hasActiveTimerRingtones = !self.audioPlayers.isEmpty || !self.audioLoopers.isEmpty
            let hasActivePreview = self.player != nil
            
            if !hasActiveTimerRingtones && !hasActivePreview {
                self.audioQueue.async {
                    do {
                        try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                    } catch {
                        print("AudioPlayerManager: Failed to deactivate AVAudioSession: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleStopTimerAudio(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let cardUUID = userInfo["cardUUID"] as? UUID else { return }
        
        stopTimerRingtone(for: cardUUID)
    }
    
    @objc private func handleStopAllTimerAudio(_ notification: Notification) {
        stopAllTimerRingtones()
    }
    
    // MARK: - Timer Ringtone Methods
    
    func playTimerRingtone(for cardUUID: UUID, ringtone: String) {
        // Clean up existing audio for this card first
        stopTimerRingtone(for: cardUUID)
        
        guard let asset = NSDataAsset(name: ringtone) else {
            print("AudioPlayerManager: Data asset not found for: \(ringtone)")
            return
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Perform file I/O off the main thread
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(ringtone)-\(cardUUID.uuidString).wav")
            do {
                try asset.data.write(to: tempURL)
            } catch {
                print("AudioPlayerManager: Error writing temp audio file: \(error)")
                return
            }
            
            // Activate audio session on background queue to avoid blocking UI
            self.activateAudioSession {
                let newPlayerItem = AVPlayerItem(url: tempURL)
                
                DispatchQueue.main.async {
                    let player = AVQueuePlayer()
                    let looper = AVPlayerLooper(player: player, templateItem: newPlayerItem)
                    
                    self.tempFileURLs[cardUUID] = tempURL
                    self.audioPlayers[cardUUID] = player
                    self.audioLoopers[cardUUID] = looper
                    player.play()
                }
            }
        }
    }
    
    func stopTimerRingtone(for cardUUID: UUID) {
        // Clean up existing players on main queue
        if let existingLooper = audioLoopers[cardUUID] {
            existingLooper.disableLooping()
        }
        if let existingPlayer = audioPlayers[cardUUID] {
            existingPlayer.pause()
            existingPlayer.removeAllItems()
        }
        audioPlayers.removeValue(forKey: cardUUID)
        audioLoopers.removeValue(forKey: cardUUID)
        
        // Clean up temporary audio file off main thread and deactivate session if needed
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if let tempURL = self.tempFileURLs[cardUUID] {
                try? FileManager.default.removeItem(at: tempURL)
                self.tempFileURLs.removeValue(forKey: cardUUID)
            }
            self.deactivateAudioSessionIfNeeded()
        }
    }
    
    func stopAllTimerRingtones() {
        // Clean up all audio players and loopers on main queue
        for (_, looper) in audioLoopers {
            looper.disableLooping()
        }
        for (_, player) in audioPlayers {
            player.pause()
            player.removeAllItems()
        }
        audioPlayers.removeAll()
        audioLoopers.removeAll()
        
        // Clean up all temporary audio files off main thread and deactivate session
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            for (_, url) in self.tempFileURLs {
                try? FileManager.default.removeItem(at: url)
            }
            self.tempFileURLs.removeAll()
            self.deactivateAudioSessionIfNeeded()
        }
    }
    
    // MARK: - Ringtone Preview Methods (for RingtonePickerView)
    
    /// Plays a ringtone for preview purposes (used by RingtonePickerView)
    func playAudio(audio: String) {
        // Stop any existing preview audio
        stopAudio()
        
        let ringtoneToPlay = audio.isEmpty ? "Code" : audio // Use default if empty
        
        guard let asset = NSDataAsset(name: ringtoneToPlay) else {
            print("AudioPlayerManager: Data asset not found for preview: \(ringtoneToPlay)")
            return
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Activate session off main thread
            self.activateAudioSession {
                do {
                    let previewPlayer = try AVAudioPlayer(data: asset.data)
                    previewPlayer.numberOfLoops = 0 // Play once for preview
                    
                    DispatchQueue.main.async {
                        self.player = previewPlayer
                        self.player?.play()
                    }
                } catch {
                    print("AudioPlayerManager: Error playing preview audio: \(error)")
                }
            }
        }
    }
    
    /// Stops the preview audio (used by RingtonePickerView)
    func stopAudio() {
        player?.stop()
        player = nil
        
        deactivateAudioSessionIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopAllTimerRingtones()
        stopAudio()
    }
}
