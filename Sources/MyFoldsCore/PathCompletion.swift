import Foundation

public struct PathCompletion: Identifiable, Sendable, Equatable {
    public var id: URL { url }
    public let url: URL
    public let isDirectory: Bool
    public var path: String { url.path + (isDirectory && url.path != "/" ? "/" : "") }
}

public enum PathCompletionService {
    @concurrent public static func suggestions(for input: String, relativeTo base: URL, showHidden: Bool = false, limit: Int = 12) async throws -> [PathCompletion] {
        guard !input.isEmpty else { return [] }
        let resolved = try DirectoryService.resolve(input, relativeTo: base)
        let parent = input.hasSuffix("/") ? resolved : resolved.deletingLastPathComponent()
        let prefix = input.hasSuffix("/") ? "" : resolved.lastPathComponent
        let urls = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        var matches: [PathCompletion] = []
        for url in urls {
            try Task.checkCancellation()
            let name = url.lastPathComponent
            guard (showHidden || prefix.hasPrefix(".") || !name.hasPrefix(".")), name.range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil || prefix.isEmpty else { continue }
            matches.append(PathCompletion(url: url, isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true))
        }
        return Array(matches.sorted { $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending }.prefix(limit))
    }
}
