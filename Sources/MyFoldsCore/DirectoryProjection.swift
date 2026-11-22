import Foundation

public struct DirectoryProjection: Sendable, Equatable {
    public var query: String
    public var sort: String
    public var ascending: Bool
    public var foldersFirst: Bool

    public init(query: String = "", sort: String = "name", ascending: Bool = true, foldersFirst: Bool = true) {
        self.query = query; self.sort = sort; self.ascending = ascending; self.foldersFirst = foldersFirst
    }

    @concurrent public func apply(to entries: [FileItem]) async throws -> [FileItem] {
        var filtered: [FileItem] = []
        for entry in entries {
            try Task.checkCancellation()
            if query.isEmpty || entry.name.localizedStandardContains(query) { filtered.append(entry) }
        }
        let result = filtered.sorted {
            if foldersFirst && $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            let a = ascending ? $0 : $1, b = ascending ? $1 : $0
            switch sort {
            case "modified": if a.modified != b.modified { return a.modified < b.modified }
            case "size": if a.size != b.size { return a.size < b.size }
            case "kind": if a.kind != b.kind { return a.kind < b.kind }
            default: break
            }
            let order = a.name.localizedStandardCompare(b.name)
            return order == .orderedSame ? a.url.path < b.url.path : order == .orderedAscending
        }
        try Task.checkCancellation()
        return result
    }
}
