import SwiftUI

struct WindowMaterial<Content: View>: NSViewControllerRepresentable {
    @Bindable var preferences: Preferences
    @Environment(\.accessibilityReduceTransparency) private var systemOpaque
    var identifier = "MyFolds.main"
    var editorAppearance = false
    @ViewBuilder var content: Content

    func makeNSViewController(context: Context) -> MaterialContentController<Content> {
        let controller = MaterialContentController(content: content)
        updateMaterial(controller.surface)
        return controller
    }
    func updateNSViewController(_ controller: MaterialContentController<Content>, context: Context) {
        updateMaterial(controller.surface)
        controller.update(content: content)
    }
    private func updateMaterial(_ surface: MaterialView) {
        surface.windowAppearance = editorAppearance && preferences.editor.appearance != "app" ? preferences.editor.appearance : preferences.appearance
        surface.wantsOpaque = preferences.reduceTransparency || systemOpaque
        surface.windowID = identifier
        surface.configureWindow()
    }
}
