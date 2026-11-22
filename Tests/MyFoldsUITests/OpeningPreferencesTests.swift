import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Opening preferences", .serialized)
struct OpeningPreferencesTests {
    @Test("Rules persist, explicit suffix resets fall back, and folders never use file rules")
    func persistenceAndReset() throws {
        let domain = "MyFolds.opening-test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: domain); try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.md")
        try Data("# Fixture".utf8).write(to: url)
        let file = try FileItem(url: url)
        let preferences = Preferences(defaults: defaults)
        preferences.categoryRules["markdown"] = "/Apps/Category.app"
        preferences.rememberApplication(URL(fileURLWithPath: "/Apps/Suffix.app"), for: file)
        let restored = Preferences(defaults: defaults)
        #expect(restored.applicationPath(for: file) == "/Apps/Suffix.app")
        restored.clearApplication(for: file)
        #expect(Preferences(defaults: defaults).applicationPath(for: file) == "/Apps/Category.app")
        let folder = directory.appendingPathComponent("folder.md")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(try restored.applicationPath(for: FileItem(url: folder)) == nil)
    }

    @Test("Clearing a compound suffix removes the rule actually used")
    func compoundReset() throws {
        let domain = "MyFolds.opening-test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".tar.gz")
        try Data().write(to: url)
        defer { defaults.removePersistentDomain(forName: domain); try? FileManager.default.removeItem(at: url) }
        let preferences = Preferences(defaults: defaults)
        preferences.extensionRules = ["tar.gz": "specific", "gz": "general"]
        let file = try FileItem(url: url)
        preferences.clearApplication(for: file)
        #expect(preferences.applicationPath(for: file) == "general")
    }

    @Test("Explicit built-in choice overrides a broader external text application")
    func builtInOverride() throws {
        let domain = "MyFolds.opening-test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        try Data("# Example".utf8).write(to: url)
        defer { defaults.removePersistentDomain(forName: domain); try? FileManager.default.removeItem(at: url) }
        let file = try FileItem(url: url), preferences = Preferences(defaults: defaults)
        preferences.categoryRules["text"] = "/Apps/Text.app"
        #expect(preferences.openingDestination(for: file) == .automatic)
        preferences.extensionRules["md"] = Preferences.builtInApplication
        #expect(Preferences(defaults: defaults).applicationPath(for: file) == nil)
        preferences.clearApplication(for: file)
        #expect(preferences.openingDestination(for: file) == .automatic)
    }

    @Test("Every built-in category has independent default and explicit destinations")
    func independentDestinations() throws {
        let name = "MyFolds.routes." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let preferences = Preferences(defaults: defaults)
        preferences.categoryRules["text"] = "/Apps/Text.app"
        for (suffix, category) in [("md", "markdown"), ("html", "html"), ("png", "image"), ("mp4", "video"), ("pdf", "pdf"), ("zip", "archive")] {
            let url = root.appendingPathComponent("example." + suffix)
            try Data("fixture".utf8).write(to: url)
            let item = try FileItem(url: url)
            #expect(preferences.openingDestination(for: item) == .automatic)
            preferences.categoryRules[category] = Preferences.builtInApplication
            #expect(Preferences(defaults: defaults).openingDestination(for: item) == .builtIn)
            preferences.extensionRules[suffix] = Preferences.systemApplication
            #expect(Preferences(defaults: defaults).openingDestination(for: item) == .system)
            preferences.extensionRules[suffix] = "/Apps/Explicit.app"
            #expect(preferences.openingDestination(for: item) == .application("/Apps/Explicit.app"))
        }
    }
}
