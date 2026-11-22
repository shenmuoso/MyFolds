import AppKit

enum AppAccent: String, CaseIterable, Sendable {
    case system, blue, purple, pink, red, orange, yellow, green, graphite

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .blue: "蓝色"
        case .purple: "紫色"
        case .pink: "粉色"
        case .red: "红色"
        case .orange: "橙色"
        case .yellow: "黄色"
        case .green: "绿色"
        case .graphite: "石墨色"
        }
    }

    private var nativeColor: NSColor {
        switch self {
        case .system: .selectedContentBackgroundColor
        case .blue: .systemBlue
        case .purple: .systemPurple
        case .pink: .systemPink
        case .red: .systemRed
        case .orange: .systemOrange
        case .yellow: .systemYellow
        case .green: .systemGreen
        case .graphite: .systemGray
        }
    }

    func palette(appearance: NSAppearance?) -> SelectionPalette {
        var color = nativeColor
        appearance?.performAsCurrentDrawingAppearance { color = nativeColor.usingColorSpace(.sRGB) ?? nativeColor }
        let prefersLightText = [.blue, .purple, .pink, .red, .graphite].contains(self)
        return SelectionPalette(background: color, prefersLightText: prefersLightText)
    }
}
