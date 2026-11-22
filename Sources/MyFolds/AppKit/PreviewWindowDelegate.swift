import AppKit

@MainActor final class PreviewWindowDelegate: NSObject, NSWindowDelegate {
    weak var model: BrowserModel?
    init(model: BrowserModel) { self.model = model }
    func windowWillClose(_ notification: Notification) {
        if let current = model?.preview?.item { model?.active.selection = [current.url] }
        (notification.object as? NSWindow)?.contentViewController = nil
        model?.preview = nil; model?.previewWindow = nil
    }
}
