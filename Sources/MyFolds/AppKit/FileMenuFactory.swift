import AppKit
import MyFoldsCore

@MainActor
enum FileMenuFactory {
    static func make(model: BrowserModel, session: FolderSession, item: FileItem?, window: NSWindow? = nil) -> NSMenu {
        if let window {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
        }
        let isRight = model.rightTabs.contains { $0.id == session.id }
        model.rightActive = isRight
        if let item {
            if !session.selection.contains(item.url) { session.selection = [item.url] }
        } else { session.selection = [] }
        if NSApp.keyWindow?.firstResponder is NSTextView { NSApp.keyWindow?.makeFirstResponder(nil) }
        let menu = NSMenu(); menu.autoenablesItems = false
        let files = session.selected
        let editable = !model.busy && !session.loading && session.archive == nil && !session.isInTrash
        let canPaste = editable && NSPasteboard.general.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        func add(_ title: String, _ symbol: String, _ key: String = "", _ modifiers: NSEvent.ModifierFlags = .command, enabled: Bool = true, action: @escaping () -> Void) {
            menu.addItem(FileMenuItem(title, symbol: symbol, key: key, modifiers: modifiers, enabled: enabled, action: action))
        }
        if files.isEmpty {
            add("新建文件夹…", "folder.badge.plus", "n", [.command, .shift], enabled: editable) { model.requestName(rename: false) }
            add("粘贴", "doc.on.clipboard", "v", enabled: canPaste, action: model.paste)
            add("复制文件夹完整路径", "link", "c", [.command, .option], action: model.copyPath)
            menu.addItem(.separator())
            add("新建标签页", "plus", "t") { model.addTab(isRight: isRight) }
            let directory = session.directory
            add("添加当前位置到快速访问", "star") { model.addQuickAccess([directory]) }
            add("刷新", "arrow.clockwise", "r", action: model.refreshAll)
            return menu
        }
        add("打开", "arrow.up.forward", enabled: files.count == 1, action: model.openSelected)
        if files.count == 1, let file = files.first, let viewer = BuiltInViewer.matching(file) {
            add(viewer.isEditable ? "用 MyFolds 编辑" : "用 MyFolds 查看", "doc.viewfinder") { model.openBuiltIn(file) }
        }
        add("快速预览", "eye", " ", [], enabled: files.contains { !$0.isDirectory && !$0.isArchive }, action: model.quickLook)
        if files.count == 1, let file = files.first, !file.isDirectory {
            let openWith = NSMenu(); openWith.autoenablesItems = false
            let remember = NSMenu(); remember.autoenablesItems = false
            if BuiltInViewer.matching(file) != nil {
                openWith.addItem(FileMenuItem("MyFolds 内置查看器", symbol: "doc.viewfinder") { model.openBuiltIn(file) })
                openWith.addItem(.separator())
                remember.addItem(FileMenuItem("设为 MyFolds 内置查看器", symbol: "doc.viewfinder") {
                    if let ext = OpeningRules.normalizedExtension(file.url.pathExtension) { model.preferences.extensionRules[ext] = Preferences.builtInApplication }
                    else { model.preferences.applicationRules[file.typeIdentifier] = Preferences.builtInApplication }
                })
                remember.addItem(.separator())
            }
            for app in model.applications(for: file) {
                let name = app.deletingPathExtension().lastPathComponent
                let openItem = FileMenuItem(name, symbol: "app") { model.openExternally(file, application: app) }
                let rememberItem = FileMenuItem(name, symbol: "app") { model.preferences.rememberApplication(app, for: file) }
                for entry in [openItem, rememberItem] {
                    entry.image = NSWorkspace.shared.icon(forFile: app.path); entry.image?.size = NSSize(width: 16, height: 16)
                }
                openWith.addItem(openItem); remember.addItem(rememberItem)
            }
            openWith.addItem(FileMenuItem("选择其他应用…", symbol: "folder") { model.otherApplication(file) })
            remember.addItem(FileMenuItem("选择其他应用…", symbol: "folder") { model.otherApplication(file, remember: true) })
            openWith.addItem(.separator())
            let rememberItem = NSMenuItem(title: file.url.pathExtension.isEmpty ? "设为此类型的默认应用" : "设为 .\(file.url.pathExtension.lowercased()) 的默认应用", action: nil, keyEquivalent: "")
            rememberItem.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
            rememberItem.preferredImageVisibility = .visible
            rememberItem.submenu = remember; openWith.addItem(rememberItem)
            openWith.addItem(FileMenuItem("管理默认打开方式…", symbol: "gearshape", action: model.openOpeningSettings))
            let parent = NSMenuItem(title: "打开方式", action: nil, keyEquivalent: "")
            parent.image = NSImage(systemSymbolName: "arrow.up.forward.app", accessibilityDescription: nil)
            parent.preferredImageVisibility = .visible
            parent.submenu = openWith; menu.addItem(parent)
        }
        menu.addItem(.separator())
        add("剪切", "scissors", "x", enabled: editable) { model.copy(cut: true) }
        add("复制", "doc.on.doc", "c", enabled: !model.busy, action: { model.copy() })
        add("粘贴", "doc.on.clipboard", "v", enabled: canPaste, action: model.paste)
        add("复制文件完整路径", "link", "c", [.command, .option], action: model.copyPath)
        add("重命名…", "pencil", enabled: editable && files.count == 1) { model.requestName(rename: true) }
        add("新建文件夹…", "folder.badge.plus", "n", [.command, .shift], enabled: editable) { model.requestName(rename: false) }
        menu.addItem(.separator())
        add("创建 ZIP…", "doc.zipper", enabled: editable, action: model.createZIP)
        add("添加到快速访问", "star") { model.addQuickAccess(files.map(\.url)) }
        add("在 Finder 中显示", "folder") { NSWorkspace.shared.activateFileViewerSelecting(files.map(\.url)) }
        add("移到废纸篓", "trash", "\u{8}", enabled: editable, action: model.trashSelected)
        menu.addItem(.separator())
        add("新建标签页", "plus", "t") { model.addTab(isRight: isRight) }
        return menu
    }
}
