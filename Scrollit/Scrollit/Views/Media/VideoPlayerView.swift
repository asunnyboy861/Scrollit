import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    @State private var playbackSpeed: Float = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }

                Spacer()

                HStack {
                    Menu {
                        ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                            Button {
                                playbackSpeed = Float(speed)
                                player?.rate = Float(speed)
                            } label: {
                                if Float(speed) == playbackSpeed {
                                    Label("\(speed)x", systemImage: "checkmark")
                                } else {
                                    Text("\(speed)x")
                                }
                            }
                        }
                    } label: {
                        Text("\(playbackSpeed == 1.0 ? "1x" : String(format: "%.1fx", playbackSpeed))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: playerItem)
            newPlayer.play()
            self.player = newPlayer
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
