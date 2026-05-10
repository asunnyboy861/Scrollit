import SwiftUI
import AVKit

struct GIFPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .onAppear {
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVQueuePlayer(playerItem: playerItem)
            self.looper = AVPlayerLooper(player: newPlayer, templateItem: playerItem)
            self.player = newPlayer
            newPlayer.isMuted = true
            newPlayer.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
            looper = nil
        }
    }
}
