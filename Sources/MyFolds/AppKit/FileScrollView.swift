import AppKit

final class FileScrollView: NSScrollView {
    var blankMenu: (() -> NSMenu)?
    override func menu(for event: NSEvent) -> NSMenu? { blankMenu?() }
}
