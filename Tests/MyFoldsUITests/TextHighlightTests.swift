import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Editor highlight drawing", .serialized)
struct TextHighlightTests {
    @Test func highlightingPreservesTextSelectionAndUndo() async throws {
        _ = NSApplication.shared
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        view.isRichText = false; view.allowsUndo = true
        let window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.contentView = view
        defer { window.close() }
        view.string = "let value = 42"
        view.setSelectedRange(NSRange(location: 12, length: 2))
        view.insertText("43", replacementRange: view.selectedRange())
        let selection = view.selectedRange()
        #expect(view.undoManager?.canUndo == true)
        let controller = TextHighlightController()
        controller.refresh(view, text: view.string, language: .swift, dark: false)
        try await waitForColor(in: view, present: true)
        #expect(view.string == "let value = 43")
        #expect(view.selectedRange() == selection)
        #expect(view.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: 0, effectiveRange: nil) != nil)
        #expect(view.undoManager?.canUndo == true)
        view.undoManager?.undo()
        #expect(view.string == "let value = 42")
        controller.invalidate()
        controller.refresh(view, text: view.string, language: .plain, dark: true)
        try await waitForColor(in: view, present: false)
        #expect(view.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: 0, effectiveRange: nil) == nil)
        controller.cancel()
    }

    private func waitForColor(in view: NSTextView, present: Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while ContinuousClock.now < deadline {
            let hasColor = view.layoutManager?.temporaryAttribute(.foregroundColor, atCharacterIndex: 0, effectiveRange: nil) != nil
            if hasColor == present { return }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
