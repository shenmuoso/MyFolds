import AppKit

@MainActor
enum AppIconProvider {
    static let assetName = "AppBrandIcon"
    private static var runningAppearance: Bool?
    private static var resolvedIcons: [Bool: NSImage] = [:]

    static var image: NSImage {
        // Resolve the same appearance-aware artwork used by the installed icon,
        // without using the Dock's cached temporary override.
        Bundle.main.image(forResource: assetName)
            ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
    }

    static func updateRunningIcon(dark: Bool) {
        guard runningAppearance != dark else { return }
        guard let icon = resolvedIcons[dark] ?? resolvedImage(dark: dark) else { return }
        resolvedIcons[dark] = icon
        NSApp.applicationIconImage = icon
        runningAppearance = dark
    }

    static func resolvedImage(dark: Bool, bundle: Bundle = .main) -> NSImage? {
        guard let appearance = NSAppearance(named: dark ? .darkAqua : .aqua),
              let artwork = bundle.image(forResource: assetName),
              let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                isPlanar: false, colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0
              ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
        appearance.performAsCurrentDrawingAppearance {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            let canvas = NSRect(x: 0, y: 0, width: 256, height: 256)
            context.cgContext.clear(canvas)
            // Match the system application's icon inset in the Dock tile.
            artwork.draw(in: canvas.insetBy(dx: 25.6, dy: 25.6))
            NSGraphicsContext.restoreGraphicsState()
        }
        guard let pixels = bitmap.cgImage else { return nil }
        return NSImage(cgImage: pixels, size: NSSize(width: 128, height: 128))
    }
}
