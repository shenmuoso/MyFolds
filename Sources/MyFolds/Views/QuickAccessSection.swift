import SwiftUI

struct QuickAccessSection: View {
    @Environment(\.myfoldsAccentColor) private var accent
    @Bindable var model: BrowserModel
    var targeted = false
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(targeted ? "松开以添加到快速访问" : "快速访问").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, 10).padding(.bottom, 5)
            if model.quickAccess.entries.isEmpty {
                Text("拖到侧栏任意位置即可添加")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading).padding(.horizontal, 10)
            } else {
                ForEach(model.quickAccess.entries) { entry in
                    SidebarAction(entry.name, symbol: entry.isDirectory ? "folder" : "doc",
                                  selected: entry.isDirectory && model.active.directory.path == entry.path) {
                        model.openQuickAccess(entry)
                    }
                    .help(entry.path)
                    .accessibilityLabel("快速访问：" + entry.name)
                    .accessibilityIdentifier("quickAccess." + entry.id.uuidString)
                    .onDrag { NSItemProvider(object: entry.url as NSURL) }
                    .sidebarContextMenu(SidebarLocationMenu(model: model, url: entry.url, isDirectory: entry.isDirectory, entry: entry))
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .background(accent.opacity(targeted ? 0.20 : 0), in: .rect(cornerRadius: 8))
    }
}
