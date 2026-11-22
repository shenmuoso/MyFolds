import SwiftUI
import MyFoldsCore

struct MarkdownPreview: View {
    let text: String
    let url: URL
    @State private var blocks: [MarkdownBlock] = []
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(blocks) { block in blockView(block) }
            }.textSelection(.enabled).font(.system(size: 14)).lineSpacing(5)
                .frame(maxWidth: 740, alignment: .leading).padding(26).frame(maxWidth: .infinity, alignment: .center)
        }.accessibilityLabel("Markdown 预览")
            .task(id: text) {
                do {
                    try await Task.sleep(for: .milliseconds(160))
                    let parsed = try await MarkdownParser.parse(text)
                    try Task.checkCancellation(); blocks = parsed
                } catch { }
            }
    }
    @ViewBuilder private func blockView(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .paragraph: Text(block.text).frame(maxWidth: .infinity, alignment: .leading)
        case .heading(let level): Text(block.text).font(.system(size: level == 1 ? 28 : level == 2 ? 22 : 17, weight: .semibold)).padding(.top, 8)
        case .code(let code):
            ScrollView(.horizontal) { Text(code).font(.system(size: 12, design: .monospaced)).padding(14) }
                .background(Color.primary.opacity(0.045), in: .rect(cornerRadius: 8))
        case .quote: Text(block.text).foregroundStyle(.secondary).padding(.leading, 16)
        case .list(let marker): HStack(alignment: .top, spacing: 10) { Text(marker).foregroundStyle(.secondary); Text(block.text) }
        case .divider: Divider().opacity(0.3)
        case .image(let path, let alt):
            if let imageURL = localImage(path) { ImagePreview(url: imageURL, actualSize: false).frame(height: 240).accessibilityLabel(alt) }
            else { Label(alt.isEmpty ? "远程图片" : alt, systemImage: "photo").foregroundStyle(.secondary) }
        case .table(let rows):
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                ForEach(rows.indices, id: \.self) { row in
                    GridRow { ForEach(rows[row].indices, id: \.self) { column in Text(rows[row][column]).fontWeight(row == 0 ? .semibold : .regular) } }
                }
            }.padding(12).background(Color.primary.opacity(0.04), in: .rect(cornerRadius: 8))
        }
    }
    private func localImage(_ path: String) -> URL? {
        guard !path.contains("://"), !path.hasPrefix("data:") else { return nil }
        return try? DirectoryService.resolve(path, relativeTo: url.deletingLastPathComponent())
    }
}
