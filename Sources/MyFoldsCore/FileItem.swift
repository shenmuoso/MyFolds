import Foundation
import UniformTypeIdentifiers

public struct FileItem: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let directoryTarget: URL?
    public let isSymbolicLink: Bool
    public let size: Int64
    public let modified: Date
    public let typeIdentifier: String
    public let kind: String
    public var isImage: Bool { UTType(typeIdentifier)?.conforms(to: .image) == true }
    public var isVideo: Bool { UTType(typeIdentifier)?.conforms(to: .movie) == true }
    public var isArchive: Bool { ["zip", "7z", "rar", "tar", "gz", "bz2", "xz", "tgz", "tbz2", "txz"].contains(url.pathExtension.lowercased()) }

    public init(url: URL) throws {
        let value = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .isAliasFileKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey])
        self.url = url.standardizedFileURL
        name = url.lastPathComponent
        isSymbolicLink = value.isSymbolicLink == true
        var target = url.standardizedFileURL
        if value.isAliasFile == true {
            target = (try? URL(resolvingAliasFileAt: url, options: [.withoutUI, .withoutMounting])) ?? target
        }
        if isSymbolicLink || value.isAliasFile == true {
            target = target.resolvingSymlinksInPath().standardizedFileURL
            let resolved = try? target.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            directoryTarget = resolved?.isDirectory == true && resolved?.isPackage != true ? target : nil
        } else { directoryTarget = value.isDirectory == true && value.isPackage != true ? target : nil }
        isDirectory = directoryTarget != nil
        size = Int64(value.fileSize ?? 0)
        modified = value.contentModificationDate ?? .distantPast
        typeIdentifier = value.contentType?.identifier ?? UTType.data.identifier
        kind = isSymbolicLink ? "符号链接" : isDirectory ? "文件夹" : (value.contentType?.localizedDescription ?? url.pathExtension.uppercased())
    }
}
