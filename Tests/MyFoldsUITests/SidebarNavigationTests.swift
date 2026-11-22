import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Sidebar navigation", .serialized)
struct SidebarNavigationTests {
    @Test func newTabsAndOtherPaneUseTheMenuTarget() async throws {
        let name = "MyFolds.sidebar." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: root) }
        let model = BrowserModel(defaults: defaults), original = model.primary.directory
        await model.openSidebar(root, target: .newTab).value
        #expect(model.tabs.count == 2 && model.primary.directory.standardizedFileURL.path == root.standardizedFileURL.path)
        #expect(model.tabs.first?.directory == original)
        await model.openSidebar(root, target: .otherPane).value
        #expect(model.split && model.rightActive && model.right.directory.standardizedFileURL.path == root.standardizedFileURL.path)
        let file = root.appendingPathComponent("notes.md"); try Data("# test".utf8).write(to: file)
        await model.quickAccess.add([file])
        let entry = try #require(model.quickAccess.entries.first)
        await model.openSidebar(file, entry: entry, target: .newTab).value
        #expect(model.rightTabs.count == 2 && model.right.directory.standardizedFileURL.path == root.standardizedFileURL.path)
        #expect(model.right.selection == [file])
        for tab in model.tabs + model.rightTabs { tab.cancelWork() }
    }
    @Test func realDisksCannotUseImageEjection() async {
        let service = DiskImageService()
        do {
            try await service.eject(MountedVolume(url: URL(fileURLWithPath: "/"), name: "System"))
            Issue.record("Only known mounted images can be ejected")
        } catch { #expect(error.localizedDescription.contains("不是已挂载")) }
    }
}
