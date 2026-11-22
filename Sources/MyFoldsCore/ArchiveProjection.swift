import Foundation

public enum ArchiveProjection {
    @concurrent public static func contents(_ entries: [ArchiveItem], in folder: String) async throws -> [ArchiveItem] {
        let prefix = folder.isEmpty ? "" : folder + "/"
        var items: [String: ArchiveItem] = [:]
        for entry in entries {
            try Task.checkCancellation()
            guard entry.path.hasPrefix(prefix), entry.path != folder else { continue }
            let remainder = String(entry.path.dropFirst(prefix.count))
            guard let first = remainder.split(separator: "/").first else { continue }
            let path = prefix + first
            if remainder.contains("/") { items[path] = ArchiveItem(path: path, size: 0, isDirectory: true) }
            else { items[path] = entry }
        }
        return items.values.sorted {
            $0.isDirectory != $1.isDirectory ? $0.isDirectory : $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
