import AppKit
import Quartz
import SwiftUI
import Testing
@testable import MyFolds

@MainActor @Suite("Quick Look lifecycle", .serialized)
struct QuickLookLifecycleTests {
    @Test func closingDocxWindowThenDismantlingDoesNotClosePreviewTwice() async throws {
        _ = NSApplication.shared
        let url = try #require(Bundle.module.url(forResource: "preview", withExtension: "docx", subdirectory: "Fixtures"))
        for _ in 0..<3 {
            var host: NSHostingController<AnyView>? = NSHostingController(rootView: AnyView(QuickLookSurface(url: url)))
            let window = NSWindow(contentViewController: host!)
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 500, height: 360))
            window.orderFront(nil)
            try await Task.sleep(for: .milliseconds(150))
            window.contentView?.layoutSubtreeIfNeeded()
            let preview = try #require(findPreview(window.contentView))
            #expect(!preview.shouldCloseWithWindow)
            #expect(preview.previewItem?.previewItemURL == url)
            window.close()
            window.contentViewController = nil
            host = nil
            try await Task.sleep(for: .milliseconds(100))
            #expect(!window.isVisible)
        }
    }

    @Test func replacingDocxBeforeWindowCloseCanOpenAnotherPreview() async throws {
        _ = NSApplication.shared
        let url = try #require(Bundle.module.url(forResource: "preview", withExtension: "docx", subdirectory: "Fixtures"))
        let host = NSHostingController(rootView: AnyView(QuickLookSurface(url: url)))
        let window = NSWindow(contentViewController: host)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 500, height: 360))
        window.orderFront(nil)
        defer { window.close(); window.contentViewController = nil }
        try await Task.sleep(for: .milliseconds(150))
        #expect(findPreview(window.contentView) != nil)
        host.rootView = AnyView(Text("Image preview placeholder"))
        try await Task.sleep(for: .milliseconds(150))
        #expect(findPreview(window.contentView) == nil)
        host.rootView = AnyView(QuickLookSurface(url: url))
        try await Task.sleep(for: .milliseconds(150))
        #expect(findPreview(window.contentView)?.previewItem?.previewItemURL == url)
    }

    private func findPreview(_ view: NSView?) -> QLPreviewView? {
        guard let view else { return nil }
        if let preview = view as? QLPreviewView { return preview }
        return view.subviews.lazy.compactMap { findPreview($0) }.first
    }
}
