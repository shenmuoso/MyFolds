import Foundation
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Startup disk access reminder", .serialized)
struct StartupAccessTests {
    @Test func deniedAccessPromptsOnEveryLaunchUntilSuppressed() async throws {
        let name = "MyFolds.StartupAccess." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let access = FileAccessManager(defaults: defaults, probe: { .restricted })
        await access.refreshDiskAccess()
        #expect(access.shouldPromptAtLaunch)
        access.complete()
        let relaunched = FileAccessManager(defaults: defaults, probe: { .restricted })
        await relaunched.refreshDiskAccess()
        #expect(relaunched.shouldPromptAtLaunch)
        relaunched.suppressDiskAccessReminder = true
        let suppressed = FileAccessManager(defaults: defaults, probe: { .restricted })
        await suppressed.refreshDiskAccess()
        #expect(!suppressed.shouldPromptAtLaunch && suppressed.needsDiskAccess)
        suppressed.remindDiskAccessAtLaunch = true
        #expect(suppressed.shouldPromptAtLaunch)
        #expect(!FileAccessManager(defaults: defaults).suppressDiskAccessReminder)
    }
    @Test func grantedAccessSkipsPromptAndUnknownDoesNotPretendAuthorized() async throws {
        let name = "MyFolds.GrantedAccess." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let access = FileAccessManager(defaults: defaults, probe: { .available })
        await access.refreshDiskAccess()
        #expect(!access.shouldPromptAtLaunch && !access.needsDiskAccess)
        let unknown = FileAccessManager(defaults: defaults, probe: { .unknown })
        await unknown.refreshDiskAccess()
        #expect(unknown.shouldPromptAtLaunch)
    }
}
