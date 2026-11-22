import SwiftUI

extension BrowserModel {
    func quickLook() {
        guard fileWindowIsKey, let first = selected.first, !first.isDirectory else { return }
        let items = (selected.count > 1 ? selected : active.visible).filter { !$0.isDirectory && !$0.isArchive }
        guard let index = items.firstIndex(where: { $0.id == first.id }) else { return }
        previewWindow?.close()
        let state = PreviewModel(items: items, index: index); preview = state
        let controller = NSHostingController(rootView: PreviewView(preview: state, model: self))
        let window = AuxiliaryWindow(contentViewController: controller)
        window.title = first.name; window.identifier = .init("MyFolds.preview")
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 940, height: 650)); window.center()
        window.isReleasedWhenClosed = false
        let delegate = PreviewWindowDelegate(model: self); previewDelegate = delegate; window.delegate = delegate
        previewWindow = window; window.makeKeyAndOrderFront(nil)
    }
    func closePreview() {
        if let current = preview?.item { active.selection = [current.url] }
        previewWindow?.close(); previewWindow = nil; preview = nil
    }
}
