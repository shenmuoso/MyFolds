import SwiftUI

struct BrowserTab: View {
    @Bindable var model: BrowserModel
    @Bindable var tab: FolderSession
    let isRight: Bool
    let active: Bool
    @State private var targeted = false
    @Environment(\.myfoldsSelectionText) private var selectionText
    @Environment(\.myfoldsAccentColor) private var accent
    private var side: String { isRight ? "右侧" : "左侧" }
    var body: some View {
        HStack(spacing: 4) {
            Button { model.selectTab(tab.id, isRight: isRight) } label: {
                Label(tab.displayName, systemImage: tab.isInTrash ? "trash" : "folder")
                    .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10).frame(height: BrowserChrome.controlHeight).contentShape(.rect)
            }.accessibilityLabel(side + "切换标签：" + tab.directory.path)
                .accessibilityIdentifier("tab.\(isRight ? "right" : "left").\(tab.id)")
                .accessibilityAddTraits(active ? .isSelected : [])
            Button { model.closeTab(tab.id, isRight: isRight) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                    .frame(width: 25, height: BrowserChrome.controlHeight).contentShape(.rect)
            }.help("关闭标签 ⌘W").accessibilityLabel(side + "关闭标签：" + tab.displayName)
        }.frame(width: BrowserChrome.tabWidth).contentShape(.rect).font(.system(size: 12, weight: active ? .semibold : .regular))
            .foregroundStyle(active ? selectionText : BrowserChrome.idleText)
            .background(targeted && !active ? accent.opacity(0.22) : .clear, in: .rect(cornerRadius: 8))
            .overlay {
                if targeted { RoundedRectangle(cornerRadius: 8).strokeBorder(active ? selectionText.opacity(0.8) : accent, lineWidth: 1.5).allowsHitTesting(false) }
            }
            .contextMenu { TabContextMenu(model: model, tabID: tab.id, isRight: isRight) }
            .onDrop(of: [.fileURL], delegate: FileDropDelegate(model: model, directory: tab.directory,
                enabled: tab.archive == nil && !tab.loading && !tab.isInTrash, targeted: $targeted))
            .task(id: targeted) {
                guard targeted else { return }
                do { try await Task.sleep(for: .milliseconds(550)); try Task.checkCancellation() }
                catch { return }
                model.selectTab(tab.id, isRight: isRight)
            }
    }
}
