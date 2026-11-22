import SwiftUI
import AVFoundation

struct VideoPreview: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var error: String?
    var body: some View {
        Group {
            if let error { ContentUnavailableView("无法播放此视频", systemImage: "play.slash", description: Text(error)) }
            else if let player { NativeVideoPlayer(player: player) }
            else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .task(id: url) {
            player?.pause(); player = nil; error = nil
            do {
                let asset = AVURLAsset(url: url)
                guard try await asset.load(.isPlayable) else { throw CocoaError(.fileReadUnsupportedScheme) }
                try Task.checkCancellation()
                player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            } catch is CancellationError {} catch { self.error = "当前系统无法解码此封装或编码。可使用打开应用选择其他播放器。\n" + error.localizedDescription }
        }
        .onDisappear { player?.pause(); player?.replaceCurrentItem(with: nil) }
    }
}
