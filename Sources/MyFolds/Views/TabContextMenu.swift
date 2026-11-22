import SwiftUI

struct TabContextMenu: View {
    let model: BrowserModel
    let tabID: UUID
    let isRight: Bool
    private var tabs: [FolderSession] { isRight ? model.rightTabs : model.tabs }

    var body: some View {
        Button("关闭此标签页", systemImage: "xmark") { model.closeTab(tabID, isRight: isRight) }
        Button("关闭其他标签页", systemImage: "rectangle.stack") { model.closeOtherTabs(tabID, isRight: isRight) }
            .disabled(tabs.count < 2)
        Button("关闭右侧标签页", systemImage: "rectangle.trailinghalf.inset.filled") { model.closeTabsToRight(tabID, isRight: isRight) }
            .disabled(tabs.last?.id == tabID)
        Divider()
        Button("关闭所有标签页", systemImage: "xmark.rectangle") { model.closeAllTabs(isRight: isRight) }
    }
}
