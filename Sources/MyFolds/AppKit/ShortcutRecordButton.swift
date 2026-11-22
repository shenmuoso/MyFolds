import AppKit

final class ShortcutRecordButton: NSButton {
    var displayValue = ""
    var capture: ((EditorShortcut) -> Bool)?
    private var recording = false
    override var acceptsFirstResponder: Bool { true }
    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded; setButtonType(.momentaryPushIn)
        target = self; action = #selector(beginRecording)
        toolTip = "点击后按下新快捷键，按 Esc 取消"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    func refreshTitle() { title = recording ? "按下快捷键…" : displayValue }
    @objc private func beginRecording() { recording = true; window?.makeFirstResponder(self); refreshTitle() }
    override func resignFirstResponder() -> Bool { recording = false; refreshTitle(); return super.resignFirstResponder() }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if recording { accept(event); return true }
        return super.performKeyEquivalent(with: event)
    }
    override func keyDown(with event: NSEvent) {
        if recording { accept(event) } else { super.keyDown(with: event) }
    }
    private func accept(_ event: NSEvent) {
        if event.keyCode == 53 { recording = false; refreshTitle(); return }
        if let candidate = EditorShortcut(event: event), capture?(candidate) == true {
            displayValue = candidate.label; recording = false; refreshTitle()
        }
    }
}
