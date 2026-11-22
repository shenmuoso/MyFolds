import AppKit

final class BrowserTable: NSTableView {
    var previewAction: (() -> Void)?
    var renameAction: (() -> Void)?
    var activateAction: (() -> Void)?
    var contextMenuProvider: ((Int) -> NSMenu)?
    override func mouseDown(with event: NSEvent) { activateAction?(); super.mouseDown(with: event) }
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.numericPad, .function]).isEmpty {
            if event.keyCode == 49 { previewAction?(); return }
            if event.keyCode == 36 { renameAction?(); return }
        }
        super.keyDown(with: event)
    }
    override func menu(for event: NSEvent) -> NSMenu? {
        activateAction?()
        let index = row(at: convert(event.locationInWindow, from: nil))
        if index >= 0 && !selectedRowIndexes.contains(index) { selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false) }
        if index < 0 { deselectAll(nil) }
        window?.makeFirstResponder(self)
        return contextMenuProvider?(index)
    }
}
