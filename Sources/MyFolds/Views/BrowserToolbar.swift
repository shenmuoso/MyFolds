import SwiftUI

struct BrowserToolbar: View {
    @Bindable var model: BrowserModel
    var body: some View {
        @Bindable var session = model.active
        @Bindable var preferences = model.preferences
        HStack(spacing: 12) {
            if !model.sidebarVisible {
                WindowControls().frame(width: 70, height: 22)
                ToolbarSymbol("显示侧栏", symbol: "sidebar.left") { model.sidebarVisible = true }
            }
            HStack(spacing: 8) {
                ToolbarSymbol("后退", symbol: "chevron.left", width: 27) { model.active.back(hidden: preferences.showHidden) }
                    .disabled(model.active.history.isEmpty && model.active.archive == nil)
                if !model.active.future.isEmpty {
                    ToolbarSymbol("前进", symbol: "chevron.right", width: 27) { model.active.forward(hidden: preferences.showHidden) }
                }
                ToolbarSymbol("上一级", symbol: "chevron.up", width: 27, action: model.up)
            }
            Text(model.active.archive?.url.lastPathComponent ?? model.active.displayName)
                .font(.system(size: 15, weight: .semibold)).lineLimit(1).truncationMode(.middle)
                .frame(minWidth: 36, maxWidth: .infinity, alignment: .leading)
            GlassEffectContainer(spacing: 7) {
                HStack(spacing: 9) {
                    HStack(spacing: 1) {
                        ToolbarSymbol("剪切 ⌘X", symbol: "scissors") { model.copy(cut: true) }.disabled(model.selected.isEmpty || !model.canEditFiles)
                        ToolbarSymbol("复制 ⌘C", symbol: "doc.on.doc") { model.copy() }.disabled(model.selected.isEmpty || model.busy)
                        ToolbarSymbol("粘贴 ⌘V", symbol: "doc.on.clipboard", action: model.paste).disabled(!model.canEditFiles)
                    }.padding(3).glassEffect(.regular, in: .capsule)
                    HStack(spacing: 1) {
                        ToolbarSymbol("列表", symbol: "list.bullet", selected: !session.grid) { session.grid = false }
                        ToolbarSymbol("图标", symbol: "square.grid.2x2", selected: session.grid) { session.grid = true }
                        Menu {
                            Picker("排序依据", selection: $session.sort) {
                                Text("名称").tag("name"); Text("修改日期").tag("modified"); Text("类型").tag("kind"); Text("大小").tag("size")
                            }
                            Toggle("升序", isOn: $session.ascending)
                            Toggle("文件夹优先", isOn: $session.foldersFirst)
                            Toggle("显示隐藏文件", isOn: $preferences.showHidden)
                        } label: { Image(systemName: "arrow.up.arrow.down").frame(width: 31, height: 29) }
                            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("排序").accessibilityLabel("排序")
                    }.padding(3).glassEffect(.regular, in: .capsule)
                    HStack(spacing: 1) {
                        ToolbarSymbol("双栏浏览", symbol: "rectangle.split.2x1", selected: model.split, action: model.toggleSplit)
                        ToolbarSymbol("预览区", symbol: "sidebar.right", selected: model.inspector) { model.inspector.toggle() }.disabled(model.split)
                    }.padding(3).glassEffect(.regular, in: .capsule)
                    Menu {
                        Button("打开文件夹…", action: model.chooseDirectory)
                        Button("新建文件夹") { model.requestName(rename: false) }.disabled(!model.canEditFiles)
                        Button("新建标签页", action: model.addTab)
                        Button("添加当前位置到快速访问", action: model.favorite)
                        Divider()
                        Button("创建 ZIP…", action: model.createZIP).disabled(model.selected.isEmpty || !model.canEditFiles)
                        Button("刷新", action: model.refreshAll)
                        Button("任务历史", systemImage: "clock.arrow.circlepath") { model.showsTasks = true }
                    } label: { Image(systemName: "ellipsis").frame(width: 35, height: 35) }
                        .menuStyle(.borderlessButton).menuIndicator(.hidden).frame(width: 35, height: 35).glassEffect(.regular, in: .circle)
                        .accessibilityLabel("更多操作")
                    SearchField(model: model).frame(width: 145)
                }
            }
        }.font(.system(size: 15)).padding(.leading, 13).padding(.trailing, 18).frame(height: 64)
            .background { WindowDragArea() }
    }
}
