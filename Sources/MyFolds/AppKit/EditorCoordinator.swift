import AppKit
import MyFoldsCore

@MainActor
final class EditorCoordinator: NSObject, NSTextViewDelegate {
    let document: TextDocumentSession
    let preferences: Preferences
    var token = UUID()
    var dark = false
    let highlighting = TextHighlightController()
    private(set) var lineIndex = TextLineIndex()
    private var indexTask: Task<Void, Never>?
    private var indexGeneration = UUID()
    init(document: TextDocumentSession, preferences: Preferences) { self.document = document; self.preferences = preferences }
    func cancel() { highlighting.cancel(); indexTask?.cancel(); document.search.detach() }
    func textDidChange(_ notification: Notification) {
        guard let text = notification.object as? EditorTextView else { return }
        document.text = text.string
        document.search.contentChanged()
        highlighting.invalidate()
        highlighting.refresh(text, text: document.text, language: document.syntaxLanguage, dark: dark)
        refreshLines(text)
    }
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        document.search.willEdit(affectedCharRange, replacement: replacementString)
        return true
    }
    func textViewDidChangeSelection(_ notification: Notification) {
        guard let text = notification.object as? EditorTextView else { return }
        document.search.selectionChanged(text.selectedRange())
        updateCursor(text)
        text.enclosingScrollView?.verticalRulerView?.needsDisplay = true
    }
    func refreshLines(_ view: EditorTextView) {
        indexTask?.cancel()
        let text = view.string, request = UUID(); indexGeneration = request
        indexTask = Task { [weak self, weak view] in
            do {
                try await Task.sleep(for: .milliseconds(40))
                let worker = Task.detached(priority: .userInitiated) { try TextLineIndex(text) }
                let index = try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
                try Task.checkCancellation()
                guard let self, let view, indexGeneration == request else { return }
                lineIndex = index
                (view.enclosingScrollView?.verticalRulerView as? EditorLineNumberRuler)?.update(index: index, fontSize: Double(view.font?.pointSize ?? 13))
                updateCursor(view)
            } catch { }
        }
    }
    private func updateCursor(_ view: NSTextView) {
        let position = min(view.selectedRange().location, (view.string as NSString).length)
        let line = lineIndex.line(at: position)
        let start = min(position, lineIndex.starts[line])
        document.cursorLine = line + 1
        document.cursorColumn = (view.string as NSString).substring(with: NSRange(location: start, length: position - start)).count + 1
    }
}
