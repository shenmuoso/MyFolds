import AppKit
import ImageIO

enum ImageDataLoader {
    @concurrent static func load(_ url: URL) async throws -> sending NSImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try Task.checkCancellation()
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
}
