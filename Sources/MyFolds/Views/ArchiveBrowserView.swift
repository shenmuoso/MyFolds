import SwiftUI
import MyFoldsCore

struct ArchiveBrowserView: View {
    @Bindable var archive: ArchiveState
    let model: BrowserModel
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("压缩包 · 只读", systemImage: "archivebox").foregroundStyle(.secondary)
                Spacer()
                Button(archive.selection.isEmpty ? "全部解压…" : "解压所选…") { model.extractArchive(archive) }.disabled(model.busy || archive.loading || archive.error != nil)
            }.font(.callout).padding(12)
            if archive.loading { ProgressView("读取压缩目录…").frame(maxWidth: .infinity, maxHeight: .infinity) }
            else if let error = archive.error { ContentUnavailableView("无法浏览压缩包", systemImage: "archivebox", description: Text(error)) }
            else {
                Table(archive.visible, selection: $archive.selection) {
                    TableColumn("名称") { entry in
                        HStack {
                            Image(systemName: entry.isDirectory ? "folder" : entry.isLink ? "link" : "doc").foregroundStyle(.secondary)
                            Text(entry.name)
                            if entry.isDirectory { Button("进入", systemImage: "chevron.right") { archive.enter(entry) }.labelStyle(.iconOnly).buttonStyle(.plain) }
                        }
                    }
                    TableColumn("大小") { entry in Text(entry.isDirectory ? "—" : ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file)).foregroundStyle(.secondary) }.width(100)
                }.scrollContentBackground(.hidden)
            }
        }
    }
}
