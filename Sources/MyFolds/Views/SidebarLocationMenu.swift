import SwiftUI
import MyFoldsCore

struct SidebarLocationMenu: View {
    @Bindable var model: BrowserModel
    let url: URL
    var isDirectory = true
    var entry: QuickAccessEntry?
    var volume: MountedVolume?
    var body: some View {
        let items = commands
        ForEach(items.indices, id: \.self) { index in
            let item = items[index]
            if let symbol = item.symbol {
                Button(item.title, systemImage: symbol, action: item.action).disabled(!item.enabled)
            } else { Divider() }
        }
    }

    func makeNativeMenu(in window: NSWindow?) -> NSMenu {
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        let menu = NSMenu(); menu.autoenablesItems = false
        for item in commands {
            if let symbol = item.symbol {
                menu.addItem(FileMenuItem(item.title, symbol: symbol, enabled: item.enabled, action: item.action))
            } else { menu.addItem(.separator()) }
        }
        return menu
    }

    private var commands: [SidebarMenuCommand] {
        var items: [SidebarMenuCommand] = [
            .init(title: "打开", symbol: "arrow.up.forward") { model.openSidebar(url, entry: entry, target: .current) },
            .init(title: isDirectory ? "在新标签页打开" : "在新标签页中显示", symbol: "plus.square.on.square") { model.openSidebar(url, entry: entry, target: .newTab) },
            .init(title: isDirectory ? "在另一栏打开" : "在另一栏中显示", symbol: "rectangle.split.2x1") { model.openSidebar(url, entry: entry, target: .otherPane) },
            .separator
        ]
        if let pinned = entry ?? model.quickAccess.entries.first(where: { $0.path == url.standardizedFileURL.path }) {
            items.append(.init(title: "从快速访问移除", symbol: "star.slash") { model.quickAccess.remove(pinned) })
        } else {
            items.append(.init(title: "添加到快速访问", symbol: "star") { model.addQuickAccess([url]) })
        }
        items.append(.init(title: "复制路径", symbol: "doc.on.doc") {
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(url.path, forType: .string)
        })
        if let volume, volume.isDiskImage {
            items.append(.separator)
            items.append(.init(title: "弹出“\(volume.name)”", symbol: "eject", enabled: !model.ejectingVolumes.contains(volume.id)) { model.ejectImage(volume) })
        }
        return items
    }
}
