import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MyFoldsCore

@Suite("Default application routing")
struct OpeningRulesTests {
    @Test("Suffix input accepts familiar notation without accepting paths")
    func normalization() {
        #expect(OpeningRules.normalizedExtension(" .MD\n") == "md")
        #expect(OpeningRules.normalizedExtension("*.TAR.GZ") == "tar.gz")
        for value in ["", ".", "*", "a/b", "../md", "md txt", "a..b", "https://example.com"] {
            #expect(OpeningRules.normalizedExtension(value) == nil)
        }
    }

    @Test("Suffix wins over legacy type and category, including uppercase filenames")
    func suffixPriority() {
        let url = URL(fileURLWithPath: "/tmp/notes.MD")
        #expect(OpeningRules.applicationPath(for: url, typeIdentifier: UTType.plainText.identifier,
            extensions: ["md": "/Apps/Suffix.app"], types: [UTType.plainText.identifier: "/Apps/Legacy.app"],
            categories: ["markdown": "/Apps/Markdown.app", "text": "/Apps/Text.app"]) == "/Apps/Suffix.app")
    }

    @Test("Longest suffix wins and never matches a directory or partial filename")
    func compoundSuffix() {
        let rules = ["gz": "gzip", "tar.gz": "tar", "md": "editor"]
        #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/backup.TAR.GZ"), typeIdentifier: "public.data", extensions: rules, types: [:], categories: [:]) == "tar")
        for path in ["/tmp/a.md/readme", "/tmp/readmd", "/tmp/notes.md.backup"] {
            #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: path), typeIdentifier: "public.data", extensions: rules, types: [:], categories: [:]) == nil)
        }
    }

    @Test("Dedicated document categories keep independent defaults")
    func documentCategories() {
        let rules = ["markdown": "markdown", "html": "browser", "text": "editor"]
        for (name, expected) in [("readme.md", "markdown"), ("index.html", "browser"), ("notes.txt", "editor")] {
            #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/" + name), typeIdentifier: UTType.plainText.identifier, extensions: [:], types: [:], categories: rules) == expected)
        }
        for name in ["readme.md", "index.html", "photo.svg"] {
            #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/" + name), typeIdentifier: UTType.plainText.identifier, extensions: [:], types: [:], categories: ["text": "editor"]) == nil)
        }
    }

    @Test("Categories route common and UTI-derived formats independently")
    func formatCategories() {
        for (suffix, category) in [("docx", "office"), ("xlsx", "office"), ("pptx", "office"), ("jpg", "image"), ("mkv", "video"), ("flac", "audio"), ("pdf", "pdf"), ("7z", "archive")] {
            #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/sample." + suffix), typeIdentifier: "public.data", extensions: [:], types: [:], categories: [category: "app", "text": "editor"]) == "app")
        }
        #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/photo.custom"), typeIdentifier: UTType.png.identifier, extensions: [:], types: [:], categories: ["image": "viewer"]) == "viewer")
        #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/unknown.bin"), typeIdentifier: "public.data", extensions: [:], types: [:], categories: ["text": "editor"]) == nil)
    }

    @Test("Existing exact type preferences survive the new category fallback")
    func legacyCompatibility() {
        #expect(OpeningRules.applicationPath(for: URL(fileURLWithPath: "/tmp/photo.png"), typeIdentifier: UTType.png.identifier, extensions: [:], types: [UTType.png.identifier: "legacy"], categories: ["image": "viewer"]) == "legacy")
    }
}
