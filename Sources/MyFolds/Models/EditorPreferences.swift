import AppKit

struct EditorPreferences: Codable, Equatable {
    var showLineNumbers = true
    var fontFamily = "system-monospace"
    var fontSize = 13.0
    var appearance = "app"
    var scrollToZoom = true
    var findShortcut = EditorShortcut.find
    var replaceShortcut = EditorShortcut.replace

    var normalized: Self {
        var value = self
        value.fontSize = fontSize.isFinite ? min(72, max(8, fontSize)) : 13
        if !["app", "system", "light", "dark"].contains(appearance) { value.appearance = "app" }
        if fontFamily.isEmpty { value.fontFamily = "system-monospace" }
        if findShortcut.validationError != nil { value.findShortcut = .find }
        if replaceShortcut.validationError != nil { value.replaceShortcut = .replace }
        if value.findShortcut == value.replaceShortcut { value.findShortcut = .find; value.replaceShortcut = .replace }
        return value
    }
    func font(size: Double? = nil) -> NSFont {
        let points = min(72, max(8, size ?? fontSize))
        if fontFamily != "system-monospace", let font = NSFontManager.shared.font(withFamily: fontFamily, traits: [], weight: 5, size: points) { return font }
        return .monospacedSystemFont(ofSize: points, weight: .regular)
    }
}
