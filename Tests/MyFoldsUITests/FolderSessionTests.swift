import Foundation
import Testing
@testable import MyFolds

@MainActor @Suite("Empty folder refresh")
struct FolderSessionTests {
    @Test("Background refresh preserves the empty presentation while navigation still loads")
    func refreshKeepsEmptyState() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = FolderSession(directory: directory)
        session.reload(hidden: false)
        #expect(session.loading)
        for _ in 0..<100 where session.loading { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!session.loading)
        #expect(session.entries.isEmpty)
        session.reload(hidden: false)
        #expect(!session.loading, "A refresh must not unmount an open empty-space context menu")
        let child = directory.appendingPathComponent("child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        session.navigate(child, hidden: false)
        #expect(session.loading)
        for _ in 0..<100 where session.loading { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!session.loading)
    }
}
