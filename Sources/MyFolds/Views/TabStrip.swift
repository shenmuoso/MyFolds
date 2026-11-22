import SwiftUI

struct TabStrip: View {
    @Bindable var model: BrowserModel
    @Environment(\.myfoldsSubtleAccent) private var subtleAccent
    let isRight: Bool
    private var tabs: [FolderSession] { isRight ? model.rightTabs : model.tabs }
    private var selectedID: UUID { isRight ? model.selectedRightTabID : model.selectedTabID }
    private var side: String { isRight ? "右侧" : "左侧" }
    @Environment(\.myfoldsReduceMotion) private var reduced
    var body: some View {
        TabStripLayout(contentWidth: CGFloat(tabs.count) * (BrowserChrome.tabWidth + BrowserChrome.tabSpacing) - BrowserChrome.tabSpacing) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: BrowserChrome.tabSpacing) {
                        ForEach(tabs) { tab in
                            BrowserTab(model: model, tab: tab, isRight: isRight, active: selectedID == tab.id)
                                .id(tab.id).transition(BrowserMotion.insertion(reduced))
                        }
                    }.background(alignment: .leading) {
                        ZStack(alignment: .leading) {
                        HStack(spacing: BrowserChrome.tabSpacing) {
                            ForEach(tabs) { _ in
                                RoundedRectangle(cornerRadius: 8).fill(subtleAccent).frame(width: BrowserChrome.tabWidth, height: BrowserChrome.controlHeight)
                            }
                        }
                        TabSelectionBackground(position: CGFloat(tabs.firstIndex(where: { $0.id == selectedID }) ?? 0) * (BrowserChrome.tabWidth + BrowserChrome.tabSpacing), reduced: reduced)
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
                .accessibilityIdentifier("tabs.add.\(isRight ? "right" : "left")")
        }.buttonStyle(.plain).padding(.horizontal, 10).frame(height: BrowserChrome.controlHeight + 8)
            .animation(reduced ? nil : BrowserMotion.layout(false), value: tabs.map(\.id))
            .animation(BrowserMotion.content(reduced), value: selectedID)
    }
}
