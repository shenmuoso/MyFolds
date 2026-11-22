#if DEBUG
import AppKit

extension BrowserModel {
    func showMaterialCheck() {
        guard let main = NSApp.windows.first(where: { $0.identifier?.rawValue == "MyFolds.main" }) else { return }
        materialBackdrop?.close()
        let window = NSWindow(contentRect: main.frame.insetBy(dx: -50, dy: -50), styleMask: [.borderless], backing: .buffered, defer: false)
        window.title = "MyFolds 材质测试背景"; window.identifier = .init("MyFolds.materialCheck")
        window.isReleasedWhenClosed = false; window.isExcludedFromWindowsMenu = true
        window.contentView = MaterialCheckPattern(frame: NSRect(origin: .zero, size: window.frame.size))
        materialBackdrop = window
        window.order(.below, relativeTo: main.windowNumber)
        main.makeKeyAndOrderFront(nil)
        MaterialDiagnostics.record(main)
    }
    func showMaterialProbe() {
        showMaterialCheck()
        materialProbe?.close()
        let probe = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 500), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        probe.title = "MyFolds 原生材质对照（开发验证）"
        probe.identifier = .init("MyFolds.materialProbe")
        probe.isOpaque = false; probe.backgroundColor = .clear; probe.isReleasedWhenClosed = false
        probe.appearance = NSAppearance(named: .aqua)
        let effect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 900, height: 500))
        effect.material = .underWindowBackground
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.alphaValue = 1
        probe.contentView = effect
        let label = NSTextField(labelWithString: "原生窗口后方模糊 · RGB 背景")
        label.frame = NSRect(x: 45, y: 230, width: 800, height: 40)
        label.font = .systemFont(ofSize: 22, weight: .medium)
        effect.addSubview(label)
        probe.center(); materialProbe = probe; probe.makeKeyAndOrderFront(nil)
        materialBackdrop?.setFrame(probe.frame.insetBy(dx: -40, dy: -40), display: true)
        materialBackdrop?.order(.below, relativeTo: probe.windowNumber)
        MaterialDiagnostics.record(probe)
    }
}
final class MaterialCheckPattern: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let colors: [NSColor] = [.systemRed, .systemGreen, .systemBlue]
        for (index, color) in colors.enumerated() {
            color.setFill()
            NSRect(x: bounds.width * CGFloat(index) / 3, y: 0, width: bounds.width / 3, height: bounds.height).fill()
        }
        NSColor.white.withAlphaComponent(0.25).setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 90, dy: 120)).fill()
        let sample = "MyFolds · 背景文字应被磨砂打散" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: NSColor.black.withAlphaComponent(0.65)]
        for y in stride(from: 40.0, to: bounds.height, by: 68) {
            for x in stride(from: 30.0, to: bounds.width, by: 360) {
                sample.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
            }
        }
    }
}
#endif
