import Foundation
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Asynchronous browser data flow")
struct AsyncBrowserTests {
    @Test func slowOldDirectoryCannotReplaceNewNavigationOrFreezeUI() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("first.txt"), next = root.appendingPathComponent("next.txt")
        try Data().write(to: first); try Data().write(to: next)
        let oldItem = try FileItem(url: first), newItem = try FileItem(url: next)
        let slow = root.appendingPathComponent("slow"), fast = root.appendingPathComponent("fast")
        let gate = BrowserReadGate()
        let session = FolderSession(directory: slow) { url, _ in
            // Ignore cancellation to emulate an OS read that has already begun.
            if url == slow { await gate.wait(); return [oldItem] }
            return [newItem]
        }
        session.reload(hidden: false)
        #expect(session.loading)
        var pulses = 0
        let heartbeat = Task { @MainActor in
            for _ in 0..<8 { try await Task.sleep(for: .milliseconds(10)); pulses += 1 }
        }
        try await heartbeat.value
        #expect(pulses == 8)
        #expect(session.loading, "UI heartbeat ran while the data read was still waiting")
        session.navigate(fast, hidden: false)
        #expect(session.visible.isEmpty, "Never interact with rows belonging to the previous folder")
        await gate.release()
        for _ in 0..<100 where session.loading { try await Task.sleep(for: .milliseconds(5)) }
        #expect(session.visible.map(\.url) == [next])
        try await Task.sleep(for: .milliseconds(280))
        #expect(session.visible.map(\.url) == [next])
        #expect(pulses == 8)
    }
    @Test func latestQueryAndSortWinWithoutFilesystemReload() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for name in ["apple.txt", "apricot.txt", "banana.txt"] { try Data().write(to: root.appendingPathComponent(name)) }
        let session = FolderSession(directory: root)
        session.reload(hidden: false)
        for _ in 0..<100 where session.loading { try await Task.sleep(for: .milliseconds(10)) }
        session.query = "banana"; session.query = "ap"; session.ascending = false
        for _ in 0..<100 where session.filtering { try await Task.sleep(for: .milliseconds(10)) }
        #expect(session.visible.map(\.name) == ["apricot.txt", "apple.txt"])
    }
    @Test func editorTracksSaveAndSubsequentChanges() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        try Data("first".utf8).write(to: url); defer { try? FileManager.default.removeItem(at: url) }
        let document = TextDocumentSession(url: url)
        await document.load(); #expect(!document.dirty)
        document.text = "second"; #expect(document.dirty)
        #expect(await document.save()); #expect(!document.dirty)
        #expect(try String(contentsOf: url, encoding: .utf8) == "second")
        try Data("external".utf8).write(to: url); document.text = "third"
        #expect(!(await document.save())); #expect(document.dirty); #expect(document.error != nil)
    }
    @Test func pathFocusDoesNotOpenSuggestionsUntilTypingAndCancellationWins() async throws {
        let editor = PathEditorModel(), base = FileManager.default.temporaryDirectory
        editor.begin(base)
        #expect(editor.editing && editor.suggestions.isEmpty)
        editor.draft = base.path + "/"; editor.typed(relativeTo: base, showHidden: false); editor.cancel()
        try await Task.sleep(for: .milliseconds(170))
        #expect(!editor.editing && editor.suggestions.isEmpty)
    }
}

private actor BrowserReadGate {
    var released = false
    var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        if released { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func release() { released = true; for waiter in waiters { waiter.resume() }; waiters = [] }
}
