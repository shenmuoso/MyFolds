import Foundation
import Testing
import MyFoldsCore

@Suite("Mounted disk image classification")
struct VolumeServiceTests {
    @Test func readsImageSourcesAcrossMultipleVolumesAndSkipsUnmountedEntities() throws {
        let data = try plist(["images": [
            ["image-path": "/Downloads/安装 包.dmg", "system-entities": [
                ["dev-entry": "/dev/disk4"],
                ["mount-point": "/Volumes/工具"],
                ["mount-point": "/Volumes/资料"]
            ]],
            ["image-path": "/Downloads/Backup.sparsebundle", "system-entities": [["mount-point": "/Volumes/Backup"]]],
            ["system-entities": [["mount-point": "/Volumes/Unknown"]]]
        ]])
        let sources = try DiskImageService.imageSources(from: data)
        #expect(sources.count == 3)
        #expect(sources["/Volumes/工具"]?.path == "/Downloads/安装 包.dmg")
        #expect(sources["/Volumes/资料"] == sources["/Volumes/工具"])
        #expect(sources["/Volumes/Backup"]?.path == "/Downloads/Backup.sparsebundle")
        #expect(sources["/dev/disk4"] == nil && sources["/Volumes/Unknown"] == nil)
    }

    @Test func usesMountIdentityInsteadOfNamesAndDeduplicatesHiddenImageVolumes() {
        let disk = MountedVolume(url: URL(fileURLWithPath: "/Volumes/Physical"), name: "Installer.dmg")
        let image = MountedVolume(url: URL(fileURLWithPath: "/Volumes/工具"), name: "普通名称")
        let source = URL(fileURLWithPath: "/Downloads/source.dmg")
        let result = VolumeService.classified([disk, image, image], imageSources: [image.id: source])
        #expect(result.count == 2)
        #expect(!result[0].isDiskImage)
        #expect(result[1].isDiskImage && result[1].imageURL == source)
        #expect(result[1].name == "普通名称")
        let afterEject = VolumeService.classified([disk], imageSources: [image.id: source])
        #expect(afterEject.count == 1 && !afterEject[0].isDiskImage)
    }

    @Test func emptyInventoryClearsClassificationAndMalformedInventoryThrows() throws {
        let empty = try DiskImageService.imageSources(from: plist(["images": []]))
        #expect(empty.isEmpty)
        let old = MountedVolume(url: URL(fileURLWithPath: "/Volumes/Reused"), name: "Reused", imageURL: URL(fileURLWithPath: "/old.dmg"))
        #expect(VolumeService.classified([old], imageSources: empty).first?.isDiskImage == false)
        #expect(throws: (any Error).self) { try DiskImageService.imageSources(from: plist(["other": []])) }
    }

    private func plist(_ value: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: 0)
    }
}
