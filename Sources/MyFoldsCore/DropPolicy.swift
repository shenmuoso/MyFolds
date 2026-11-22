import Foundation

public enum DropPolicy {
    // A drag into its current parent is a cancelled gesture. Explicit Copy/Paste
    // and Duplicate use FileOperations directly and retain their normal behavior.
    @concurrent public static func transferable(_ sources: [URL], to directory: URL) async -> [URL] {
        let destination = directory.resolvingSymlinksInPath().standardizedFileURL
        var seen: Set<URL> = []
        return sources.filter { source in
            let parent = source.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
            let canonical = source.standardizedFileURL
            return parent != destination && seen.insert(canonical).inserted
        }
    }
}
