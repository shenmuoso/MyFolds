import SwiftUI

struct SelectionPalette {
    let background: NSColor
    let foreground: NSColor
    var fill: Color { Color(nsColor: background) }
    var text: Color { Color(nsColor: foreground) }

    init(background: NSColor, prefersLightText: Bool = false) {
        let rgb = background.usingColorSpace(.sRGB) ?? .systemBlue
        var resolved = rgb
        // Match native selection treatment: retain each hue, with enough depth for white text.
        if prefersLightText && Self.luminance(rgb) > 0.17 {
            var lower: CGFloat = 0, upper: CGFloat = 1
            for _ in 0..<12 {
                let scale = (lower + upper) / 2
                let candidate = NSColor(srgbRed: rgb.redComponent * scale, green: rgb.greenComponent * scale, blue: rgb.blueComponent * scale, alpha: 1)
                if Self.luminance(candidate) > 0.17 { upper = scale } else { lower = scale }
            }
            resolved = NSColor(srgbRed: rgb.redComponent * lower, green: rgb.greenComponent * lower, blue: rgb.blueComponent * lower, alpha: 1)
        }
        self.background = resolved
        let luminance = Self.luminance(resolved)
        // Yellow, orange and green keep their bright fill and use a readable dark foreground.
        foreground = (luminance + 0.05) / 0.05 > 1.05 / (luminance + 0.05) ? .black : .white
    }

    private static func luminance(_ rgb: NSColor) -> CGFloat {
        func linear(_ value: CGFloat) -> CGFloat { value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent) + 0.0722 * linear(rgb.blueComponent)
    }
}
