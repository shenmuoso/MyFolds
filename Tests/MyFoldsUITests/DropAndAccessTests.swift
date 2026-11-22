import AppKit
import Testing
@testable import MyFolds

@MainActor @Suite("Drop reception and directory bookmarks", .serialized)
struct DropAndAccessTests {
    @Test func sameParentCancelsAndOtherParentCopiesThroughItemProvider() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = root.appendingPathComponent("source"), target = root.appendingPathComponent("target")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = source.appendingPathComponent("drop.txt")
        try Data("drop fixture".utf8).write(to: file)
        let model = BrowserModel()
        model.tabs = [FolderSession(directory: source)]
        model.selectedTabID = model.tabs[0].id
        let provider = NSItemProvider(object: file as NSURL)
        await model.receiveDrop([provider], to: source)?.value
        #expect(model.operation == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: source.path) == ["drop.txt"])
        await model.receiveDrop([provider], to: target)?.value
        await model.operation?.value
        #expect(try Data(contentsOf: target.appendingPathComponent("drop.txt")) == Data(contentsOf: file))
        #expect(model.taskHistory.count == 1)
        for tab in model.tabs { tab.cancelWork() }; model.right.cancelWork()
    }

    @Test func directoryBookmarkSurvivesSerialization() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let bookmark = try await DirectoryBookmarks.create(directory)
        let encoded = try PropertyListEncoder().encode([bookmark])
        let restored = try PropertyListDecoder().decode([Data].self, from: encoded)
        let urls = await DirectoryBookmarks.resolve(restored)
        #expect(urls.map { $0.resolvingSymlinksInPath() } == [directory.resolvingSymlinksInPath()])
    }
}
