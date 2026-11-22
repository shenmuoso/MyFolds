import AppKit

final class EditorWindow: NSWindow {
    var handleEditorShortcut: ((NSEvent) -> Bool)?
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if attachedSheet == nil, handleEditorShortcut?(event) == true { return true }
        return super.performKeyEquivalent(with: event)
    }
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, attachedSheet == nil, handleEditorShortcut?(event) == true { return }
        super.sendEvent(event)
    }
}
