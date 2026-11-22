import Foundation

public actor VolumeService {
    private var lastImageSources: [String: URL] = [:]
    public init() {}

    public func snapshot() async -> [MountedVolume] {
        do {
            let data = try await CommandProcess.run("/usr/bin/hdiutil", arguments: ["info", "-plist"])
            try Task.checkCancellation()
            lastImageSources = try DiskImageService.imageSources(from: data)
        } catch { /* Retain known classifications across a transient query failure. */ }
        let keys: Set<URLResourceKey> = [.volumeNameKey, .volumeIsInternalKey, .volumeIsLocalKey]
        let manager = FileManager.default
        let all = manager.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: []) ?? []
        var visible = manager.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: [.skipHiddenVolumes]) ?? []
        // Images opened with -nobrowse must still appear in MyFolds. Only use
        // current mount records, so an ejected image cannot leave a phantom row.
        visible += all.filter { lastImageSources[$0.standardizedFileURL.path] != nil }
        let volumes = visible.map { url in
            let values = try? url.resourceValues(forKeys: keys)
            return MountedVolume(url: url, name: values?.volumeName ?? (url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent),
                                 isInternal: values?.volumeIsInternal ?? false, isLocal: values?.volumeIsLocal ?? true)
        }
        return Self.classified(volumes, imageSources: lastImageSources)
    }

    public static func classified(_ volumes: [MountedVolume], imageSources: [String: URL]) -> [MountedVolume] {
        var seen: Set<String> = []
        return volumes.compactMap { volume in
            guard seen.insert(volume.id).inserted else { return nil }
            var result = volume
            result.imageURL = imageSources[volume.id]
            return result
        }
    }
}
