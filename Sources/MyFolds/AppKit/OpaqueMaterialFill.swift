import AppKit

final class OpaqueMaterialFill: NSView {
    override var isOpaque: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        // Solid colors from the approved reduced-transparency palette.
        let dark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let color = dark
            ? NSColor(srgbRed: 53 / 255, green: 53 / 255, blue: 48 / 255, alpha: 1)
            : NSColor(srgbRed: 231 / 255, green: 230 / 255, blue: 226 / 255, alpha: 1)
        color.setFill()
        dirtyRect.fill(using: .copy)
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
