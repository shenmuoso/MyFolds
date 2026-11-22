import AppKit
import SwiftUI
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Editor settings and search integration", .serialized)
struct EditorSettingsAndSearchTests {
    @Test func settingsPersistAndNormalizeWithoutAffectingAppAppearance() throws {
        let name = "MyFolds.EditorTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = Preferences(defaults: defaults)
        preferences.appearance = "light"
        preferences.editor.appearance = "dark"
        preferences.editor.fontFamily = "Menlo"
        preferences.editor.fontSize = 19
        preferences.editor.showLineNumbers = false
        preferences.editor.scrollToZoom = false
        preferences.editor.findShortcut = EditorShortcut(key: "f", command: false, control: true)
        let restored = Preferences(defaults: defaults)
        #expect(restored.editor == preferences.editor)
        #expect(restored.appearance == "light")
        #expect(restored.editor.font().pointSize == 19)
        restored.editor.fontSize = 999
        #expect(restored.editor.fontSize == 72)
        #expect(EditorShortcut(key: "s").validationError != nil)
        #expect(EditorShortcut(key: "f", command: false, control: true).validationError == nil)
    }
    @Test func replacementPreservesSyntaxAndSingleUndoRedo() async throws {
        _ = NSApplication.shared
        let document = TextDocumentSession(url: URL(fileURLWithPath: "/tmp/search-test.swift"))
        document.text = "let cat = 1\nlet catName = cat"
        let text = EditorTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        text.isRichText = false; text.allowsUndo = true; text.string = document.text
        let coordinator = EditorCoordinator(document: document, preferences: Preferences())
        text.delegate = coordinator
        let window = NSWindow(contentRect: text.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let content = NSView(frame: text.frame)
        let replacementField = NSTextField(frame: NSRect(x: 0, y: 280, width: 200, height: 20))
        content.addSubview(text); content.addSubview(replacementField); window.contentView = content
        window.makeFirstResponder(replacementField)
        #expect(window.firstResponder !== text)
        defer { coordinator.cancel(); window.close() }
        let search = document.search; search.attach(text); search.open(replace: true)
        search.query = "cat"; search.options.wholeWord = true; search.replacement = "dog"
        try await wait { search.ready }
        #expect(search.result.ranges.count == 2)
        search.replace(all: true)
        try await wait { text.string == "let dog = 1\nlet catName = dog" }
        #expect(document.text == text.string)
        #expect(window.firstResponder === text)
        let message = search.message
        #expect(message?.contains("2") == true)
        search.replacement = "dog"
        #expect(search.message == message)
        #expect(text.undoManager?.canUndo == true)
        text.undoManager?.undo()
        #expect(text.string == "let cat = 1\nlet catName = cat")
        #expect(document.text == text.string)
        text.undoManager?.redo()
        #expect(text.string == "let dog = 1\nlet catName = dog")
    }
    @Test func changedQueryCannotPublishStaleResultsAndZeroLengthNavigationAdvances() async throws {
        let text = EditorTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        text.string = "alpha beta alpha\nsecond"
        let search = EditorSearchModel(); search.attach(text); search.open(replace: false)
        defer { search.detach() }
        search.query = "alpha"; search.query = "beta"
        try await wait { search.ready }
        #expect(search.result.ranges == [NSRange(location: 6, length: 4)])
        search.options.mode = .regularExpression; search.query = "^"
        try await wait { search.ready && search.result.ranges.count == 2 }
        search.navigate()
        let first = text.selectedRange()
        search.selectionChanged(first)
        search.navigate()
        #expect(text.selectedRange() != first)
    }
    @Test func selectionReplacementTracksScopeAndCorrectedTemplateCanRetry() async throws {
        _ = NSApplication.shared
        let document = TextDocumentSession(url: URL(fileURLWithPath: "/tmp/selection-test.txt"))
        let text = EditorTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        text.isRichText = false; text.allowsUndo = true; text.string = "cat cat cat"
        let coordinator = EditorCoordinator(document: document, preferences: Preferences())
        text.delegate = coordinator
        let window = NSWindow(contentRect: text.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.contentView = text
        defer { coordinator.cancel(); window.close() }
        text.setSelectedRange(NSRange(location: 4, length: 3))
        let search = document.search; search.attach(text); search.open(replace: true); search.selectionOnly = true
        search.options.mode = .regularExpression; search.query = "(cat)"; search.replacement = "$2"
        try await wait { search.ready }
        search.replace(all: true)
        try await wait { search.error != nil }
        #expect(text.string == "cat cat cat")
        search.replacement = "kitten"
        #expect(search.ready)
        search.replace(all: true)
        try await wait { text.string == "cat kitten cat" }
        search.query = "kitten"
        try await wait { search.ready }
        #expect(search.result.ranges == [NSRange(location: 4, length: 6)])
        text.undoManager?.undo(); search.query = "cat"
        try await wait { search.ready }
        #expect(search.result.ranges == [NSRange(location: 4, length: 3)])
        search.close()
        #expect(!search.ready)
    }
    @Test func modifierScrollHonorsTheSwitch() throws {
        let scroll = EditorScrollView()
        var steps = 0.0; scroll.onZoom = { steps += $0 }
        let cg = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: 2, wheel2: 0, wheel3: 0))
        cg.flags = .maskControl
        let event = try #require(NSEvent(cgEvent: cg))
        scroll.scrollWheel(with: event)
        #expect(steps > 0)
        let previous = steps
        scroll.zoomEnabled = false; scroll.scrollWheel(with: event)
        #expect(steps == previous)
        scroll.zoomEnabled = true; cg.flags = .maskCommand
        scroll.scrollWheel(with: try #require(NSEvent(cgEvent: cg)))
        #expect(steps > previous)
    }
    @Test func liveFontGutterAndIndependentThemePreserveEditing() async throws {
        _ = NSApplication.shared
        let name = "MyFolds.EditorViewTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = Preferences(defaults: defaults); preferences.appearance = "light"; preferences.editor.appearance = "dark"
        let document = TextDocumentSession(url: URL(fileURLWithPath: "/tmp/editor-view.txt"))
        let original = "first\nsecond 😀\r\nthird\n"
        document.text = original
        let content = WindowMaterial(preferences: preferences, identifier: "EditorTest", editorAppearance: true) {
            NativeTextEditor(document: document, preferences: preferences)
        }
        let host = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false; window.setContentSize(NSSize(width: 500, height: 400))
        defer { window.close() }
        try await wait { findScroll(window.contentView) != nil }
        let scroll = try #require(findScroll(window.contentView)), text = try #require(scroll.documentView as? EditorTextView)
        #expect(window.appearance?.name == .darkAqua)
        #expect(scroll.rulersVisible)
        text.insertText("x", replacementRange: NSRange(location: 0, length: 0))
        let selected = text.selectedRange()
        preferences.editor.fontSize = 22; preferences.editor.fontFamily = "Menlo"
        preferences.editor.showLineNumbers = false; preferences.editor.appearance = "light"
        try await wait { text.font?.pointSize == 22 && !scroll.rulersVisible && window.appearance?.name == .aqua }
        #expect(text.selectedRange() == selected)
        #expect(text.string == "x" + original)
        text.undoManager?.undo()
        #expect(text.string == original)
    }
    @Test func searchFieldTakesFocusOnFirstAppearanceAndEachRequest() async throws {
        _ = NSApplication.shared
        let search = EditorSearchModel()
        let host = NSHostingController(rootView: SearchFocusHost(search: search))
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 620, height: 420))
        defer { search.cancel(); window.close() }
        window.makeFirstResponder(window)
        search.open(replace: false)
        try await wait { findSearchField(window.contentView)?.currentEditor() != nil }
        let field = try #require(findSearchField(window.contentView))
        #expect(window.firstResponder === field.currentEditor())
        window.makeFirstResponder(window)
        search.open(replace: true)
        try await wait { field.currentEditor() != nil }
        #expect(window.firstResponder === field.currentEditor())
    }
    @Test func documentWindowKeepsItsSizeWhileSearchingAndEditing() async throws {
        _ = NSApplication.shared
        let name = "MyFolds.EditorWindowTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        try "# Example\n\n- Apple\n- apple\n".write(to: url, atomically: true, encoding: .utf8)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: url) }
        let browser = BrowserModel(defaults: defaults)
        let controller = FileViewerController(item: try FileItem(url: url), kind: .markdown, browser: browser)
        let window = try #require(controller.window), document = try #require(controller.state.document)
        defer { document.search.cancel(); window.close() }
        try await wait { !document.loading && document.revision != nil }
        let initial = window.frame.size
        #expect(initial.height <= 700)
        controller.state.openSearch(replace: true)
        document.search.query = "apple"
        try await wait { document.search.ready }
        document.search.showsResults = true
        document.search.replacement = "pear"; document.search.replace(all: true)
        try await wait { document.text.contains("pear") }
        window.contentView?.layoutSubtreeIfNeeded()
        #expect(window.frame.size == initial)
        window.contentView?.setFrameSize(NSSize(width: 620, height: 420))
        window.setContentSize(NSSize(width: 620, height: 420))
        window.contentView?.layoutSubtreeIfNeeded()
        #expect(window.frame.width == 620)
    }
    private func findSearchField(_ view: NSView?) -> EditorSearchTextField? {
        guard let view else { return nil }
        if let field = view as? EditorSearchTextField { return field }
        return view.subviews.lazy.compactMap { findSearchField($0) }.first
    }
    private func findScroll(_ view: NSView?) -> EditorScrollView? {
        guard let view else { return nil }
        if let scroll = view as? EditorScrollView { return scroll }
        return view.subviews.lazy.compactMap { findScroll($0) }.first
    }
    private func wait(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition(), ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(condition())
    }
}

private struct SearchFocusHost: View {
    @Bindable var search: EditorSearchModel
    var body: some View {
        VStack {
            if search.visible { EditorSearchBar(search: search) }
            Spacer()
        }
    }
}
