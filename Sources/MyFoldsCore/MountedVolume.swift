import Foundation

public struct MountedVolume: Identifiable, Equatable, Sendable {
    public let url: URL
    public let name: String
    public let isInternal: Bool
    public let isLocal: Bool
    public var imageURL: URL?
    public var id: String { url.standardizedFileURL.path }
    public var isDiskImage: Bool { imageURL != nil }

    public init(url: URL, name: String, isInternal: Bool = false, isLocal: Bool = true, imageURL: URL? = nil) {
        self.url = url.standardizedFileURL; self.name = name
        self.isInternal = isInternal; self.isLocal = isLocal; self.imageURL = imageURL
    }
}
