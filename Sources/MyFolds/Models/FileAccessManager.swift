import AppKit
import Observation
import MyFoldsCore

@MainActor @Observable
final class FileAccessManager {
    var onboardingComplete: Bool
    var suppressDiskAccessReminder: Bool {
        didSet { defaults.set(suppressDiskAccessReminder, forKey: "suppressDiskAccessReminder") }
    }
    var shouldPromptAtLaunch: Bool { needsDiskAccess && !suppressDiskAccessReminder }
    var remindDiskAccessAtLaunch: Bool {
        get { !suppressDiskAccessReminder }
        set { suppressDiskAccessReminder = !newValue }
    }
    var diskAccess: DiskAccessStatus = .unknown
    var needsDiskAccess: Bool { diskAccess != .available }
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let probe: @Sendable () async -> DiskAccessStatus
    @ObservationIgnored private var checkingAccess = false
    init(defaults: UserDefaults = .standard, probe: @escaping @Sendable () async -> DiskAccessStatus = { await DiskAccessProbe.check() }) {
        self.defaults = defaults; self.probe = probe
        suppressDiskAccessReminder = defaults.bool(forKey: "suppressDiskAccessReminder")
        onboardingComplete = defaults.bool(forKey: "fileAccessOnboardingComplete")
    }
    func refreshDiskAccess() async {
        guard !checkingAccess else { return }; checkingAccess = true
        diskAccess = await probe(); checkingAccess = false
    }
    var authorizedPaths: [String] = []
    var message: String?
    @ObservationIgnored private var scoped: [URL] = []
    @ObservationIgnored private var restored = false
    func restore() async {
        guard !restored else { return }; restored = true
        let data = defaults.array(forKey: "authorizedDirectoryBookmarks") as? [Data] ?? []
        let resolved = await DirectoryBookmarks.resolve(data)
        for url in resolved {
            if url.startAccessingSecurityScopedResource() { scoped.append(url) }
            authorizedPaths.append(url.path)
        }
        if resolved.count != data.count { message = "部分目录授权已失效，请重新选择这些目录。" }
    }
    func remember(_ url: URL) async {
        if url.startAccessingSecurityScopedResource() { scoped.append(url) }
        do {
            let data = try await DirectoryBookmarks.create(url)
            var saved = defaults.array(forKey: "authorizedDirectoryBookmarks") as? [Data] ?? []
            if !authorizedPaths.contains(url.path) {
                saved.append(data); authorizedPaths.append(url.path)
                defaults.set(saved, forKey: "authorizedDirectoryBookmarks")
            }
        } catch { message = "目录已打开，但未能保存长期授权：" + error.localizedDescription }
    }
    func chooseRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = true
        panel.directoryURL = .homeDirectory; panel.prompt = "授予访问权限"
        panel.message = "建议选择个人文件夹及常用外置磁盘。MyFolds 会记住这些目录。"
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        Task { for url in urls { await remember(url) } }
    }
    func openFullDiskAccess() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }
    func complete() {
        onboardingComplete = true
        defaults.set(true, forKey: "fileAccessOnboardingComplete")
    }
}

enum DirectoryBookmarks {
    @concurrent static func create(_ url: URL) async throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }
    @concurrent static func resolve(_ bookmarks: [Data]) async -> [URL] {
        bookmarks.compactMap { data in
            var stale = false
            return try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
        }
    }
}
