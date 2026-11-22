import SwiftUI

// One AppKit container owns the frosted and solid backgrounds, with the
// transparent SwiftUI content above them and its child controller retained.
final class MaterialContentController<Content: View>: NSViewController {
    let surface = MaterialView()
    let appearanceState = WindowAppearanceState()
    let host: NSHostingController<WindowAppearanceContent<Content>>

    init(content: Content) {
        host = NSHostingController(rootView: WindowAppearanceContent(appearance: appearanceState, content: content))
        super.init(nibName: nil, bundle: nil)
        surface.appearanceChanged = { [weak appearanceState] in appearanceState?.update($0) }
        host.safeAreaRegions = []
        host.sizingOptions = []
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    func update(content: Content) {
        host.rootView = WindowAppearanceContent(appearance: appearanceState, content: content)
    }
    override func loadView() {
        view = surface
        addChild(host)
        let content = host.view
        content.translatesAutoresizingMaskIntoConstraints = false
        surface.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: surface.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: surface.trailingAnchor),
            content.topAnchor.constraint(equalTo: surface.topAnchor),
            content.bottomAnchor.constraint(equalTo: surface.bottomAnchor)
        ])
    }
}
