import Foundation

public actor DiskImageService {
    public init() {}
    public func eject(_ volume: MountedVolume) async throws {
        guard let source = volume.imageURL else { throw FileOperationError.message("此位置不是已挂载的磁盘映像。") }
        let inventory = try await CommandProcess.run("/usr/bin/hdiutil", arguments: ["info", "-plist"])
        guard try Self.imageSources(from: inventory)[volume.id]?.standardizedFileURL == source.standardizedFileURL else {
            throw FileOperationError.message("此磁盘映像的挂载状态已变化，请刷新后重试。")
        }
        _ = try await CommandProcess.run("/usr/bin/hdiutil", arguments: ["detach", volume.url.path], failureMessage: "无法弹出磁盘映像。请关闭正在使用它的文件后重试。")
    }
    public func mount(_ url: URL) async throws -> [URL] {
        // hdiutil's -nobrowse suppresses Finder. No shell interpolation is used.
        let data = try await CommandProcess.run("/usr/bin/hdiutil", arguments: ["attach", "-nobrowse", "-noautoopen", "-plist", url.path])
        let mounts = try Self.mountPoints(from: data)
        guard !mounts.isEmpty else { throw FileOperationError.message("映像已处理，但没有可浏览的文件系统。加密映像请先使用磁盘工具解锁。") }
        return mounts
    }
    public static func mountPoints(from data: Data) throws -> [URL] {
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any], let entities = plist["system-entities"] as? [[String: Any]] else { throw FileOperationError.message("无法读取磁盘映像的挂载结果。") }
        return entities.compactMap { ($0["mount-point"] as? String).map { URL(fileURLWithPath: $0, isDirectory: true) } }
    }

    public static func imageSources(from data: Data) throws -> [String: URL] {
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let images = plist["images"] as? [[String: Any]] else {
            throw FileOperationError.message("无法读取已挂载的磁盘映像。")
        }
        var sources: [String: URL] = [:]
        for image in images {
            guard let path = image["image-path"] as? String, path.hasPrefix("/"),
                  let entities = image["system-entities"] as? [[String: Any]] else { continue }
            let source = URL(fileURLWithPath: path).standardizedFileURL
            for entity in entities {
                guard let mount = entity["mount-point"] as? String, mount.hasPrefix("/") else { continue }
                sources[URL(fileURLWithPath: mount).standardizedFileURL.path] = source
            }
        }
        return sources
    }
}
