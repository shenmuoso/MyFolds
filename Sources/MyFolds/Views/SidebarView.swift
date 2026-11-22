import SwiftUI
import MyFoldsCore

struct SidebarView: View {
    @Bindable var model: BrowserModel
    var dropTargeted = false
    @State private var available: String = ""
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    group("个人收藏") {
                        SidebarLocation(name: "个人文件夹", symbol: "house", url: .homeDirectory, model: model)
                        SidebarLocation(name: "桌面", symbol: "desktopcomputer", url: .desktopDirectory, model: model)
                        SidebarLocation(name: "下载", symbol: "arrow.down.circle", url: .downloadsDirectory, model: model)
                        SidebarLocation(name: "文稿", symbol: "doc", url: .documentsDirectory, model: model)
                        SidebarLocation(name: "图片", symbol: "photo", url: .picturesDirectory, model: model)
                    }
                    QuickAccessSection(model: model, targeted: dropTargeted)
                    group("位置") {
                        ForEach(model.volumes.filter { !$0.isDiskImage }) { volume in
                            SidebarLocation(name: volume.name, symbol: !volume.isLocal ? "network" : volume.isInternal ? "internaldrive" : "externaldrive", url: volume.url, model: model)
                        }
                        SidebarAction("打开文件夹…", symbol: "folder.badge.plus", action: model.chooseDirectory)
                    }
                    if model.volumes.contains(where: \.isDiskImage) {
                        group("磁盘映像") {
                            ForEach(model.volumes.filter(\.isDiskImage)) { volume in
                                SidebarLocation(name: volume.name, symbol: "opticaldisc", url: volume.url, model: model, volume: volume)
                            }
                        }
                    }
                }.padding(.top, 4).padding(.horizontal, 11).padding(.bottom, 16)
            }
            VStack(spacing: 1) {
                SidebarAction("废纸篓", symbol: "trash", selected: model.active.isInTrash, action: model.openTrash)
                    .sidebarContextMenu(SidebarLocationMenu(model: model, url: TrashLocation.root))
                SidebarAction("偏好设置", symbol: "gearshape") { model.openSettings() }
                if model.access.needsDiskAccess { DiskAccessPrompt(action: model.access.openFullDiskAccess).padding(.top, 3) }
                Text(available).font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10).frame(height: 38)
            }.padding(.horizontal, 11)
        }
        .task(id: model.active.directory) {
            if let bytes = await model.directoryService.availableCapacity(at: model.active.directory) {
                available = "可用 " + ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            } else { available = "" }
        }
    }
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.horizontal, 10).padding(.bottom, 5)
            content()
        }
    }
}
