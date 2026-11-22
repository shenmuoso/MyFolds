import Foundation
import MyFoldsCore

enum QuickAccessFiles {
    @concurrent static func entry(at url: URL, id: UUID = UUID()) async throws -> QuickAccessEntry {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL
        let item = try FileItem(url: canonical)
        let bookmark = try? canonical.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        return QuickAccessEntry(id: id, path: canonical.path, name: item.name.isEmpty ? "/" : item.name,
                                isDirectory: item.isDirectory, bookmark: bookmark)
    }

    @concurrent static func resolve(_ entry: QuickAccessEntry) async throws -> (QuickAccessEntry, FileItem) {
        var stale = false
        let resolved = entry.bookmark.flatMap {
            try? URL(resolvingBookmarkData: $0, options: [.withSecurityScope, .withoutUI, .withoutMounting],
                     relativeTo: nil, bookmarkDataIsStale: &stale)
        } ?? entry.url
        let scoped = resolved.startAccessingSecurityScopedResource()
        defer { if scoped { resolved.stopAccessingSecurityScopedResource() } }
        let item = try FileItem(url: resolved)
        var updated = entry
        updated.path = item.url.path; updated.name = item.name.isEmpty ? "/" : item.name
        updated.isDirectory = item.isDirectory
        if stale || entry.bookmark == nil {
            updated.bookmark = try? resolved.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        return (updated, item)
    }
}
