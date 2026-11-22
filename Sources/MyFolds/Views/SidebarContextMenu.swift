import SwiftUI

struct SidebarContextMenu: ViewModifier {
    let menu: SidebarLocationMenu
    func body(content: Content) -> some View {
        // Keep SwiftUI's accessibility menu; pointer interaction uses the same
        // commands in AppKit so macOS 27 always displays the menu symbols.
        content.contextMenu { menu }
            .overlay {
                ContextMenuArea { _, window in menu.makeNativeMenu(in: window) }
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    func sidebarContextMenu(_ menu: SidebarLocationMenu) -> some View { modifier(SidebarContextMenu(menu: menu)) }
}
