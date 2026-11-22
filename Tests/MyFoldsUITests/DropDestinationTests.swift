import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Folder and tab drop destinations", .serialized)
struct DropDestinationTests {
    @Test func applicationBundleCopiesThroughDiskImageApplicationsLink() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let image = root.appendingPathComponent("Image"), applications = root.appendingPathComponent("Applications")
        let bundle = image.appendingPathComponent("Example.app"), contents = bundle.appendingPathComponent("Contents/MacOS")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: applications, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = contents.appendingPathComponent("Example")
        try Data("test application executable".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let link = image.appendingPathComponent("Applications")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: applications)
        let item = try FileItem(url: link)
        #expect(item.isDirectory && item.isSymbolicLink)
        #expect(item.directoryTarget == applications.resolvingSymlinksInPath())
        #expect(try FileItem(url: bundle).directoryTarget == nil)
        let name = "MyFolds.DropTargets." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = BrowserModel(defaults: defaults)
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() } }
        await model.receiveDrop([NSItemProvider(object: bundle as NSURL)], to: link)?.value
        await model.operation?.value
        let installed = applications.appendingPathComponent("Example.app/Contents/MacOS/Example")
        #expect(try Data(contentsOf: installed) == Data(contentsOf: executable))
        #expect(try FileManager.default.attributesOfItem(atPath: installed.path)[.posixPermissions] as? Int == 0o755)
        #expect(FileManager.default.fileExists(atPath: executable.path))
        #expect(model.message == nil)
        model.open(item)
        #expect(model.active.directory == applications.resolvingSymlinksInPath())
    }

    @Test func finderAliasIsADirectoryTargetButBrokenLinkIsNot() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let folder = root.appendingPathComponent("Folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let alias = root.appendingPathComponent("Folder alias")
        let bookmark = try folder.bookmarkData(options: [.suitableForBookmarkFile], includingResourceValuesForKeys: nil, relativeTo: nil)
        try URL.writeBookmarkData(bookmark, to: alias)
        #expect(try FileItem(url: alias).directoryTarget == folder.resolvingSymlinksInPath())
        let broken = root.appendingPathComponent("Broken")
        try FileManager.default.createSymbolicLink(at: broken, withDestinationURL: root.appendingPathComponent("Missing"))
        #expect(try FileItem(url: broken).directoryTarget == nil)
    }

    @Test func droppingIntoInactiveTabUsesItsDirectoryAndRejectsTrash() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let source = root.appendingPathComponent("Source"), target = root.appendingPathComponent("Target")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = source.appendingPathComponent("file.txt")
        try Data("tab destination".utf8).write(to: file)
        let name = "MyFolds.TabDrop." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = BrowserModel(defaults: defaults)
        let left = FolderSession(directory: source), right = FolderSession(directory: target)
        model.tabs = [left]; model.selectedTabID = left.id
        model.rightTabs = [right]; model.selectedRightTabID = right.id
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() } }
        let providers = [NSItemProvider(object: file as NSURL)]
        await model.receiveDrop(providers, to: right)?.value
        await model.operation?.value
        #expect(try Data(contentsOf: target.appendingPathComponent("file.txt")) == Data(contentsOf: file))
        #expect(model.active === left)
        #expect(model.receiveDrop(providers, to: FolderSession(directory: TrashLocation.root)) == nil)
        let count = model.taskHistory.count
        await model.receiveDrop(providers, to: source)?.value
        #expect(model.taskHistory.count == count)
    }
}
