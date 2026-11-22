import AppKit

final class ContextMenuAreaView: NSView {
    var makeMenu: ((NSPoint, NSWindow?) -> NSMenu)?
    override var isFlipped: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent,
              event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)) else { return nil }
        return super.hitTest(point)
    }
    override func rightMouseDown(with event: NSEvent) {
        guard let menu = makeMenu?(convert(event.locationInWindow, from: nil), window) else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    override func mouseDown(with event: NSEvent) { rightMouseDown(with: event) }
}
