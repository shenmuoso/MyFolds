import AppKit
import Testing
@testable import MyFolds

@MainActor @Suite("Independent pane tabs", .serialized)
struct PaneTabsTests {
    @Test func independentSelectionCloseAndPersistence() throws {
        let name = "MyFolds-Panes-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(["/tmp", "/Applications"], forKey: "tabDirectories")
        defaults.set(["/System", "/Library"], forKey: "rightTabDirectories")
        let model = BrowserModel(defaults: defaults)
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() } }
        model.toggleSplit()
        model.selectTab(model.tabs[1].id)
        let left = model.selectedTabID
        model.selectTab(model.rightTabs[1].id, isRight: true)
        #expect(model.selectedTabID == left)
        #expect(model.active.directory.path == "/Library")
        model.addTab(isRight: true)
        #expect(model.tabs.count == 2 && model.rightTabs.count == 3)
        #expect(model.right.directory.path == "/Library")
        model.closeTab(model.rightTabs[1].id, isRight: true)
        #expect(model.rightTabs.count == 2 && model.selectedTabID == left)
        model.saveSession()
        let restored = BrowserModel(defaults: defaults)
        #expect(restored.split)
        #expect(restored.primary.directory.path == "/Applications")
        #expect(restored.right.directory.path == "/Library")
        #expect(restored.rightTabs.map { $0.directory.path } == ["/System", "/Library"])
        #expect(restored.tabs.map { $0.directory.path } == ["/tmp", "/Applications"])
    }

    @Test func lastRightTabCollapsesAndReopensSameLocation() throws {
        let name = "MyFolds-Panes-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(["/tmp"], forKey: "tabDirectories")
        let model = BrowserModel(defaults: defaults)
        defer { for tab in model.tabs + model.rightTabs { tab.cancelWork() } }
        model.toggleSplit()
        model.right.navigate(URL(fileURLWithPath: "/Applications"), hidden: false)
        let rightID = model.right.id
        model.closeTab(rightID, isRight: true)
        #expect(!model.split && !model.rightActive)
        #expect(model.tabs.count == 1 && model.rightTabs.count == 1)
        model.toggleSplit()
        #expect(model.right.id == rightID)
        #expect(model.right.directory.path == "/Applications")
        #expect(model.primary.directory.path == "/tmp")
    }
}
