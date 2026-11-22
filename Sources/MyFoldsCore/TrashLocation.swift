import Foundation

public enum TrashLocation {
    public static var root: URL { URL.homeDirectory.appendingPathComponent(".Trash", isDirectory: true).standardizedFileURL }
    public static func contains(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let path = url.standardizedFileURL.path
        return path == root.path || path.hasPrefix(root.path + "/")
    }
}
