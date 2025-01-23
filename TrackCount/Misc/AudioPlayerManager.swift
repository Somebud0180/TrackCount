//
//  AudioPlayerManager.swift
//  TrackCount
//
//  Manages audio playback
//

import SwiftUI
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @AppStorage("timerDefaultRingtone") var timerDefaultRingtone: String = DefaultSettings.timerDefaultRingtone
    var player: AVAudioPlayer?

    /// Plays the audio with the given name
    func playAudio(audio audioName: String) {
        var ringtonePlaying = audioName
        if audioName.isEmpty {
            ringtonePlaying = timerDefaultRingtone
        }
        
        // Grab audio
        guard let dataAsset = NSDataAsset(name: ringtonePlaying) else {
            print("Data asset not found for: \(ringtonePlaying)")
            return
        }
        
        do {
            // Stop existing audio if any then try playing the audio
            player?.stop()
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: dataAsset.data)
            player?.delegate = self
            player?.play()
        } catch {
            print("Failed to play: \(error.localizedDescription)")
        }
    }

    /// Stops the audio player and deactivates the audio session
    func stopAudio() {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    /// Called when the audio player finishes playing
    /// Unducks the audio session
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Unducking")
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error handling AVAudioSession: \(error)")
        }
    }
}
