import AppKit
import MyFoldsCore

extension BrowserModel {
    var keyDocument: FileViewerController? { documentWindows.values.first { $0.window === NSApp.keyWindow } }
    func openBuiltIn(_ item: FileItem) {
        guard let kind = BuiltInViewer.matching(item) else { return }
        if let controller = documentWindows[item.url] { controller.window?.makeKeyAndOrderFront(nil); return }
        let controller = FileViewerController(item: item, kind: kind, browser: self)
        documentWindows[item.url] = controller
        controller.showWindow(nil); controller.window?.makeKeyAndOrderFront(nil)
    }
    func saveDocument() { keyDocument?.save() }
    func saveDocumentCopy() { keyDocument?.saveCopy() }
    func redoText() { (NSApp.keyWindow?.firstResponder as? NSTextView)?.undoManager?.redo() }
}
