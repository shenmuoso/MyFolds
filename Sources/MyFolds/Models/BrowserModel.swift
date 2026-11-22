import SwiftUI
import MyFoldsCore
import UniformTypeIdentifiers

@MainActor @Observable
final class BrowserModel {
    let preferences: Preferences
    let quickAccess: QuickAccessStore
    @ObservationIgnored private let defaults: UserDefaults
    var tabs: [FolderSession]
    var selectedTabID: UUID
    var rightTabs: [FolderSession]
    var selectedRightTabID: UUID
    private var rightInitialized: Bool
    var split = false
    var rightActive = false
    var sidebarVisible = true
    var inspector = false
    var searchFocused = false
    var message: String?
    var busy = false
    var taskTitle = ""
    var taskDetail = ""
    var taskProgress = 0.0
    var taskHistory: [String] = []
    var showsTasks = false
    var cutURLs: Set<URL> = []
    var clipboardCount = 0
    var undoStack: [[OperationReceipt]] = []
    var volumes: [MountedVolume] = []
    var ejectingVolumes: Set<String> = []
    var preview: PreviewModel?
    let access: FileAccessManager
    var showsAccessOnboarding = false
    @ObservationIgnored private var checkedStartupAccess = false
    @ObservationIgnored let directoryService = DirectoryService()
    @ObservationIgnored let diskImages = DiskImageService()
    @ObservationIgnored let volumeService = VolumeService()
    @ObservationIgnored private var volumeRefresh: Task<Void, Never>?
    @ObservationIgnored var documentWindows: [URL: FileViewerController] = [:]
    var activeTextViewer: FileViewerState?
    #if DEBUG
    @ObservationIgnored var materialBackdrop: NSWindow?
    @ObservationIgnored var materialProbe: NSWindow?
    #endif
    @ObservationIgnored var settingsWindow: NSWindow?
    @ObservationIgnored var aboutWindow: NSWindow?
    @ObservationIgnored var previewDelegate: PreviewWindowDelegate?
    @ObservationIgnored var previewWindow: NSWindow?
    @ObservationIgnored var operation: Task<Void, Never>?
    @ObservationIgnored let operations = FileOperations()
    @ObservationIgnored var applyConflict: ConflictDecision?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = Preferences(defaults: defaults)
        access = FileAccessManager(defaults: defaults)
        quickAccess = QuickAccessStore(defaults: defaults)
        let saved = defaults.stringArray(forKey: "tabDirectories") ?? []
        let restored = saved.map { FolderSession(directory: URL(fileURLWithPath: $0)) }
        let first = restored.first ?? FolderSession(directory: .homeDirectory)
        let leftSessions = restored.isEmpty ? [first] : restored
        tabs = leftSessions
        selectedTabID = leftSessions[min(max(0, defaults.integer(forKey: "selectedTabIndex")), leftSessions.count - 1)].id
        let rightSaved = defaults.stringArray(forKey: "rightTabDirectories") ?? []
        let rightSessions = rightSaved.isEmpty ? [FolderSession(directory: first.directory)] : rightSaved.map { FolderSession(directory: URL(fileURLWithPath: $0)) }
        rightTabs = rightSessions
        selectedRightTabID = rightSessions[min(max(0, defaults.integer(forKey: "selectedRightTabIndex")), rightSessions.count - 1)].id
        rightInitialized = !rightSaved.isEmpty
        split = defaults.bool(forKey: "splitView")
    }
    var primary: FolderSession { tabs.first { $0.id == selectedTabID } ?? tabs[0] }
    var right: FolderSession { rightTabs.first { $0.id == selectedRightTabID } ?? rightTabs[0] }
    var active: FolderSession { split && rightActive ? right : primary }
    var selected: [FileItem] { active.archive == nil ? active.selected : [] }
    var canEditFiles: Bool { !busy && !active.loading && active.archive == nil && !active.isInTrash }
    var fileWindowIsKey: Bool { NSApp.keyWindow?.identifier?.rawValue == "MyFolds.main" }
    var pathLabel: String { active.archive.map { $0.url.path + "  ›  /" + $0.folder } ?? active.directory.path }

    func start() async {
        refreshVolumes()
        await access.restore()
        await access.refreshDiskAccess()
        await quickAccess.restore()
        if !checkedStartupAccess {
            checkedStartupAccess = true
            showsAccessOnboarding = access.shouldPromptAtLaunch
        }
        refreshAll()
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            clipboardCount = NSPasteboard.general.changeCount
            if clipboardCount != cutChangeCount { cutURLs = [] }
            if !busy && !showsAccessOnboarding && NSApp.isActive { active.reload(hidden: preferences.showHidden) }
        }
    }
    func refreshAll() {
        for tab in tabs + (split ? rightTabs : []) { tab.reload(hidden: preferences.showHidden) }
    }
    @discardableResult
    func refreshVolumes() -> Task<Void, Never> {
        volumeRefresh?.cancel()
        let task = Task {
            let snapshot = await volumeService.snapshot()
            guard !Task.isCancelled else { return }
            volumes = snapshot
        }
        volumeRefresh = task
        return task
    }
    func saveSession() {
        defaults.set(tabs.map { $0.directory.path }, forKey: "tabDirectories")
        if rightInitialized { defaults.set(rightTabs.map { $0.directory.path }, forKey: "rightTabDirectories") }
        defaults.set(tabs.firstIndex { $0.id == selectedTabID } ?? 0, forKey: "selectedTabIndex")
        defaults.set(rightTabs.firstIndex { $0.id == selectedRightTabID } ?? 0, forKey: "selectedRightTabIndex")
        defaults.set(split, forKey: "splitView")
    }
    func go(_ url: URL, session: FolderSession? = nil) {
        let target = session ?? active
        target.navigationTask?.cancel()
        let request = UUID(); target.navigationRequest = request; target.resolving = true
        target.navigationTask = Task {
            defer { if target.navigationRequest == request { target.resolving = false } }
            do {
                let item = try await directoryService.item(at: url)
                try Task.checkCancellation()
                if item.isDirectory { target.navigate(item.directoryTarget ?? url, hidden: preferences.showHidden) }
                else {
                    target.navigate(url.deletingLastPathComponent(), hidden: preferences.showHidden)
                    target.selection = [url.standardizedFileURL]
                }
                saveSession()
            } catch is CancellationError { }
            catch { message = "无法访问 \(url.path)\n\(error.localizedDescription)" }
        }
    }
    func chooseDirectory() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.prompt = "打开文件夹"
        if panel.runModal() == .OK, let url = panel.url {
            Task { await access.remember(url); go(url) }
        }
    }
    func addTab() { addTab(isRight: split && rightActive) }
    func addTab(isRight: Bool, directory: URL? = nil) {
        let source = isRight ? right : primary
        let tab = FolderSession(directory: directory ?? source.directory)
        if isRight { rightTabs.append(tab); selectedRightTabID = tab.id; rightInitialized = true }
        else { tabs.append(tab); selectedTabID = tab.id }
        rightActive = isRight; tab.reload(hidden: preferences.showHidden); saveSession()
    }
    func selectTab(_ id: UUID, isRight: Bool = false) {
        let paneTabs = isRight ? rightTabs : tabs
        guard paneTabs.contains(where: { $0.id == id }) else { return }
        (isRight ? right : primary).pathEditor.cancel()
        if isRight { selectedRightTabID = id } else { selectedTabID = id }
        rightActive = isRight; saveSession()
    }
    func closeTab(_ id: UUID, isRight: Bool = false) {
        closeTabs([id], isRight: isRight)
    }
    func closeCurrentTabOrWindow() {
        if fileWindowIsKey { closeTab(active.id, isRight: split && rightActive) }
        else { NSApp.keyWindow?.performClose(nil) }
    }
    func cycleTab(_ delta: Int) {
        guard fileWindowIsKey else { return }
        let isRight = split && rightActive, paneTabs = isRight ? rightTabs : tabs
        guard let index = paneTabs.firstIndex(where: { $0.id == active.id }) else { return }
        selectTab(paneTabs[(index + delta % paneTabs.count + paneTabs.count) % paneTabs.count].id, isRight: isRight)
    }
    func toggleSplit() {
        split.toggle(); rightActive = false
        if split {
            if !rightInitialized { right.navigate(primary.directory, hidden: preferences.showHidden); rightInitialized = true }
            else { for tab in rightTabs { tab.reload(hidden: preferences.showHidden) } }
        }
        saveSession()
    }
    func openTrash() {
        active.navigate(TrashLocation.root, hidden: preferences.showHidden)
        saveSession()
    }
    func up() {
        guard fileWindowIsKey else { return }
        if active.archive != nil { active.back(hidden: preferences.showHidden) }
        else { go(active.directory.deletingLastPathComponent()) }
    }
    func editPath() {
        guard fileWindowIsKey else { return }
        active.pathEditor.begin(active.archive?.url ?? active.directory)
    }
    func copyPath() {
        guard fileWindowIsKey else { return }
        let paths = selected.isEmpty ? [active.directory.path] : selected.map { $0.url.path }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
        cutURLs = []
    }
    @ObservationIgnored private var cutChangeCount = -1
    func copy(cut: Bool = false) {
        if sendTextAction(cut ? #selector(NSText.cut(_:)) : #selector(NSText.copy(_:))) { return }
        guard fileWindowIsKey, !selected.isEmpty, !busy, !cut || canEditFiles else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.writeObjects(selected.map { $0.url as NSURL })
        cutURLs = cut ? Set(selected.map(\.url)) : []
        cutChangeCount = NSPasteboard.general.changeCount; clipboardCount = cutChangeCount
    }
    func sendTextAction(_ action: Selector) -> Bool {
        guard NSApp.keyWindow?.firstResponder is NSTextView else { return false }
        NSApp.sendAction(action, to: nil, from: nil); return true
    }
    func paste() {
        if sendTextAction(#selector(NSText.paste(_:))) { return }
        guard fileWindowIsKey, canEditFiles else { return }
        let urls = (NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        guard !urls.isEmpty else { return }
        transfer(urls, to: active.directory, move: NSPasteboard.general.changeCount == cutChangeCount && !cutURLs.isEmpty)
    }
    func transfer(_ urls: [URL], to destination: URL, move: Bool) {
        guard !busy, !TrashLocation.contains(destination) else { return }
        busy = true; applyConflict = nil; taskProgress = 0; taskTitle = move ? "正在移动" : "正在复制"
        operation = Task {
            let result = await operations.transfer(urls, to: destination, move: move, conflict: { source, target, directory in
                let targetIsDirectory = (try? await self.directoryService.item(at: target).isDirectory) == true
                return await MainActor.run { self.askConflict(source: source, target: target, directory: directory || targetIsDirectory) }
            }, progress: { name, done, total in
                await MainActor.run { self.taskDetail = name; self.taskProgress = Double(done) / Double(max(total, 1)) }
            })
            if !result.receipts.isEmpty { undoStack.append(result.receipts) }
            let summary = "\(move ? "移动" : "复制")：完成 \(result.receipts.count) 项，跳过 \(result.skipped) 项" + (result.cancelled ? "，已取消" : "")
            taskHistory.insert(summary + (result.failures.isEmpty ? "" : "\n" + result.failures.joined(separator: "\n")), at: 0)
            taskTitle = summary; busy = false
            if !result.failures.isEmpty { message = result.failures.joined(separator: "\n") }
            cutURLs.subtract(result.receipts.compactMap(\.source)); refreshAll()
        }
    }
    private func askConflict(source: URL, target: URL, directory: Bool) -> ConflictDecision {
        if let applyConflict, !(directory && applyConflict == .replace) { return applyConflict }
        let alert = NSAlert(); alert.messageText = "“\(target.lastPathComponent)”已存在"
        alert.informativeText = "来源：\(source.path)\n目标：\(target.path)"
        alert.addButton(withTitle: "保留两份"); alert.addButton(withTitle: "跳过"); alert.addButton(withTitle: "取消任务")
        if !directory { alert.addButton(withTitle: "替换文件") }
        let checkbox = NSButton(checkboxWithTitle: "应用到本任务剩余同名项", target: nil, action: nil)
        alert.accessoryView = checkbox
        let response = alert.runModal()
        let decision: ConflictDecision = response.rawValue == 1000 ? .keepBoth : response.rawValue == 1001 ? .skip : response.rawValue == 1003 ? .replace : .cancel
        if checkbox.state == .on && decision != .cancel { applyConflict = decision }
        return decision
    }
    func cancelTask() { operation?.cancel() }
    func requestName(rename: Bool) {
        guard fileWindowIsKey, canEditFiles, !rename || selected.count == 1 else { return }
        let source = selected.first?.url
        let alert = NSAlert(); alert.messageText = rename ? "重命名" : "新建文件夹"
        let field = NSTextField(string: rename ? source?.lastPathComponent ?? "" : "未命名文件夹")
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)
        alert.accessoryView = field; alert.addButton(withTitle: "确定"); alert.addButton(withTitle: "取消")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue; let directory = active.directory
        runSimple(title: rename ? "重命名" : "新建文件夹") {
            if rename, let source { return [try await self.operations.rename(source, to: name)] }
            return [try await self.operations.createFolder(in: directory, name: name)]
        }
    }
    func trashSelected() {
        let urls = selected.map(\.url); guard fileWindowIsKey, canEditFiles, !urls.isEmpty else { return }
        guard !busy else { return }
        busy = true; taskTitle = "移到废纸篓"; taskDetail = ""; taskProgress = 0
        operation = Task {
            let result = await operations.trash(urls)
            if !result.receipts.isEmpty { undoStack.append(result.receipts) }
            taskTitle = "已移到废纸篓 \(result.receipts.count) 项"
            if !result.failures.isEmpty { message = result.failures.joined(separator: "\n") }
            taskHistory.insert(taskTitle + (message.map { "\n" + $0 } ?? ""), at: 0)
            busy = false; refreshAll()
        }
    }
    func duplicate() { guard fileWindowIsKey, canEditFiles else { return }; transfer(selected.map(\.url), to: active.directory, move: false) }
    func undo() {
        if let editor = NSApp.keyWindow?.firstResponder as? NSTextView { editor.undoManager?.undo(); return }
        guard fileWindowIsKey, !busy, let receipt = undoStack.last else { return }
        busy = true
        operation = Task {
            do { try await operations.undo(receipt); undoStack.removeLast(); taskTitle = "已撤销"; refreshAll() }
            catch { message = error.localizedDescription }
            busy = false
        }
    }
    func runSimple(title: String, action: @escaping @MainActor () async throws -> [OperationReceipt]) {
        guard !busy else { return }
        busy = true; taskTitle = title; taskDetail = ""; taskProgress = 0
        operation = Task {
            do { let receipts = try await action(); if !receipts.isEmpty { undoStack.append(receipts) }; taskTitle = "\(title)完成"; taskHistory.insert(taskTitle, at: 0) }
            catch is CancellationError { taskTitle = "\(title)已取消"; taskHistory.insert(taskTitle, at: 0) }
            catch { message = error.localizedDescription; taskHistory.insert("\(title)：\(error.localizedDescription)", at: 0) }
            busy = false; refreshAll()
        }
    }
    func open(_ item: FileItem, session: FolderSession? = nil) {
        let target = session ?? active
        if item.isDirectory {
            target.navigate(item.directoryTarget ?? item.url, hidden: preferences.showHidden); saveSession()
        } else if preferences.openingDestination(for: item) == .system { openExternally(item, useSystemDefault: true) }
        else if preferences.applicationPath(for: item) != nil { openExternally(item) }
        else if item.url.pathExtension.lowercased() == "dmg" { mountImage(item.url, session: target) }
        else if BuiltInViewer.matching(item) != nil { openBuiltIn(item) }
        else if item.isArchive {
            let archive = ArchiveState(url: item.url); target.archive = archive; target.selection = []
            Task { await archive.load() }
        } else if preferences.openingDestination(for: item) == .builtIn {
            message = "此格式暂不支持内置查看。请在打开方式中选择其他应用。"
        } else { openExternally(item) }
    }
    func mountImage(_ url: URL, session: FolderSession? = nil) {
        guard !busy else { return }
        let target = session ?? active
        busy = true; taskTitle = "正在挂载磁盘映像"; taskDetail = url.lastPathComponent; taskProgress = 0
        operation = Task {
            do {
                let mounted = try await diskImages.mount(url)
                try Task.checkCancellation()
                if let first = mounted.first { target.navigate(first, hidden: preferences.showHidden); saveSession() }
                await refreshVolumes().value
                taskHistory.insert("已挂载：" + url.lastPathComponent, at: 0)
            } catch is CancellationError { taskHistory.insert("已取消挂载", at: 0) }
            catch { message = error.localizedDescription }
            busy = false
        }
    }
    func openSelected() { guard fileWindowIsKey else { return }; if let item = selected.first { open(item) } }
    func applications(for item: FileItem) -> [URL] { NSWorkspace.shared.urlsForApplications(toOpen: item.url) }
    func openExternally(_ item: FileItem, application: URL? = nil, useSystemDefault: Bool = false) {
        let app = useSystemDefault ? nil : (application ?? preferences.applicationPath(for: item).map { URL(fileURLWithPath: $0) })
        if let app {
            guard FileManager.default.fileExists(atPath: app.path) else { message = "默认应用已不可用。请在打开方式中重新选择，或清除此类型规则。"; return }
            NSWorkspace.shared.open([item.url], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error { Task { @MainActor in self.message = error.localizedDescription } }
            }
        } else if !NSWorkspace.shared.open(item.url) { message = "无法打开此文件，请选择其他应用。" }
    }
    func otherApplication(_ item: FileItem, remember: Bool = false) {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]; panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url {
            if remember { preferences.rememberApplication(url, for: item) }
            else { openExternally(item, application: url) }
        }
    }
    func favorite() { addQuickAccess([active.directory]) }
    func addQuickAccess(_ urls: [URL]) {
        Task { await quickAccess.add(urls); if let error = quickAccess.error { message = error } }
    }
    @discardableResult
    func openQuickAccess(_ entry: QuickAccessEntry) -> Task<Void, Never> {
        let target = active
        target.navigationTask?.cancel()
        let request = UUID(); target.navigationRequest = request; target.resolving = true
        let task = Task {
            defer { if target.navigationRequest == request { target.resolving = false } }
            do {
                let item = try await quickAccess.resolve(entry)
                try Task.checkCancellation()
                guard target.navigationRequest == request else { return }
                if item.isDirectory { target.navigate(item.directoryTarget ?? item.url, hidden: preferences.showHidden); saveSession() }
                else { open(item, session: target) }
            } catch is CancellationError { }
            catch { message = "快速访问项目不可用：\(entry.name)\n\(error.localizedDescription)" }
        }
        target.navigationTask = task
        return task
    }
    func createZIP() {
        let urls = selected.map(\.url); guard fileWindowIsKey, canEditFiles, !urls.isEmpty else { return }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.zip]; panel.nameFieldStringValue = urls.count == 1 ? urls[0].deletingPathExtension().lastPathComponent + ".zip" : "归档.zip"
        panel.directoryURL = active.directory
        if panel.runModal() == .OK, let target = panel.url {
            runSimple(title: "创建 ZIP") { try await ArchiveService().createZIP(urls, at: target); return [try OperationReceipt(kind: .create, source: nil, destination: target)] }
        }
    }
    func extractArchive(_ archive: ArchiveState) {
        guard !busy else { return }
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.directoryURL = archive.url.deletingLastPathComponent(); panel.prompt = "解压到这里"
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        let selected = archive.selection
        runSimple(title: "解压") {
            let target = try await ArchiveService().extract(archive.url, selected: selected, to: destination) { name in await MainActor.run { self.taskDetail = name } }
            self.go(target)
            return [try OperationReceipt(kind: .create, source: nil, destination: target)]
        }
    }
}
