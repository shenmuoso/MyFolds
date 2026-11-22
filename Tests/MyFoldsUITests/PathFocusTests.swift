import AppKit
import SwiftUI
import Testing
@testable import MyFolds

@MainActor @Suite("Path field focus", .serialized)
struct PathFocusTests {
    @Test func selectingPathReportsFocusBeforeTypingAndClearsOnBlur() async throws {
        _ = NSApplication.shared
        var focused = false
        let host = NSHostingController(rootView: NativePathField(text: .constant("/tmp"), submit: {}, cancel: {}, focusChanged: { focused = $0 }))
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 400, height: 32))
        window.orderFront(nil)
        defer { window.close() }
        try await Task.sleep(for: .milliseconds(120))
        #expect(focused)
        window.makeFirstResponder(nil)
        try await Task.sleep(for: .milliseconds(30))
        #expect(!focused)
    }
}
