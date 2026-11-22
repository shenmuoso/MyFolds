import SwiftUI

struct BrowserSidebar: View {
    @Bindable var model: BrowserModel
    @Environment(\.myfoldsAccentColor) private var accent
    @Environment(\.myfoldsReduceMotion) private var reduced
    @State private var dropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                WindowControls().frame(width: 70, height: 22)
                Spacer()
                ToolbarSymbol("收起侧栏", symbol: "sidebar.left") { model.sidebarVisible = false }
            }.padding(.horizontal, 17).frame(height: 64).background { WindowDragArea() }
            SidebarView(model: model, dropTargeted: dropTargeted)
        }
        .frame(maxHeight: .infinity)
        .background(Color.white.opacity(0.035))
        .background(accent.opacity(dropTargeted ? 0.10 : 0))
        .contentShape(.rect)
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            guard !providers.isEmpty else { return false }
            model.receiveQuickAccessDrop(providers)
            return true
        }
        .animation(BrowserMotion.feedback(reduced), value: dropTargeted)
    }
}
