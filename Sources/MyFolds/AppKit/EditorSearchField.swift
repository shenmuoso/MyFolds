import SwiftUI

struct EditorSearchField: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: UUID
    let submit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> EditorSearchTextField {
        let field = EditorSearchTextField()
        field.bezelStyle = .roundedBezel
        field.isBordered = false
        field.isBezeled = true
        field.drawsBackground = true
        field.controlSize = .small
        field.font = .systemFont(ofSize: 11)
        field.placeholderString = "查找内容"
        field.setAccessibilityIdentifier("editor.find")
        field.setAccessibilityLabel("查找内容")
        field.delegate = context.coordinator
        return field
    }
    func updateNSView(_ field: EditorSearchTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
        field.requestFocus(focusRequest)
    }
    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: EditorSearchField
        init(_ parent: EditorSearchField) { self.parent = parent }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            parent.submit()
            return true
        }
    }
}

final class EditorSearchTextField: NSTextField {
    private var lastRequest: UUID?
    private var pendingFocus = false

    func requestFocus(_ request: UUID) {
        guard request != lastRequest else { return }
        lastRequest = request
        pendingFocus = true
        focusWhenAttached()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        focusWhenAttached()
    }
    private func focusWhenAttached() {
        guard pendingFocus, window != nil else { return }
        Task { @MainActor [weak self] in
            guard let self, pendingFocus, let window else { return }
            pendingFocus = false
            window.makeFirstResponder(self)
            selectText(nil)
        }
    }
}
