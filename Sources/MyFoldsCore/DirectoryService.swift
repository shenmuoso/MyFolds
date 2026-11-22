import Foundation

public actor DirectoryService {
    public init() {}
    public func item(at url: URL) throws -> FileItem { try FileItem(url: url) }
    public func mountedVolumes() -> [URL] {
        FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey], options: [.skipHiddenVolumes]) ?? []
    }
    public func availableCapacity(at url: URL) -> Int64? {
        (try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity).map(Int64.init)
    }
    public func contents(of directory: URL, showHidden: Bool) throws -> [FileItem] {
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey], options: options)
        return try urls.compactMap { url in
            try Task.checkCancellation()
            do { return try FileItem(url: url) }
            catch CocoaError.fileReadNoSuchFile { return nil } // A concurrent rename can remove a directory entry.
        }
    }
    public func modificationDate(of directory: URL) throws -> Date? {
        try directory.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
    public static func resolve(_ input: String, relativeTo directory: URL) throws -> URL {
        let path = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { throw FileOperationError.message("请输入文件或文件夹路径。") }
        if path.hasPrefix("file://"), let url = URL(string: path), url.isFileURL { return url.standardizedFileURL }
        let expanded = (path as NSString).expandingTildeInPath
        let base = URL(fileURLWithPath: directory.path, isDirectory: true)
        return URL(fileURLWithPath: expanded, relativeTo: expanded.hasPrefix("/") ? nil : base).standardizedFileURL
    }
}
