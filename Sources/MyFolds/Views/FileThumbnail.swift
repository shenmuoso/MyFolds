import SwiftUI
import QuickLookThumbnailing
import MyFoldsCore
import UniformTypeIdentifiers

struct FileThumbnail: View {
    let item: FileItem
    @State private var thumbnail: NSImage?
    var body: some View {
        Image(nsImage: thumbnail ?? NSWorkspace.shared.icon(for: item.isDirectory ? .folder : (UTType(item.typeIdentifier) ?? .data)))
            .resizable().scaledToFit().accessibilityHidden(true)
            .task(id: item.url) { await load() }
    }
    private func load() async {
        guard !item.isDirectory else { return }
        let request = QLThumbnailGenerator.Request(fileAt: item.url, size: CGSize(width: 256, height: 192), scale: 2, representationTypes: .thumbnail)
        do { let result = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request); if !Task.isCancelled { thumbnail = result.nsImage } }
        catch { /* Keep the actual file-type icon when Quick Look has no thumbnail. */ }
    }
}
