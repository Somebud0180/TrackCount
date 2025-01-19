//
//  GuideFileView.swift
//  TrackCount
//
//  Displays the guide json
//

import SwiftUI
import AVKit

struct GuideFileView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var playerLooper: AVPlayerLooper?
    @State private var queuePlayer: AVQueuePlayer?
    @State private var reloadID = UUID()
    let guide: Guide
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    let safeWidth = max(geometry.size.width, 1)
                    let safeHeight = max(geometry.size.height, 1)
                    let isLandscape = safeWidth > safeHeight
                    
                    if isLandscape {
                        // Landscape layout
                        HStack(alignment: .top, spacing: 16) {
                            Spacer()
                            
                            Text(guide.description)
                                .multilineTextAlignment(.leading)
                                .padding()
                                .frame(maxWidth: geometry.size.width * 0.62, alignment: .leading)
                            
                            videoView(width: safeWidth, height: safeHeight, isLandscape: isLandscape)
                            
                            Spacer()
                        }
                    } else {
                        // Portrait layout
                        VStack(alignment: .center) {
                            Text(guide.description)
                                .multilineTextAlignment(.leading)
                                .padding()
                            
                            videoView(width: safeWidth, height: safeHeight, isLandscape: isLandscape)
                        }
                    }
                }
                .navigationTitle(guide.title)
                .navigationBarTitleDisplayMode(.inline)
            }
            .id(reloadID) // Force view reload to properly play new video on colorScheme change
        }
        .onAppear {
            setupVideo()
        }
        .onChange(of: colorScheme) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                reloadID = UUID()
                setupVideo()
            }
        }
    }
    
    /// Returns the video player view
    private func videoView(width: CGFloat, height: CGFloat, isLandscape: Bool) -> some View {
        // 1:2 aspect ratio => width: height = 1:2
        // Decide an appropriate fraction of screen width for landscape vs. portrait
        let videoWidth = isLandscape ? width * 0.28 : width - 32
        // Clamp to avoid negative or zero sizes
        let safeVideoWidth = max(videoWidth, 1)
        let safeVideoHeight = max(safeVideoWidth * 2, 1)
        
        return Group {
            if let player = queuePlayer {
                CustomVideoPlayer(player: player)
                    .frame(width: safeVideoWidth, height: safeVideoHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary, lineWidth: 0.5)
                    }
                    .padding()
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.regularMaterial)
                    .frame(width: safeVideoWidth, height: safeVideoHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary, lineWidth: 0.5)
                    }
                    .padding()
            }
        }
    }
    
    /// Sets up the video player
    private func setupVideo() {
        // Stop and clean up existing player
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer = nil
        
        // Load correct file name for Dark Mode
        let fileSuffix = colorScheme == .dark ? "Dark" : "Light"
        let videoName = "\(guide.videoFilename)\(fileSuffix)"
        guard let bundleURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("Could not find video: \(videoName).mp4")
            return
        }
        
        let playerItem = AVPlayerItem(url: bundleURL)
        let player = AVQueuePlayer(playerItem: playerItem)
        queuePlayer = player
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        player.play()
    }
    
    /// A custom video player that hides the system controls
    struct CustomVideoPlayer: UIViewControllerRepresentable {
        let player: AVPlayer
        
        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            controller.player = player
            controller.showsPlaybackControls = false
            // Use .resizeAspect to fit within frame or .resizeAspectFill to fill
            controller.videoGravity = .resizeAspect
            return controller
        }
        
        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    }
}
