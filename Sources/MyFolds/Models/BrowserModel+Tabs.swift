import AppKit

extension BrowserModel {
    func closeOtherTabs(_ id: UUID, isRight: Bool = false) {
        let paneTabs = isRight ? rightTabs : tabs
        guard paneTabs.contains(where: { $0.id == id }) else { return }
        closeTabs(Set(paneTabs.filter { $0.id != id }.map(\.id)), isRight: isRight)
    }

    func closeTabsToRight(_ id: UUID, isRight: Bool = false) {
        let paneTabs = isRight ? rightTabs : tabs
        guard let index = paneTabs.firstIndex(where: { $0.id == id }) else { return }
        closeTabs(Set(paneTabs.dropFirst(index + 1).map(\.id)), isRight: isRight)
    }

    func closeAllTabs(isRight: Bool = false) {
        closeTabs(Set((isRight ? rightTabs : tabs).map(\.id)), isRight: isRight)
    }

    func closeTabs(_ ids: Set<UUID>, isRight: Bool) {
        let paneTabs = isRight ? rightTabs : tabs
        let removed = paneTabs.filter { ids.contains($0.id) }
        guard !removed.isEmpty else { return }
        let selectedID = isRight ? selectedRightTabID : selectedTabID
        let selectedIndex = paneTabs.firstIndex { $0.id == selectedID } ?? 0
        removed.forEach { $0.cancelWork() }
        var remaining = paneTabs.filter { !ids.contains($0.id) }
        let closesPane = remaining.isEmpty
        // Keep one location to restore when the main window/right pane reopens.
        if closesPane { remaining = [paneTabs[selectedIndex]] }
        let next = remaining.contains { $0.id == selectedID } ? selectedID : remaining[min(selectedIndex, remaining.count - 1)].id
        if isRight { rightTabs = remaining; selectedRightTabID = next }
        else { tabs = remaining; selectedTabID = next }
        rightActive = isRight
        if closesPane && isRight { split = false; rightActive = false }
        saveSession()
        if closesPane && !isRight {
            NSApp.windows.first { $0.identifier?.rawValue == "MyFolds.main" }?.performClose(nil)
        }
    }
}
