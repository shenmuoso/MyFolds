import Foundation

public struct ArchiveItem: Identifiable, Hashable, Sendable {
    public var id: String { path }
    public let path: String
    public let size: Int64
    public let isDirectory: Bool
    public let isLink: Bool
    public var name: String { (path as NSString).lastPathComponent }
    public init(path: String, size: Int64, isDirectory: Bool, isLink: Bool = false) {
        self.path = path; self.size = size; self.isDirectory = isDirectory; self.isLink = isLink
    }
}
