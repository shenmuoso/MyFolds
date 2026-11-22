import SwiftUI

struct PreviewView: View {
    @Bindable var preview: PreviewModel
    let model: BrowserModel
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Button("上一个", systemImage: "chevron.left") { preview.next(-1) }.disabled(preview.index == 0)
                Button("下一个", systemImage: "chevron.right") { preview.next(1) }.disabled(preview.index == preview.items.count - 1)
                Text(preview.item.name).lineLimit(1)
                Text("\(preview.index + 1) / \(preview.items.count)").foregroundStyle(.secondary)
                Spacer()
                if preview.item.isImage { Button(preview.actualSize ? "适合窗口" : "100%") { preview.actualSize.toggle() } }
                Button("打开应用", systemImage: "arrow.up.forward.app") { model.openExternally(preview.item) }
            }.buttonStyle(.borderless).padding(14).background(.bar)
            if preview.item.isImage { ImagePreview(url: preview.item.url, actualSize: preview.actualSize) }
            else if preview.item.isVideo { VideoPreview(url: preview.item.url) }
            else { QuickLookSurface(url: preview.item.url) }
            HStack {
                Text(ByteCountFormatter.string(fromByteCount: preview.item.size, countStyle: .file))
                Spacer(); Text(preview.item.kind)
            }.font(.caption).foregroundStyle(.secondary).padding(12).background(.bar)
        }
        .background(.black.opacity(0.92)).preferredColorScheme(.dark)
        .onExitCommand(perform: model.closePreview)
        .onKeyPress(.leftArrow) { preview.next(-1); return .handled }
        .onKeyPress(.rightArrow) { preview.next(1); return .handled }
        .onChange(of: preview.index) { model.previewWindow?.title = preview.item.name }
        .frame(minWidth: 600, minHeight: 420)
    }
}
