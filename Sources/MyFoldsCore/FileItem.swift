import Foundation
import UniformTypeIdentifiers

public struct FileItem: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isSymbolicLink: Bool
    public let size: Int64
    public let modified: Date
    public let typeIdentifier: String
    public let kind: String
    public var isImage: Bool { UTType(typeIdentifier)?.conforms(to: .image) == true }
    public var isVideo: Bool { UTType(typeIdentifier)?.conforms(to: .movie) == true }
    public var isArchive: Bool { ["zip", "7z", "rar", "tar", "gz", "bz2", "xz", "tgz", "tbz2", "txz"].contains(url.pathExtension.lowercased()) }

    public init(url: URL) throws {
        let value = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey])
        self.url = url.standardizedFileURL
        name = url.lastPathComponent
        isDirectory = value.isDirectory == true && value.isPackage != true
        isSymbolicLink = value.isSymbolicLink == true
        size = Int64(value.fileSize ?? 0)
        modified = value.contentModificationDate ?? .distantPast
        typeIdentifier = value.contentType?.identifier ?? UTType.data.identifier
        kind = isSymbolicLink ? "符号链接" : isDirectory ? "文件夹" : (value.contentType?.localizedDescription ?? url.pathExtension.uppercased())
    }
}
