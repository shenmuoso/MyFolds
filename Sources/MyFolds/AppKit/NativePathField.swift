import SwiftUI

struct NativePathField: NSViewRepresentable {
    @Binding var text: String
    let submit: () -> Void
    let cancel: () -> Void
    var changed: () -> Void = {}
    var step: (Int) -> Void = { _ in }
    var complete: () -> Void = {}
    var focusChanged: (Bool) -> Void = { _ in }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> PathTextField {
        let field = PathTextField()
        field.isBordered = false; field.drawsBackground = false; field.focusRingType = .none
        field.textColor = BrowserChrome.pathNativeText
        field.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        field.placeholderAttributedString = NSAttributedString(string: "输入完整路径", attributes: [.foregroundColor: BrowserChrome.pathNativeText])
        field.setAccessibilityLabel("输入完整路径")
        field.delegate = context.coordinator; field.stringValue = text
        field.onFocus = { [weak coordinator = context.coordinator] in coordinator?.parent.focusChanged(true) }
        return field
    }
    func updateNSView(_ field: PathTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
    }
    @MainActor final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativePathField
        init(_ parent: NativePathField) { self.parent = parent }
        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.focusChanged(true)
            guard let field = notification.object as? NSTextField, let editor = field.currentEditor() as? NSTextView else { return }
            editor.insertionPointColor = BrowserChrome.pathNativeText; editor.textColor = BrowserChrome.pathNativeText
        }
        func controlTextDidEndEditing(_ notification: Notification) { parent.focusChanged(false) }
        func controlTextDidChange(_ notification: Notification) {
            if let field = notification.object as? NSTextField { parent.text = field.stringValue; parent.changed() }
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) { parent.submit(); return true }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) { parent.cancel(); return true }
            if commandSelector == #selector(NSResponder.moveDown(_:)) { parent.step(1); return true }
            if commandSelector == #selector(NSResponder.moveUp(_:)) { parent.step(-1); return true }
            if commandSelector == #selector(NSResponder.insertTab(_:)) { parent.complete(); return true }
            return false
        }
    }
}
final class PathTextField: NSTextField {
    var onFocus: (() -> Void)?
    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted {
            Task { @MainActor [weak self] in
                guard let self, currentEditor() != nil else { return }
                onFocus?()
            }
        }
        return accepted
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Task { @MainActor [weak self] in
            guard let self, let window = self.window else { return }
            window.makeFirstResponder(self); self.selectText(nil)
            if self.currentEditor() != nil { self.onFocus?() }
        }
    }
}
