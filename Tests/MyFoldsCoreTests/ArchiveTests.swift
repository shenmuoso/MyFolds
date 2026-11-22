import Foundation
import Testing
import CArchive
@testable import MyFoldsCore

struct ArchiveTests {
    private func fixture(_ work: (URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "MyFolds-archive-tests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try await work(root)
    }
    @Test func zipRoundTripAndSelection() async throws {
        try await fixture { root in
            let a = root.appending(path: "中文 文件.txt"); let b = root.appending(path: "other.txt")
            try Data("你好 zip".utf8).write(to: a); try Data("other".utf8).write(to: b)
            let zip = root.appending(path: "test.zip"); let service = ArchiveService()
            try await service.createZIP([a, b], at: zip)
            let list = try await service.list(zip)
            #expect(Set(list.map(\.name)) == [a.lastPathComponent, b.lastPathComponent])
            let target = try await service.extract(zip, selected: [a.lastPathComponent], to: root, progress: { _ in })
            #expect(try String(contentsOf: target.appending(path: a.lastPathComponent), encoding: .utf8) == "你好 zip")
            #expect(!FileManager.default.fileExists(atPath: target.appending(path: b.lastPathComponent).path))
            #expect(FileManager.default.fileExists(atPath: zip.path))
        }
    }
    @Test func unsafePathsAreRejected() throws {
        for path in ["../escape", "a/../../escape", "/absolute", "\\server\\file", "C:/windows", "a\\..\\b"] {
            #expect(throws: (any Error).self) { try ArchiveService.safePath(path) }
        }
        #expect(try ArchiveService.safePath("./a/b") == "a/b")
        #expect(try ArchiveService.safePath("") == "")
    }
    @Test func traversalArchiveDoesNotEscape() async throws {
        try await fixture { root in
            let archive = root.appending(path: "evil.tar"); try makeArchive(archive, path: "../escape", symbolic: false)
            await #expect(throws: (any Error).self) { try await ArchiveService().extract(archive, selected: [], to: root, progress: { _ in }) }
            #expect(!FileManager.default.fileExists(atPath: root.appending(path: "escape").path))
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["evil.tar"])
        }
    }
    @Test func symbolicArchiveEntryIsRejected() async throws {
        try await fixture { root in
            let archive = root.appending(path: "links.tar"); try makeArchive(archive, path: "link", symbolic: true)
            await #expect(throws: (any Error).self) { try await ArchiveService().extract(archive, selected: [], to: root, progress: { _ in }) }
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["links.tar"])
        }
    }
    @Test func corruptArchiveFailsClearly() async throws {
        try await fixture { root in
            let archive = root.appending(path: "broken.zip"); try Data("not a zip".utf8).write(to: archive)
            await #expect(throws: (any Error).self) { try await ArchiveService().list(archive) }
        }
    }
    @Test func existingExtractionFolderIsNotOverwritten() async throws {
        try await fixture { root in
            let file = root.appending(path: "file"); try Data([1, 2, 3]).write(to: file)
            let zip = root.appending(path: "same.zip"); let service = ArchiveService()
            try await service.createZIP([file], at: zip)
            let first = try await service.extract(zip, selected: [], to: root, progress: { _ in })
            let second = try await service.extract(zip, selected: [], to: root, progress: { _ in })
            #expect(first != second); #expect(FileManager.default.fileExists(atPath: first.path))
        }
    }
    @Test(arguments: ["7z", "tar", "tgz", "tbz2", "txz", "gz", "bz2", "xz"])
    func additionalFormatsExtractBytes(_ format: String) async throws {
        try await fixture { root in
            let url = root.appending(path: "payload." + format)
            try writeFormatFixture(url, format: format)
            let service = ArchiveService(); let entries = try await service.list(url)
            #expect(entries.count == 1)
            let name = ["gz", "bz2", "xz"].contains(format) ? "payload" : "payload.txt"
            #expect(entries.first?.path == name)
            let output = try await service.extract(url, selected: [], to: root, progress: { _ in })
            #expect(try String(contentsOf: output.appending(path: name), encoding: .utf8) == "archive payload")
        }
    }
    @Test(arguments: ["rar4", "rar5"])
    func rarFixturesReadAndExtract(_ name: String) async throws {
        try await fixture { root in
            let url = try #require(Bundle.module.url(forResource: name, withExtension: "rar", subdirectory: "Fixtures"))
            let service = ArchiveService(); let entries = try await service.list(url)
            let path = name == "rar4" ? "test.txt" : "helloworld.txt"
            #expect(entries.contains { $0.path == path })
            let output = try await service.extract(url, selected: [path], to: root, progress: { _ in })
            let data = try Data(contentsOf: output.appending(path: path))
            #expect(!data.isEmpty)
        }
    }
    private func writeFormatFixture(_ url: URL, format: String) throws {
        let writer = try #require(archive_write_new()); defer { archive_write_free(writer) }
        let raw = ["gz", "bz2", "xz"].contains(format)
        let formatResult = raw ? archive_write_set_format_raw(writer) : format == "7z" ? archive_write_set_format_7zip(writer) : archive_write_set_format_pax_restricted(writer)
        try #require(formatResult == ARCHIVE_OK)
        if ["gz", "tgz"].contains(format) { try #require(archive_write_add_filter_gzip(writer) == ARCHIVE_OK) }
        if ["bz2", "tbz2"].contains(format) { try #require(archive_write_add_filter_bzip2(writer) == ARCHIVE_OK) }
        if ["xz", "txz"].contains(format) { try #require(archive_write_add_filter_xz(writer) == ARCHIVE_OK) }
        try #require(archive_write_open_filename(writer, url.path) == ARCHIVE_OK)
        let entry = try #require(archive_entry_new()); defer { archive_entry_free(entry) }
        let data = Data("archive payload".utf8)
        archive_entry_set_pathname(entry, "payload.txt"); archive_entry_set_perm(entry, 0o644)
        archive_entry_set_filetype(entry, 0o100000); archive_entry_set_size(entry, Int64(data.count))
        try #require(archive_write_header(writer, entry) == ARCHIVE_OK)
        let count = data.withUnsafeBytes { archive_write_data(writer, $0.baseAddress, data.count) }
        try #require(count == data.count)
        try #require(archive_write_close(writer) == ARCHIVE_OK)
    }
    private func makeArchive(_ url: URL, path: String, symbolic: Bool) throws {
        let writer = try #require(archive_write_new()); defer { archive_write_free(writer) }
        archive_write_set_format_pax_restricted(writer); #expect(archive_write_open_filename(writer, url.path) == ARCHIVE_OK)
        let entry = try #require(archive_entry_new()); defer { archive_entry_free(entry) }
        archive_entry_set_pathname(entry, path); archive_entry_set_perm(entry, 0o644)
        archive_entry_set_filetype(entry, symbolic ? 0o120000 : 0o100000)
        archive_entry_set_size(entry, 0)
        if symbolic { archive_entry_set_symlink(entry, "../../outside") }
        #expect(archive_write_header(writer, entry) == ARCHIVE_OK)
        archive_write_finish_entry(writer); archive_write_close(writer)
    }
}
