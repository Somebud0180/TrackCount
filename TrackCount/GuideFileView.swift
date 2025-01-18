//
//  GuideFileView.swift
//  TrackCount
//
//  Displays the guide json
//

import SwiftUI
import AVKit

struct GuideFileView: View {
    let guide: Guide
    @Environment(\.colorScheme) var colorScheme
    @State private var playerLooper: AVPlayerLooper?
    @State private var queuePlayer: AVQueuePlayer?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Text(guide.description)
                    .padding()
                
                if let player = queuePlayer {
                    CustomVideoPlayer(player: player)
                        .frame(width: geometry.size.width * 0.9, height: (geometry.size.width * 0.9) * (3.0/2.0))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary, lineWidth: 0.5)
                        }
                        .padding()
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.regularMaterial)
                        .frame(width: geometry.size.width * 0.9, height: (geometry.size.width * 0.9) * (3.0/2.0))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary, lineWidth: 0.5)
                        }
                        .padding()
                }
            }
        }
        .onAppear {
            setupVideo()
        }
        .onChange(of: colorScheme) {
            setupVideo()
        }
    }

    /// Set up the video player
    private func setupVideo() {
        // Stop and clean up existing player
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer = nil
        
        // Create new player with delay to ensure proper cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let videoName = "\(guide.videoFilename)\(colorScheme == .light ? "Light" : "Dark")"
            if let videoPath = Bundle.main.path(forResource: videoName, ofType: "mov") {
                let url = URL(fileURLWithPath: videoPath)
                let playerItem = AVPlayerItem(url: url)
                let player = AVQueuePlayer()
                queuePlayer = player
                playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                player.play()
            }
        }
    }
}

/// Custom video player to remove the controls
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill // Fill the frame while maintaining aspect ratio
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
