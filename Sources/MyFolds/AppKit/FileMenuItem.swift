import AppKit

final class FileMenuItem: NSMenuItem {
    private let handler: () -> Void
    init(_ title: String, symbol: String, key: String = "", modifiers: NSEvent.ModifierFlags = .command, enabled: Bool = true, action: @escaping () -> Void) {
        handler = action
        super.init(title: title, action: #selector(performAction), keyEquivalent: key)
        target = self
        keyEquivalentModifierMask = modifiers
        isEnabled = enabled
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.size = NSSize(width: 16, height: 16)
        preferredImageVisibility = .visible
    }
    required init(coder: NSCoder) { fatalError("init(coder:) is not used") }
    @objc private func performAction() { handler() }
}
