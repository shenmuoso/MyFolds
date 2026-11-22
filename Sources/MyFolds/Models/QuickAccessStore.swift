import Foundation
import Observation
import MyFoldsCore

@MainActor @Observable
final class QuickAccessStore {
    private(set) var entries: [QuickAccessEntry]
    private(set) var error: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var restored = false
    @ObservationIgnored private var scoped: [UUID: URL] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = defaults.data(forKey: "quickAccessEntries").flatMap {
            try? JSONDecoder().decode([QuickAccessEntry].self, from: $0)
        } ?? []
    }

    func restore() async {
        guard !restored else { return }; restored = true
        guard defaults.data(forKey: "quickAccessEntries") == nil else { return }
        // Preserve unavailable legacy locations too; they may be on an unmounted disk.
        for path in defaults.stringArray(forKey: "favorites") ?? [] {
            let url = URL(fileURLWithPath: path)
            let entry = (try? await QuickAccessFiles.entry(at: url)) ?? QuickAccessEntry(path: path, name: url.lastPathComponent, isDirectory: true)
            if !entries.contains(where: { $0.path == entry.path }) { entries.append(entry) }
        }
        save()
    }

    func add(_ urls: [URL]) async {
        await restore()
        var failures: [String] = []
        for url in urls where url.isFileURL {
            do {
                let entry = try await QuickAccessFiles.entry(at: url)
                if !entries.contains(where: { $0.path == entry.path }) { entries.append(entry) }
            } catch { failures.append(url.lastPathComponent + "：" + error.localizedDescription) }
        }
        error = failures.isEmpty ? nil : "未能添加到快速访问\n" + failures.joined(separator: "\n")
        save()
    }

    func resolve(_ entry: QuickAccessEntry) async throws -> FileItem {
        let (updated, item) = try await QuickAccessFiles.resolve(entry)
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            if let old = scoped.removeValue(forKey: entry.id) { old.stopAccessingSecurityScopedResource() }
            if item.url.startAccessingSecurityScopedResource() { scoped[entry.id] = item.url }
            entries[index] = updated; save()
        }
        return item
    }

    func remove(_ entry: QuickAccessEntry) {
        entries.removeAll { $0.id == entry.id }
        if let url = scoped.removeValue(forKey: entry.id) { url.stopAccessingSecurityScopedResource() }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: "quickAccessEntries") }
    }
}
