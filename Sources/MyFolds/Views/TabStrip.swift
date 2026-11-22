import SwiftUI

struct TabStrip: View {
    @Bindable var model: BrowserModel
    @Environment(\.myfoldsSelectionText) private var selectionText
    @Environment(\.myfoldsSubtleAccent) private var subtleAccent
    let isRight: Bool
    private var tabs: [FolderSession] { isRight ? model.rightTabs : model.tabs }
    private var selectedID: UUID { isRight ? model.selectedRightTabID : model.selectedTabID }
    private var side: String { isRight ? "右侧" : "左侧" }
    @Environment(\.myfoldsReduceMotion) private var reduced
    var body: some View {
        HStack(spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 4) {
                        ForEach(tabs) { tab in
                            let active = selectedID == tab.id
                            HStack(spacing: 4) {
                                Button { model.selectTab(tab.id, isRight: isRight) } label: {
                                    Label(tab.displayName, systemImage: tab.isInTrash ? "trash" : "folder")
                                        .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 10).frame(height: BrowserChrome.controlHeight).contentShape(.rect)
                                }.accessibilityLabel(side + "切换标签：" + tab.directory.path)
                                    .accessibilityIdentifier("tab.\(isRight ? "right" : "left").\(tab.id)")
                                    .accessibilityAddTraits(active ? .isSelected : [])
                                Button { model.closeTab(tab.id, isRight: isRight) } label: {
                                    Image(systemName: "xmark").font(.system(size: 10, weight: .semibold)).frame(width: 25, height: BrowserChrome.controlHeight).contentShape(.rect)
                                }.help("关闭标签 ⌘W").accessibilityLabel(side + "关闭标签：" + tab.displayName)
                            }.frame(width: 190).font(.system(size: 12, weight: active ? .semibold : .regular))
                                .foregroundStyle(active ? selectionText : BrowserChrome.idleText)
                                .id(tab.id).transition(BrowserMotion.insertion(reduced))
                        }
                    }.background(alignment: .leading) {
                        ZStack(alignment: .leading) {
                        HStack(spacing: 4) {
                            ForEach(tabs) { _ in
                                RoundedRectangle(cornerRadius: 8).fill(subtleAccent).frame(width: 190, height: BrowserChrome.controlHeight)
                            }
                        }
                        TabSelectionBackground(position: CGFloat(tabs.firstIndex(where: { $0.id == selectedID }) ?? 0) * 194, reduced: reduced)
                            .animation(reduced ? nil : BrowserMotion.content(false), value: selectedID)
                        }
                    }.padding(.vertical, 4)
                }.scrollIndicators(.hidden)
                    .onAppear { proxy.scrollTo(selectedID) }
                    .onChange(of: selectedID) {
                        withAnimation(reduced ? nil : BrowserMotion.content(false)) { proxy.scrollTo(selectedID) }
                    }
            }
            Button { model.addTab(isRight: isRight) } label: { Image(systemName: "plus").font(.system(size: 13, weight: .medium)).frame(width: BrowserChrome.controlHeight, height: BrowserChrome.controlHeight).contentShape(.rect) }
                .help("新建标签 ⌘T").accessibilityLabel(side + "新建标签页")
        }.buttonStyle(.plain).padding(.horizontal, 10).frame(height: BrowserChrome.controlHeight + 8)
            .animation(reduced ? nil : BrowserMotion.layout(false), value: tabs.map(\.id))
            .animation(BrowserMotion.content(reduced), value: selectedID)
    }
}
