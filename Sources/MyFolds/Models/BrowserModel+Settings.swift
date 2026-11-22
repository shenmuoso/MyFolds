import SwiftUI

extension BrowserModel {
    func openOpeningSettings() {
        preferences.settingsSection = "打开方式"
        openSettings()
    }
    func openSettings() {
        if let settingsWindow { settingsWindow.makeKeyAndOrderFront(nil); return }
        let view = WindowMaterial(preferences: preferences, identifier: "MyFolds.settings") {
            SettingsView(preferences: preferences, access: access).browserMotionPreference(preferences)
        }.frame(width: 760, height: 552).ignoresSafeArea()
        let controller = NSHostingController(rootView: view)
        controller.safeAreaRegions = []
        let window = AuxiliaryWindow(contentViewController: controller)
        window.title = "MyFolds 设置"; window.identifier = .init("MyFolds.settings")
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titleVisibility = .hidden; window.titlebarAppearsTransparent = true
        window.isOpaque = false; window.backgroundColor = .clear
        window.setFrame(NSRect(x: 0, y: 0, width: 760, height: 552), display: false)
        if let main = NSApp.windows.first(where: { $0.identifier?.rawValue == "MyFolds.main" }) {
            window.setFrameOrigin(NSPoint(x: main.frame.midX - 380, y: main.frame.midY - 276))
        } else { window.center() }
        window.isReleasedWhenClosed = false
        settingsWindow = window; window.makeKeyAndOrderFront(nil)
    }
}
