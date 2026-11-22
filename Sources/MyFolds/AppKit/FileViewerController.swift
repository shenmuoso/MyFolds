import SwiftUI
import MyFoldsCore

@MainActor
final class FileViewerController: NSWindowController, NSWindowDelegate {
    let state: FileViewerState
    private weak var browser: BrowserModel?
    private var closing = false
    private var prompting = false
    init(item: FileItem, kind: BuiltInViewer, browser: BrowserModel) {
        state = FileViewerState(item: item, kind: kind); self.browser = browser
        super.init(window: nil)
        let content = WindowMaterial(preferences: browser.preferences, identifier: "MyFolds.document." + UUID().uuidString, editorAppearance: kind.isEditable) {
            FileViewerView(state: state, preferences: browser.preferences, save: { [weak self] in self?.save() }, saveCopy: { [weak self] in self?.saveCopy() }, reload: { [weak self] in self?.reload() }, external: { [weak browser] in browser?.otherApplication(item) })
                .browserMotionPreference(browser.preferences)
                .appAccentPreference(browser.preferences)
        }
        let host = NSHostingController(rootView: content); host.safeAreaRegions = []; host.sizingOptions = []
        let window = EditorWindow(contentViewController: host)
        window.handleEditorShortcut = { [weak self] in self?.handleShortcut($0) ?? false }
        window.title = item.name; window.representedURL = item.url
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden; window.titlebarAppearsTransparent = true
        window.isOpaque = false; window.backgroundColor = .clear
        window.contentMinSize = NSSize(width: 620, height: 420)
        window.setContentSize(NSSize(width: kind == .markdown ? 1080 : 900, height: 660)); window.center()
        window.isReleasedWhenClosed = false; window.delegate = self
        self.window = window
        state.document?.onChange = { [weak self] in self?.window?.isDocumentEdited = self?.state.document?.dirty == true }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    func save() { Task { await state.document?.save() } }
    func saveCopy() {
        guard let document = state.document, let window else { return }
        let panel = NSSavePanel(); panel.nameFieldStringValue = state.item.name
        panel.directoryURL = state.item.url.deletingLastPathComponent()
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let destination = panel.url else { return }
            Task { @MainActor in
                if destination.standardizedFileURL == document.url.standardizedFileURL { await document.save(); return }
                do { try await document.saveCopy(to: destination) }
                catch { document.error = error.localizedDescription }
            }
        }
    }
    func reload() {
        Task {
            if state.document?.dirty == true, let window {
                let alert = NSAlert(); alert.messageText = "放弃未保存的编辑并重新载入？"
                alert.addButton(withTitle: "取消"); alert.addButton(withTitle: "重新载入")
                guard await alert.beginSheetModal(for: window) == .alertSecondButtonReturn else { return }
            }
            await state.document?.load()
        }
    }
    func prepareClose() async -> Bool {
        guard let document = state.document, document.dirty else { return true }
        guard !prompting, !document.saving, let window else { return false }
        prompting = true; defer { prompting = false }
        window.makeKeyAndOrderFront(nil)
        let alert = NSAlert(); alert.messageText = "要保存对“\(state.item.name)”的更改吗？"
        alert.informativeText = "未保存的更改将丢失。"
        alert.addButton(withTitle: "保存"); alert.addButton(withTitle: "取消"); alert.addButton(withTitle: "不保存")
        switch await alert.beginSheetModal(for: window) {
        case .alertFirstButtonReturn: return await document.save() && !document.dirty
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if closing || state.document?.dirty != true { return true }
        Task { if await prepareClose() { closing = true; sender.performClose(nil) } }
        return false
    }
    func windowDidBecomeKey(_ notification: Notification) { browser?.activeTextViewer = state.document == nil ? nil : state }
    func windowDidResignKey(_ notification: Notification) {
        if browser?.activeTextViewer === state { browser?.activeTextViewer = nil }
    }
    private func handleShortcut(_ event: NSEvent) -> Bool {
        guard let document = state.document, let preferences = browser?.preferences else { return false }
        if preferences.editor.findShortcut.matches(event) { state.openSearch(replace: false); return true }
        if preferences.editor.replaceShortcut.matches(event) { state.openSearch(replace: true); return true }
        if document.search.visible, event.keyCode == 53, (window?.firstResponder as? NSTextView)?.hasMarkedText() != true {
            document.search.close(); return true
        }
        if document.search.visible, event.charactersIgnoringModifiers?.lowercased() == "g", event.modifierFlags.intersection([.command, .control, .option]) == .command {
            document.search.navigate(backward: event.modifierFlags.contains(.shift)); return true
        }
        return false
    }
    func windowWillClose(_ notification: Notification) {
        state.document?.search.cancel()
        if browser?.activeTextViewer === state { browser?.activeTextViewer = nil }
        browser?.documentWindows.removeValue(forKey: state.item.url)
    }
}
