import AppKit
import MyFoldsCore

extension BrowserModel {
    @discardableResult
    func openSidebar(_ url: URL, entry: QuickAccessEntry? = nil, target: SidebarOpenTarget) -> Task<Void, Never> {
        let original = active, originalRight = split && rightActive
        return Task {
            do {
                let item: FileItem
                if let entry { item = try await quickAccess.resolve(entry) }
                else { item = try await directoryService.item(at: url) }
                switch target {
                case .current: open(item, session: original)
                case .newTab:
                    addTab(isRight: originalRight, directory: item.directoryTarget ?? item.url.deletingLastPathComponent())
                    if !item.isDirectory { active.selection = [item.url] }
                case .otherPane:
                    if !split { toggleSplit() }
                    rightActive = !originalRight
                    let destination = active
                    destination.navigate(item.directoryTarget ?? item.url.deletingLastPathComponent(), hidden: preferences.showHidden)
                    if !item.isDirectory { destination.selection = [item.url] }
                    saveSession()
                }
            } catch { message = "无法打开侧栏位置：\(url.path)\n\(error.localizedDescription)" }
        }
    }

    @discardableResult
    func ejectImage(_ volume: MountedVolume) -> Task<Void, Never>? {
        guard volume.isDiskImage, !ejectingVolumes.contains(volume.id) else { return nil }
        ejectingVolumes.insert(volume.id)
        let previousVolumes = volumes
        return Task {
            defer { ejectingVolumes.remove(volume.id) }
            do {
                try await diskImages.eject(volume)
                await refreshVolumes().value
                let removed = previousVolumes.filter { previous in !volumes.contains { $0.id == previous.id } }
                for tab in tabs + rightTabs where removed.contains(where: { Self.contains(tab.directory, in: $0.url) }) {
                    tab.navigate(volume.imageURL?.deletingLastPathComponent() ?? .homeDirectory, hidden: preferences.showHidden)
                }
                saveSession()
            } catch { message = error.localizedDescription; await refreshVolumes().value }
        }
    }

    private static func contains(_ url: URL, in root: URL) -> Bool {
        let path = url.standardizedFileURL.path, parent = root.standardizedFileURL.path
        return path == parent || path.hasPrefix(parent + "/")
    }
}
