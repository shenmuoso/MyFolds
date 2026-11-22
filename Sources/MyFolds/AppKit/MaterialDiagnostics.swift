#if DEBUG
import AppKit

enum MaterialDiagnostics {
    @MainActor static func record(_ window: NSWindow) {
        var lines = ["opaque=\(window.isOpaque) background=\(String(describing: window.backgroundColor)) appearance=\(window.effectiveAppearance.name.rawValue)", "systemReduceTransparency=\(NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency)"]
        lines.append("increaseContrast=\(NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast) controller=\(String(describing: window.contentViewController))")
        for item in NSApp.orderedWindows where item.identifier?.rawValue.hasPrefix("MyFolds.") == true {
            lines.append("window=\(item.identifier!.rawValue) visible=\(item.isVisible) number=\(item.windowNumber) frame=\(item.frame) opaque=\(item.isOpaque) background=\(String(describing: item.backgroundColor))")
        }
        func collect(_ view: NSView, depth: Int) {
            guard depth < 14 else { return }
            var line = String(repeating: " ", count: depth * 2) + "\(type(of: view)) frame=\(view.frame) opaque=\(view.isOpaque) alpha=\(view.alphaValue) hidden=\(view.isHidden) wantsLayer=\(view.wantsLayer) hasLayer=\(view.layer != nil) layerBG=\(String(describing: view.layer?.backgroundColor))"
            if let effect = view as? NSVisualEffectView { line += " material=\(effect.material.rawValue) blend=\(effect.blendingMode.rawValue) state=\(effect.state.rawValue)" }
            lines.append(line)
            for child in view.subviews { collect(child, depth: depth + 1) }
        }
        if let content = window.contentView { collect(content, depth: 0) }
        try? lines.joined(separator: "\n").write(to: URL(fileURLWithPath: "/tmp/MyFolds-material-" + (window.identifier?.rawValue ?? "window") + ".txt"), atomically: true, encoding: .utf8)
    }
}
#endif
