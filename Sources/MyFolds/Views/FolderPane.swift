import SwiftUI

struct FolderPane: View {
    @Environment(\.myfoldsAccentColor) private var accent
    @Bindable var session: FolderSession
    @Bindable var model: BrowserModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.myfoldsReduceMotion) private var reduced
    var isRight: Bool
    private var contentState: String {
        if session.loading { return "loading" }
        if session.error != nil { return "error" }
        if session.archive != nil { return "archive" }
        return session.grid ? "grid" : "list"
    }
    var body: some View {
        VStack(spacing: 0) {
            PathBar(model: model, session: session, isRight: isRight).zIndex(10)
            ZStack {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(!session.resolving)
                    .id(contentState).transition(.opacity)
                    .overlay {
                        if !session.loading && session.archive == nil && session.error == nil && session.visible.isEmpty {
                            ContextMenuArea { _, window in FileMenuFactory.make(model: model, session: session, item: nil, window: window) }
                        }
                    }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped().animation(BrowserMotion.content(reduced), value: contentState)
                .onTapGesture { model.rightActive = isRight; session.pathEditor.cancel() }
            HStack(spacing: 8) {
                if (session.filtering || session.resolving) && !session.loading { ProgressView().controlSize(.mini) }
                Text(session.resolving ? "正在定位路径…" : session.archive.map { "\($0.visible.count) 个项目" } ?? (session.selection.isEmpty ? "\(session.visible.count) 个项目" : "已选 \(session.selection.count) 项"))
                Spacer()
                if model.split && model.rightActive == isRight { Text("当前窗格").foregroundStyle(accent) }
            }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 14).frame(height: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((scheme == .dark ? Color(white: 0.12) : Color(red: 0.945, green: 0.941, blue: 0.929)).opacity(model.preferences.increaseContrast ? 0.6 : 0.14))
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard session.archive == nil && !session.loading && !session.isInTrash else { return false }
            model.receiveDrop(providers, to: session.directory); return true
        }
    }
    @ViewBuilder private var content: some View {
        if let archive = session.archive { ArchiveBrowserView(archive: archive, model: model) }
        else if let error = session.error {
            ContentUnavailableView {
                Label(session.isInTrash ? "无法读取废纸篓" : "无法读取此文件夹", systemImage: "folder.badge.questionmark")
            } description: { Text(session.isInTrash ? "请为 MyFolds 开启完全磁盘访问权限，然后重试。\n" + error : error) } actions: {
                if session.isInTrash { Button("打开磁盘权限", action: model.access.openFullDiskAccess) }
                else { Button("文件访问权限…") { model.openAccessSettings() } }
                Button("选择文件夹…", action: model.chooseDirectory)
                Button("重试") { session.reload(hidden: model.preferences.showHidden) }
            }
        } else if session.loading {
            ProgressView("正在读取文件夹…").controlSize(.small).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if session.visible.isEmpty {
            ContentUnavailableView(session.query.isEmpty ? (session.isInTrash ? "废纸篓为空" : "文件夹为空") : "没有找到文件", systemImage: session.query.isEmpty ? (session.isInTrash ? "trash" : "folder") : "magnifyingglass", description: Text(session.query.isEmpty ? (session.isInTrash ? "移到废纸篓的项目会显示在这里。" : "可以新建文件夹，或将文件粘贴到这里。") : "请尝试其他名称，或清除搜索。"))
        } else if session.grid { FileGridView(session: session, model: model, isRight: isRight) }
        else { NativeFileTable(items: session.visible, selection: $session.selection, model: model, session: session, isRight: isRight) }
    }
}
