import AppKit

// The material and its opaque fallback belong to the view tree. NSWindow's
// background is not a fallback: SwiftUI may reset it while updating the scene.
final class MaterialView: NSView {
    var windowID = "MyFolds.main"
    var wantsOpaque = false
    var windowAppearance = "system"
    var appearanceChanged: ((NSAppearance) -> Void)?
    private let effect = NSVisualEffectView()
    private let solid = OpaqueMaterialFill()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        // Lowering the effect alpha exposes unblurred pixels behind the window.
        effect.alphaValue = 1
        for child in [effect, solid] {
            child.frame = bounds
            child.autoresizingMask = [.width, .height]
            addSubview(child)
        }
        solid.isHidden = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        solid.needsDisplay = true
        appearanceChanged?(effectiveAppearance)
    }
    func configureWindow() {
        // Install the replacement before hiding the effect. Neither transition
        // relies on NSWindow.isOpaque, which does not paint any pixels itself.
        solid.isHidden = !wantsOpaque
        effect.isHidden = wantsOpaque
        solid.needsDisplay = true
        guard let window else { return }
        let appearanceName: NSAppearance.Name? = windowAppearance == "system" ? nil : windowAppearance == "dark" ? .darkAqua : .aqua
        if window.appearance?.name != appearanceName { window.appearance = appearanceName.flatMap(NSAppearance.init(named:)) }
        appearanceChanged?(window.effectiveAppearance)
        window.isOpaque = false
        window.backgroundColor = .clear
        if !window.styleMask.contains(.fullSizeContentView) { window.styleMask.insert(.fullSizeContentView) }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
        window.identifier = NSUserInterfaceItemIdentifier(windowID)
        #if DEBUG
        MaterialDiagnostics.record(window)
        #endif
    }
}
