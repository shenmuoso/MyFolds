import Foundation
import UniformTypeIdentifiers

public enum BuiltInViewer: String, Sendable {
    case text, markdown, image, video, pdf
    public static func matching(_ file: FileItem) -> Self? {
        guard !file.isDirectory else { return nil }
        let categories = OpeningCategory.matching(fileExtension: file.url.pathExtension, typeIdentifier: file.typeIdentifier)
        if categories.contains(.markdown) { return .markdown }
        if categories.contains(.pdf) { return .pdf }
        if categories.contains(.image) { return .image }
        if categories.contains(.video) { return .video }
        // Rich text and Office packages must not be rewritten as plain text.
        if categories.contains(.office) || ["rtf", "rtfd"].contains(file.url.pathExtension.lowercased()) { return nil }
        if categories.contains(.text) || categories.contains(.html) { return .text }
        return nil
    }
    public var isEditable: Bool { self == .text || self == .markdown }
}
