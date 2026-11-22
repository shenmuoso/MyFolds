import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var browser: BrowserModel?
    private var terminating = false
    static func showAbout() {
        browser?.openAbout()
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let browser = Self.browser, browser.documentWindows.values.contains(where: { $0.state.document?.dirty == true }) else { return .terminateNow }
        guard !terminating else { return .terminateCancel }
        terminating = true
        Task {
            var allowed = true
            for controller in Array(browser.documentWindows.values) {
                if !(await controller.prepareClose()) { allowed = false; break }
            }
            terminating = false
            sender.reply(toApplicationShouldTerminate: allowed)
        }
        return .terminateLater
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let browser = Self.browser else { return }
        Task {
            for url in urls {
                do { browser.open(try await browser.directoryService.item(at: url)) }
                catch { browser.message = error.localizedDescription }
            }
        }
    }
}
