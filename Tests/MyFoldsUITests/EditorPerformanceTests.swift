import AppKit
import SwiftUI
import Testing
@testable import MyFolds

@MainActor @Suite("Large document editing", .serialized)
struct EditorPerformanceTests {
    @Test func changingFontInLargeDocumentPreservesContentAndSelection() async throws {
        _ = NSApplication.shared
        let name = "MyFolds.FontPerformance." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = Preferences(defaults: defaults)
        let document = TextDocumentSession(url: URL(fileURLWithPath: "/tmp/performance.swift"))
        let source = String(repeating: "let number = 42 // example line\n", count: 40_000)
        document.text = source
        let host = NSHostingController(rootView: NativeTextEditor(document: document, preferences: preferences))
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false; window.setContentSize(NSSize(width: 800, height: 500))
        defer { window.close() }
        try await Task.sleep(for: .milliseconds(150))
        let scroll = try #require(findScroll(window.contentView))
        let text = try #require(scroll.documentView as? EditorTextView)
        #expect(text.layoutManager?.allowsNonContiguousLayout == true)
        // Include syntax painting, as resizing an unstyled NSTextView hides the regression.
        try await Task.sleep(for: .seconds(2))
        let selection = NSRange(location: 4, length: 6)
        text.setSelectedRange(selection)
        for size in [18.0, 22.0, 13.0] {
            let start = ContinuousClock.now
            preferences.editor.fontSize = size
            let deadline = start + .seconds(8)
            while text.font?.pointSize != CGFloat(size) && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            text.sizeToFit()
            window.contentView?.layoutSubtreeIfNeeded(); window.displayIfNeeded()
            print("EDITOR_FONT \(size): \(start.duration(to: .now))")
            #expect(text.font?.pointSize == CGFloat(size))
            #expect(text.selectedRange() == selection)
            #expect(text.string == source)
        }
    }
    @Test func rapidFontChangesDoNotApplyAnObsoleteSize() async throws {
        let document = TextDocumentSession(url: URL(fileURLWithPath: "/tmp/font-race.txt"))
        let text = EditorTextView(frame: .zero)
        text.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        let coordinator = EditorCoordinator(document: document, preferences: Preferences())
        coordinator.applyFont(.monospacedSystemFont(ofSize: 22, weight: .regular), to: text)
        coordinator.applyFont(.monospacedSystemFont(ofSize: 13, weight: .regular), to: text)
        try await Task.sleep(for: .milliseconds(40))
        #expect(text.font?.pointSize == 13)
        coordinator.cancel()
    }
    private func findScroll(_ view: NSView?) -> EditorScrollView? {
        guard let view else { return nil }
        if let scroll = view as? EditorScrollView { return scroll }
        return view.subviews.lazy.compactMap { findScroll($0) }.first
    }
}
