import SwiftUI

struct EditorShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: EditorShortcut
    let other: EditorShortcut
    let label: String
    @Binding var error: String?
    func makeNSView(context: Context) -> ShortcutRecordButton { ShortcutRecordButton() }
    func updateNSView(_ button: ShortcutRecordButton, context: Context) {
        button.displayValue = shortcut.label
        button.setAccessibilityLabel(label)
        button.capture = { candidate in
            if let reason = candidate.validationError { error = reason; return false }
            guard candidate != other else { error = "查找和替换不能使用相同的快捷键。"; return false }
            shortcut = candidate; error = nil; return true
        }
        button.refreshTitle()
    }
}
