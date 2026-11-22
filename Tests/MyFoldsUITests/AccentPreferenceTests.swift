import SwiftUI
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Shared accent preference", .serialized)
struct AccentPreferenceTests {
    @Test func choicePersistsAndUnknownValueFallsBackToSystem() throws {
        let name = "MyFolds-Accent-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = Preferences(defaults: defaults)
        #expect(preferences.accent == .system)
        preferences.accent = .purple
        #expect(Preferences(defaults: defaults).accent == .purple)
        defaults.set("unknown-color", forKey: "accentColor")
        #expect(Preferences(defaults: defaults).accent == .system)
    }

    @Test func everyPaletteKeepsSelectionTextReadable() throws {
        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            for accent in AppAccent.allCases {
                let palette = accent.palette(appearance: NSAppearance(named: appearance))
                let background = try #require(palette.background.usingColorSpace(.sRGB))
                let foreground = try #require(palette.foreground.usingColorSpace(.sRGB))
                func luminance(_ color: NSColor) -> Double {
                    func linear(_ component: CGFloat) -> Double { component <= 0.04045 ? Double(component / 12.92) : pow(Double((component + 0.055) / 1.055), 2.4) }
                    return 0.2126 * linear(color.redComponent) + 0.7152 * linear(color.greenComponent) + 0.0722 * linear(color.blueComponent)
                }
                let a = luminance(background), b = luminance(foreground)
                #expect((max(a, b) + 0.05) / (min(a, b) + 0.05) >= 4.5)
                if [.blue, .purple, .pink, .red, .graphite].contains(accent) {
                    #expect(palette.foreground == .white)
                }
            }
        }
    }

    @Test func nativeRowsUpdateImmediatelyWithoutLosingSelection() async throws {
        _ = NSApplication.shared
        let name = "MyFolds-Accent-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("selected.md")
        try Data("# Accent".utf8).write(to: file)
        let item = try FileItem(url: file), model = BrowserModel(defaults: defaults)
        let session = model.primary; session.selection = [item.url]
        let view = NativeFileTable(items: [item], selection: .constant([item.url]), model: model, session: session, isRight: false)
        let host = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false; window.setContentSize(NSSize(width: 700, height: 240))
        defer { window.close() }
        for accent in [AppAccent.purple, .yellow, .system] {
            model.preferences.accent = accent
            try await Task.sleep(for: .milliseconds(100))
            window.contentView?.layoutSubtreeIfNeeded()
            let table = try #require(findTable(window.contentView))
            #expect(table.selectedRowIndexes == [0])
            let row = try #require(table.rowView(atRow: 0, makeIfNecessary: true) as? FileSelectionRow)
            #expect(row.accent == accent)
            row.isEmphasized = true; row.updateTextColors()
            let cell = try #require(table.view(atColumn: 0, row: 0, makeIfNecessary: true) as? NSTableCellView)
            #expect(cell.textField?.textColor == row.selectionPalette.foreground)
        }
    }

    private func findTable(_ view: NSView?) -> BrowserTable? {
        guard let view else { return nil }
        if let table = view as? BrowserTable { return table }
        return view.subviews.lazy.compactMap { findTable($0) }.first
    }
}
