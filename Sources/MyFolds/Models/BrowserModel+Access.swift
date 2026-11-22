import Foundation

extension BrowserModel {
    func finishAccessOnboarding() { access.complete(); showsAccessOnboarding = false; refreshAll() }
    func openAccessSettings() { preferences.settingsSection = "文件访问"; openSettings() }
}
