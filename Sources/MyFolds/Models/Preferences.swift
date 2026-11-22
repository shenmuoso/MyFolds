import SwiftUI
import MyFoldsCore

@MainActor @Observable
final class Preferences {
    static let builtInApplication = OpeningDestination.builtInIdentifier
    static let systemApplication = OpeningDestination.systemIdentifier
    static let builtInTitle = "MyFolds 内置查看器"
    @ObservationIgnored private let defaults: UserDefaults
    var appearance: String { didSet { save() } }
    var accent: AppAccent { didSet { save() } }
    var reduceMotion: Bool { didSet { save() } }
    var compact: Bool { didSet { save() } }
    var showHidden: Bool { didSet { save() } }
    var reduceTransparency: Bool { didSet { save() } }
    var increaseContrast: Bool { didSet { save() } }
    var favorites: [String] { didSet { save() } }
    var applicationRules: [String: String] { didSet { save() } }
    var extensionRules: [String: String] { didSet { save() } }
    var categoryRules: [String: String] { didSet { save() } }
    var editor: EditorPreferences {
        didSet {
            let normalized = editor.normalized
            if editor != normalized { editor = normalized }
            if let data = try? JSONEncoder().encode(editor) { defaults.set(data, forKey: "textEditorPreferences") }
        }
    }
    var settingsSection = "外观"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let d = defaults
        appearance = d.string(forKey: "appearance") ?? "system"
        accent = d.string(forKey: "accentColor").flatMap(AppAccent.init(rawValue:)) ?? .graphite
        compact = d.bool(forKey: "compact")
        reduceMotion = d.bool(forKey: "reduceMotion")
        showHidden = d.bool(forKey: "showHidden")
        reduceTransparency = d.bool(forKey: "reduceTransparency")
        increaseContrast = d.bool(forKey: "increaseContrast")
        favorites = d.stringArray(forKey: "favorites") ?? []
        applicationRules = d.dictionary(forKey: "applicationRules") as? [String: String] ?? [:]
        extensionRules = d.dictionary(forKey: "extensionRules") as? [String: String] ?? [:]
        categoryRules = d.dictionary(forKey: "categoryRules") as? [String: String] ?? [:]
        editor = (d.data(forKey: "textEditorPreferences").flatMap { try? JSONDecoder().decode(EditorPreferences.self, from: $0) } ?? EditorPreferences()).normalized
    }
    private func save() {
        let d = defaults
        d.set(accent.rawValue, forKey: "accentColor")
        d.set(reduceMotion, forKey: "reduceMotion"); d.set(appearance, forKey: "appearance"); d.set(compact, forKey: "compact")
        d.set(showHidden, forKey: "showHidden"); d.set(reduceTransparency, forKey: "reduceTransparency")
        d.set(increaseContrast, forKey: "increaseContrast"); d.set(favorites, forKey: "favorites")
        d.set(applicationRules, forKey: "applicationRules")
        d.set(extensionRules, forKey: "extensionRules")
        d.set(categoryRules, forKey: "categoryRules")
    }
    func applicationPath(for file: FileItem) -> String? {
        if case .application(let path) = openingDestination(for: file) { return path }
        return nil
    }
    func openingDestination(for file: FileItem) -> OpeningDestination {
        guard !file.isDirectory else { return .automatic }
        return OpeningDestination(rule: OpeningRules.applicationPath(for: file.url, typeIdentifier: file.typeIdentifier, extensions: extensionRules, types: applicationRules, categories: categoryRules))
    }
    func rememberApplication(_ app: URL, for file: FileItem) {
        if let ext = OpeningRules.normalizedExtension(file.url.pathExtension) { extensionRules[ext] = app.path }
        else { applicationRules[file.typeIdentifier] = app.path }
    }
    func clearApplication(for file: FileItem) {
        if let ext = OpeningRules.matchingExtension(for: file.url, rules: extensionRules) { extensionRules.removeValue(forKey: ext) }
        applicationRules.removeValue(forKey: file.typeIdentifier)
    }
}
