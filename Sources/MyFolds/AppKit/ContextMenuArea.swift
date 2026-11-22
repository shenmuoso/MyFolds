import SwiftUI

struct ContextMenuArea: NSViewRepresentable {
    let makeMenu: (NSPoint, NSWindow?) -> NSMenu
    func makeNSView(context: Context) -> ContextMenuAreaView { ContextMenuAreaView() }
    func updateNSView(_ view: ContextMenuAreaView, context: Context) { view.makeMenu = makeMenu }
}
