import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Trash navigation and access state", .serialized)
struct TrashAndPermissionTests {
    @Test func onboardingDoesNotGrantAccessAndRecheckingReflectsRevocation() async throws {
        let name = "MyFolds-Access-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let probe = AccessProbeSequence()
        let access = FileAccessManager(defaults: defaults, probe: { await probe.next() })
        #expect(access.needsDiskAccess)
        access.complete()
        await access.refreshDiskAccess()
        #expect(access.onboardingComplete && access.needsDiskAccess)
        await access.refreshDiskAccess()
        #expect(!access.needsDiskAccess)
        await access.refreshDiskAccess()
        #expect(access.needsDiskAccess)
    }

    @Test func trashUsesActivePaneAndDisablesOrdinaryDestinationMutations() async throws {
        _ = NSApplication.shared
        let name = "MyFolds-Trash-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = BrowserModel(defaults: defaults)
        let fake = FolderSession(directory: URL(fileURLWithPath: "/tmp")) { _, _ in [] }
        model.rightTabs = [fake]; model.selectedRightTabID = fake.id
        model.split = true; model.rightActive = true
        let leftDirectory = model.primary.directory
        model.openTrash()
        #expect(model.active === fake)
        #expect(fake.directory == TrashLocation.root)
        #expect(fake.displayName == "废纸篓" && fake.isInTrash)
        #expect(model.primary.directory == leftDirectory)
        for _ in 0..<100 where fake.loading { try await Task.sleep(for: .milliseconds(5)) }
        #expect(fake.error == nil && fake.visible.isEmpty)
        #expect(!model.canEditFiles)
        let menu = FileMenuFactory.make(model: model, session: fake, item: nil)
        #expect(menu.item(withTitle: "新建文件夹…")?.isEnabled == false)
        #expect(menu.item(withTitle: "粘贴")?.isEnabled == false)
        #expect(model.receiveDrop([], to: TrashLocation.root) == nil)
        fake.cancelWork()
    }

    @Test func trashContainmentUsesPathBoundaries() {
        #expect(TrashLocation.contains(TrashLocation.root.appendingPathComponent("Folder/file.txt")))
        #expect(!TrashLocation.contains(URL(fileURLWithPath: TrashLocation.root.path + "-backup")))
    }
}

private actor AccessProbeSequence {
    private var statuses: [DiskAccessStatus] = [.restricted, .available, .restricted]
    func next() -> DiskAccessStatus { statuses.removeFirst() }
}
