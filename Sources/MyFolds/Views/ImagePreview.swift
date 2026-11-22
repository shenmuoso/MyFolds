import SwiftUI

struct ImagePreview: View {
    let url: URL
    let actualSize: Bool
    @State private var image: NSImage?
    @State private var error: String?
    var body: some View {
        Group {
            if let image { ImageCanvas(image: image, actualSize: actualSize).overlay(alignment: .bottomLeading) { Text("\(Int(image.size.width)) × \(Int(image.size.height))").font(.caption).foregroundStyle(.white.opacity(0.7)).padding(10) } }
            else if let error { ContentUnavailableView("无法预览图片", systemImage: "photo", description: Text(error)) }
            else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }.task(id: url) { await load() }
    }
    private func load() async {
        image = nil; error = nil
        do {
            let image = try await ImageDataLoader.load(url)
            try Task.checkCancellation()
            self.image = image
        } catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
