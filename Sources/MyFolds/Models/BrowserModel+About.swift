import SwiftUI

extension BrowserModel {
    func openAbout() {
        if let aboutWindow { aboutWindow.makeKeyAndOrderFront(nil); return }
        let content = WindowMaterial(preferences: preferences, identifier: "MyFolds.about") {
            AboutView().appAccentPreference(preferences)
        }.frame(width: 420, height: 430).ignoresSafeArea()
        let controller = NSHostingController(rootView: content)
        controller.safeAreaRegions = []
        let window = AuxiliaryWindow(contentViewController: controller)
        window.title = "关于 MyFolds"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden; window.titlebarAppearsTransparent = true
        window.isOpaque = false; window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 420, height: 430)); window.center()
        aboutWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
