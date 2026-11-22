import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Quick access references", .serialized)
struct QuickAccessTests {
    @Test func shortcutOpensBuiltInFileAndFolderInCapturedPane() async throws {
        _ = NSApplication.shared
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("open.md")
        try Data("# Shortcut".utf8).write(to: file)
        let model = BrowserModel(defaults: defaults)
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() }; for controller in model.documentWindows.values { controller.close() } }
        model.split = true; model.rightActive = true
        await model.quickAccess.add([root, file])
        let folderEntry = try #require(model.quickAccess.entries.first)
        let fileEntry = try #require(model.quickAccess.entries.last)
        let opening = model.openQuickAccess(folderEntry)
        model.rightActive = false
        await opening.value
        #expect(model.right.directory.resolvingSymlinksInPath() == root.resolvingSymlinksInPath())
        #expect(model.primary.directory != root)
        await model.openQuickAccess(fileEntry).value
        #expect(model.documentWindows.count == 1)
        #expect(model.documentWindows.values.first?.state.item.name == "open.md")
        #expect(model.message == nil)
    }

    @Test func filesFoldersDedupPersistenceAndRemovalNeverChangeTargets() async throws {
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("file.md"), link = root.appendingPathComponent("alias.md")
        try Data("# QA".utf8).write(to: file)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        let store = QuickAccessStore(defaults: defaults)
        await store.add([root, file, file, link])
        #expect(store.entries.count == 2)
        #expect(store.entries.map(\.isDirectory) == [true, false])
        #expect(store.error == nil)
        let loaded = QuickAccessStore(defaults: defaults)
        await loaded.restore()
        #expect(loaded.entries == store.entries)
        let entry = try #require(loaded.entries.last)
        #expect(try await loaded.resolve(entry).url.resolvingSymlinksInPath() == file)
        loaded.remove(entry)
        #expect(loaded.entries.count == 1)
        #expect(try String(contentsOf: file, encoding: .utf8) == "# QA")
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted() == ["alias.md", "file.md"])
    }

    @Test func legacyFavoritesMigrateOnceIncludingUnavailableVolumes() async throws {
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(["/Volumes/Unavailable-QA/Folder", "/Volumes/Unavailable-QA/Folder"], forKey: "favorites")
        let store = QuickAccessStore(defaults: defaults)
        await store.restore()
        #expect(store.entries.count == 1)
        store.remove(try #require(store.entries.first))
        let reloaded = QuickAccessStore(defaults: defaults)
        await reloaded.restore()
        #expect(reloaded.entries.isEmpty, "Removing a migrated entry must not resurrect it on next launch")
    }

    @Test func unavailableTargetKeepsShortcutAndThrows() async throws {
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("removed.txt")
        try Data().write(to: file)
        let store = QuickAccessStore(defaults: defaults)
        await store.add([file])
        let entry = try #require(store.entries.first)
        try FileManager.default.removeItem(at: file)
        await #expect(throws: (any Error).self) { try await store.resolve(entry) }
        #expect(store.entries == [entry])
    }

    @Test func providerDropPinsWithoutCopyingOrMoving() async throws {
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("drag.txt")
        try Data("pin only".utf8).write(to: file)
        let model = BrowserModel(defaults: defaults)
        await model.receiveQuickAccessDrop([NSItemProvider(object: file as NSURL), NSItemProvider(object: root as NSURL)]).value
        #expect(model.quickAccess.entries.count == 2)
        #expect(model.operation == nil && model.taskHistory.isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["drag.txt"])
        #expect(try String(contentsOf: file, encoding: .utf8) == "pin only")
    }

    @Test func contextMenusCaptureRightDirectoryAndSelectedFiles() async throws {
        _ = NSApplication.shared
        let name = "MyFolds-Quick-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("menu.txt")
        try Data().write(to: file)
        let model = BrowserModel(defaults: defaults); model.split = true
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() } }
        model.right.navigate(root, hidden: false)
        for _ in 0..<100 where model.right.loading { try await Task.sleep(for: .milliseconds(10)) }
        let blank = FileMenuFactory.make(model: model, session: model.right, item: nil)
        let pinFolder = try #require(blank.item(withTitle: "添加当前位置到快速访问"))
        model.rightActive = false
        NSApp.sendAction(try #require(pinFolder.action), to: pinFolder.target, from: pinFolder)
        for _ in 0..<100 where model.quickAccess.entries.isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(model.quickAccess.entries.first?.path == root.resolvingSymlinksInPath().path)
        let menu = FileMenuFactory.make(model: model, session: model.right, item: try FileItem(url: file))
        let pinFile = try #require(menu.item(withTitle: "添加到快速访问"))
        model.right.selection = []; model.rightActive = false
        NSApp.sendAction(try #require(pinFile.action), to: pinFile.target, from: pinFile)
        for _ in 0..<100 where model.quickAccess.entries.count < 2 { try await Task.sleep(for: .milliseconds(10)) }
        #expect(model.quickAccess.entries.last?.path == file.resolvingSymlinksInPath().path)
        #expect(menu.items.filter { !$0.isSeparatorItem }.allSatisfy { $0.image != nil })
    }
}
