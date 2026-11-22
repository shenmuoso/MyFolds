import SwiftUI

struct WindowControls: NSViewRepresentable {
    func makeNSView(context: Context) -> ControlsView { ControlsView() }
    func updateNSView(_ view: ControlsView, context: Context) { view.installButtons() }
}

final class ControlsView: NSView {
    private(set) var nativeButtons: [NSButton] = []
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Own native buttons instead of moving AppKit's titlebar-owned instances.
        // AppKit may replace those instances during appearance/titlebar updates.
        for (type, action) in [(NSWindow.ButtonType.closeButton, #selector(closeWindow)), (.miniaturizeButton, #selector(minimizeWindow)), (.zoomButton, #selector(zoomWindow))] {
            guard let button = NSWindow.standardWindowButton(type, for: [.titled, .closable, .miniaturizable, .resizable]) else { continue }
            button.target = self; button.action = action
            nativeButtons.append(button); addSubview(button)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); installButtons() }
    override func layout() { super.layout(); installButtons() }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsLayout = true }
    func installButtons() {
        guard let window else { return }
        for (index, type) in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].enumerated() {
            window.standardWindowButton(type)?.isHidden = true
            guard nativeButtons.indices.contains(index) else { continue }
            let button = nativeButtons[index]
            button.setFrameOrigin(NSPoint(x: CGFloat(index) * 20, y: (bounds.height - button.frame.height) / 2))
            button.isHidden = false
            button.isEnabled = type == .zoomButton ? window.styleMask.contains(.resizable) : type == .miniaturizeButton ? window.styleMask.contains(.miniaturizable) : window.styleMask.contains(.closable)
        }
    }
    @objc private func closeWindow() { window?.performClose(nil) }
    @objc private func minimizeWindow() { window?.miniaturize(nil) }
    @objc private func zoomWindow() {
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true { window?.zoom(nil) }
        else { window?.toggleFullScreen(nil) }
    }
}
