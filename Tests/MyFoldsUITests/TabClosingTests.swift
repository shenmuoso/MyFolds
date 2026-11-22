import AppKit
import Testing
@testable import MyFolds

@MainActor @Suite("Tab context actions", .serialized)
struct TabClosingTests {
    private func makeModel(_ defaults: UserDefaults) -> BrowserModel {
        defaults.set(["/tmp", "/Applications", "/System", "/Library"], forKey: "tabDirectories")
        defaults.set(["/Applications", "/System", "/Library"], forKey: "rightTabDirectories")
        defaults.set(true, forKey: "splitView")
        return BrowserModel(defaults: defaults)
    }

    @Test(arguments: [false, true])
    func closingOthersKeepsClickedTabAndOtherPane(isRight: Bool) throws {
        let domain = "MyFolds.close-tabs.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = makeModel(defaults)
        let original = isRight ? model.rightTabs : model.tabs
        let otherIDs = (isRight ? model.tabs : model.rightTabs).map(\.id)
        let kept = original[1]
        original.forEach { $0.pathEditor.begin($0.directory) }
        model.closeOtherTabs(kept.id, isRight: isRight)
        #expect((isRight ? model.rightTabs : model.tabs).map(\.id) == [kept.id])
        #expect(model.active.id == kept.id)
        #expect((isRight ? model.tabs : model.rightTabs).map(\.id) == otherIDs)
        #expect(original.filter { $0.id != kept.id }.allSatisfy { !$0.pathEditor.editing })
        let restored = BrowserModel(defaults: defaults)
        #expect((isRight ? restored.right : restored.primary).directory == kept.directory)
    }

    @Test(arguments: [false, true])
    func closingRightSelectsSurvivingNeighborAndIgnoresStaleID(isRight: Bool) throws {
        let domain = "MyFolds.close-right.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = makeModel(defaults)
        let original = isRight ? model.rightTabs : model.tabs
        model.selectTab(original.last!.id, isRight: isRight)
        model.closeTabsToRight(UUID(), isRight: isRight)
        #expect((isRight ? model.rightTabs : model.tabs).count == original.count)
        model.closeTabsToRight(original[1].id, isRight: isRight)
        #expect((isRight ? model.rightTabs : model.tabs).map(\.id) == original.prefix(2).map(\.id))
        #expect(model.active.id == original[1].id)
        model.closeTabsToRight(original[1].id, isRight: isRight)
        #expect((isRight ? model.rightTabs : model.tabs).count == 2)
    }

    @Test func closingAllRightTabsCollapsesAndRestoresOnlyOneLocation() throws {
        let domain = "MyFolds.close-all-right.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = makeModel(defaults)
        let leftIDs = model.tabs.map(\.id)
        model.selectTab(model.rightTabs[1].id, isRight: true)
        model.closeAllTabs(isRight: true)
        #expect(!model.split && !model.rightActive)
        #expect(model.tabs.map(\.id) == leftIDs)
        #expect(model.rightTabs.count == 1 && model.right.directory.path == "/System")
        let restored = BrowserModel(defaults: defaults)
        #expect(!restored.split && restored.rightTabs.count == 1)
    }

    @Test func closingAllLeftTabsClosesWindowWithoutEmptySession() async throws {
        _ = NSApplication.shared
        let domain = "MyFolds.close-all-left.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = makeModel(defaults)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 240, height: 160), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.identifier = .init("MyFolds.main")
        window.orderFront(nil)
        defer { window.close() }
        #expect(window.isVisible)
        model.closeAllTabs()
        let deadline = ContinuousClock.now + .seconds(1)
        while window.isVisible && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(!window.isVisible)
        #expect(model.tabs.count == 1)
        #expect(model.primary.id == model.selectedTabID)
        #expect(model.rightTabs.count == 3)
        #expect(BrowserModel(defaults: defaults).tabs.count == 1)
    }
}
