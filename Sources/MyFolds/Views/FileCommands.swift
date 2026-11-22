import SwiftUI

struct FileCommands: Commands {
    @Bindable var model: BrowserModel
    var body: some Commands {
        @Bindable var preferences = model.preferences
        CommandGroup(replacing: .appSettings) {
            Button("偏好设置…", action: model.openSettings).keyboardShortcut(",")
        }
        CommandGroup(replacing: .newItem) {
            Button("打开文件夹…", action: model.chooseDirectory).keyboardShortcut("o")
            Button("新建标签页") { if model.fileWindowIsKey { model.addTab() } }.keyboardShortcut("t")
            Button("关闭标签页或窗口", action: model.closeCurrentTabOrWindow).keyboardShortcut("w")
            Button("新建文件夹") { model.requestName(rename: false) }.keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(!model.canEditFiles)
        }
        CommandGroup(replacing: .saveItem) {
            Button("保存", action: model.saveDocument).keyboardShortcut("s")
            Button("另存为…", action: model.saveDocumentCopy).keyboardShortcut("s", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .pasteboard) {
            Button("剪切") { model.copy(cut: true) }.keyboardShortcut("x")
            Button("复制") { model.copy() }.keyboardShortcut("c")
            Button("粘贴", action: model.paste).keyboardShortcut("v")
            Button("复制文件路径", action: model.copyPath).keyboardShortcut("c", modifiers: [.command, .option])
            Divider()
            Button("全选") {
                if !model.sendTextAction(#selector(NSText.selectAll(_:))), model.fileWindowIsKey { model.active.selection = Set(model.active.visible.map(\.url)) }
            }.keyboardShortcut("a")
        }
        CommandGroup(replacing: .undoRedo) {
            Button("撤销", action: model.undo).keyboardShortcut("z")
            Button("重做", action: model.redoText).keyboardShortcut("z", modifiers: [.command, .shift])
        }
        CommandMenu("前往") {
            Button("下一个标签页") { model.cycleTab(1) }.keyboardShortcut(.tab, modifiers: .control)
            Button("上一个标签页") { model.cycleTab(-1) }.keyboardShortcut(.tab, modifiers: [.control, .shift])
            Divider()
            Button("编辑完整路径", action: model.editPath).keyboardShortcut("l")
            Button("上一级", action: model.up).keyboardShortcut(.upArrow)
            Button("打开所选", action: model.openSelected).keyboardShortcut(.downArrow)
            Button("后退") { model.active.back(hidden: model.preferences.showHidden) }.keyboardShortcut("[")
            Button("前进") { model.active.forward(hidden: model.preferences.showHidden) }.keyboardShortcut("]")
            Divider()
            Button("个人文件夹") { model.go(.homeDirectory) }.keyboardShortcut("h", modifiers: [.command, .shift])
        }
        CommandGroup(after: .toolbar) {
            Button("搜索当前文件夹") { if model.fileWindowIsKey { model.searchFocused = true } }.keyboardShortcut("f")
                .disabled(model.activeTextViewer != nil)
            Button("刷新", action: model.refreshAll).keyboardShortcut("r").disabled(model.activeTextViewer != nil)
            Toggle("显示隐藏文件", isOn: $preferences.showHidden).keyboardShortcut(".", modifiers: [.command, .shift])
            Toggle("显示预览区", isOn: $model.inspector).keyboardShortcut("p", modifiers: [.command, .option])
            Button("双栏浏览") { if model.fileWindowIsKey { model.toggleSplit() } }.keyboardShortcut("d", modifiers: [.command, .option])
        }
        CommandMenu("查找") {
            Button("查找…") { model.activeTextViewer?.openSearch(replace: false) }
                .keyboardShortcut(preferences.editor.findShortcut.equivalent, modifiers: preferences.editor.findShortcut.eventModifiers)
                .disabled(model.activeTextViewer == nil)
            Button("替换…") { model.activeTextViewer?.openSearch(replace: true) }
                .keyboardShortcut(preferences.editor.replaceShortcut.equivalent, modifiers: preferences.editor.replaceShortcut.eventModifiers)
                .disabled(model.activeTextViewer == nil)
            Divider()
            Button("下一个匹配") { model.activeTextViewer?.document?.search.navigate() }.keyboardShortcut("g")
                .disabled(model.activeTextViewer?.document?.search.ready != true)
            Button("上一个匹配") { model.activeTextViewer?.document?.search.navigate(backward: true) }.keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(model.activeTextViewer?.document?.search.ready != true)
            Button("查找当前文件全部匹配") { model.activeTextViewer?.document?.search.showsResults = true }
                .disabled(model.activeTextViewer?.document?.search.ready != true)
        }
        #if DEBUG
        CommandMenu("开发") {
            Button("检查磨砂背景", action: model.showMaterialCheck).keyboardShortcut("b", modifiers: [.command, .shift])
            Button("原生材质对照", action: model.showMaterialProbe)
        }
        #endif
        CommandMenu("文件操作") {
            Button("快速预览", action: model.quickLook)
            Button("重命名") { model.requestName(rename: true) }.disabled(model.selected.count != 1 || !model.canEditFiles)
            Button("创建副本", action: model.duplicate).disabled(model.selected.isEmpty || !model.canEditFiles)
            Button("移到废纸篓", action: model.trashSelected).keyboardShortcut(.delete).disabled(model.selected.isEmpty || !model.canEditFiles)
            Button("创建 ZIP…", action: model.createZIP).disabled(model.selected.isEmpty || !model.canEditFiles)
        }
    }
}
