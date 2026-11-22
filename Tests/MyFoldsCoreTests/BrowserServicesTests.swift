import Foundation
import Testing
@testable import MyFoldsCore

struct BrowserServicesTests {
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyFolds-013-tests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    @Test func pathCompletionIncludesFilesDirectoriesAndUnicode() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        for name in ["abc.txt", "axx.md", "其他.txt", ".private"] { try Data().write(to: root.appendingPathComponent(name)) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("assets"), withIntermediateDirectories: true)
        let matches = try await PathCompletionService.suggestions(for: root.path + "/a", relativeTo: root)
        #expect(matches.map { $0.url.lastPathComponent } == ["abc.txt", "assets", "axx.md"])
        #expect(matches[1].isDirectory)
        #expect(matches[1].path.hasSuffix("/"))
        let relative = try await PathCompletionService.suggestions(for: "其", relativeTo: root)
        #expect(relative.map { $0.url.lastPathComponent } == ["其他.txt"])
        let all = try await PathCompletionService.suggestions(for: root.path + "/", relativeTo: root)
        #expect(all.count == 4)
        let hidden = try await PathCompletionService.suggestions(for: root.path + "/.", relativeTo: root)
        #expect(hidden.count == 1)
    }
    @Test func sameFolderDropCancelsThroughAliasesButMixedDropRetainsOthers() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source"), other = root.appendingPathComponent("other")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        let local = source.appendingPathComponent("local.txt"), remote = other.appendingPathComponent("other.txt")
        try Data().write(to: local); try Data().write(to: remote)
        let alias = root.appendingPathComponent("alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: source)
        #expect(await DropPolicy.transferable([local], to: source).isEmpty)
        #expect(await DropPolicy.transferable([local], to: alias).isEmpty)
        #expect(await DropPolicy.transferable([local, remote, remote], to: source) == [remote])
    }
    @Test func documentPreservesEncodingAndRejectsExternalOverwrite() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("unicode.txt")
        let bytes = Data([0xff, 0xfe]) + "第一行\r\n第二行".data(using: .utf16LittleEndian)!
        try bytes.write(to: url)
        let store = TextDocumentStore(), snapshot = try await store.read(url)
        #expect(snapshot.text == "第一行\r\n第二行")
        _ = try await store.save("修改\r\n", to: url, encoding: snapshot.encoding, expectedRevision: snapshot.revision)
        #expect(try Data(contentsOf: url) == Data([0xff, 0xfe]) + "修改\r\n".data(using: .utf16LittleEndian)!)
        let current = try await store.read(url)
        try Data("external".utf8).write(to: url)
        await #expect(throws: TextDocumentError.self) { try await store.save("overwrite", to: url, encoding: current.encoding, expectedRevision: current.revision) }
        #expect(try String(contentsOf: url, encoding: .utf8) == "external")
    }
    @Test func symlinkTextSavePreservesLinkAndPermissions() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("script.sh"), link = root.appendingPathComponent("link.sh")
        try Data("initial".utf8).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: url)
        let store = TextDocumentStore(), snapshot = try await store.read(link)
        _ = try await store.save("changed", to: link, encoding: snapshot.encoding, expectedRevision: snapshot.revision)
        #expect(try link.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
        #expect(try String(contentsOf: url, encoding: .utf8) == "changed")
        #expect((try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int) == 0o755)
    }
    @Test func binaryAndLargeDocumentsAreNotRewritten() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        let binary = root.appendingPathComponent("binary.txt"), large = root.appendingPathComponent("large.txt")
        try Data([1, 0, 2, 3]).write(to: binary); try Data(repeating: 65, count: 8 * 1024 * 1024 + 1).write(to: large)
        let store = TextDocumentStore()
        await #expect(throws: TextDocumentError.self) { try await store.read(binary) }
        await #expect(throws: TextDocumentError.self) { try await store.read(large) }
    }
    @Test func mountResultFindsOnlyBrowsableVolumes() throws {
        let data = try PropertyListSerialization.data(fromPropertyList: ["system-entities": [["dev-entry": "/dev/disk99"], ["mount-point": "/Volumes/My Folds 测试", "dev-entry": "/dev/disk99s1"]]], format: .xml, options: 0)
        #expect(try DiskImageService.mountPoints(from: data) == [URL(fileURLWithPath: "/Volumes/My Folds 测试", isDirectory: true)])
    }
    @Test func markdownPreservesContentInNativeBlocks() async throws {
        let blocks = try await MarkdownParser.parse("# 标题\n\n**重点**\n\n- 第一项\n\n```swift\nlet n = 1\n```\n\n| 列 | 值 |\n| --- | --- |\n| A | 1 |")
        #expect(blocks.count == 5)
        #expect(String(blocks[1].text.characters) == "重点")
        if case .code(let value) = blocks[3].kind { #expect(value == "let n = 1") } else { Issue.record("Missing code block") }
        if case .table(let rows) = blocks[4].kind { #expect(rows == [["列", "值"], ["A", "1"]]) } else { Issue.record("Missing table") }
    }
    @Test func builtInRoutingCoversRequestedFamiliesAndExcludesOffice() async throws {
        let root = try folder(); defer { try? FileManager.default.removeItem(at: root) }
        let expected: [(String, BuiltInViewer?)] = [("a.txt", .text), ("a.md", .markdown), ("a.jpg", .image), ("a.mp4", .video), ("a.pdf", .pdf), ("a.docx", nil), ("a.rtf", nil)]
        for (name, kind) in expected {
            let url = root.appendingPathComponent(name); try Data().write(to: url)
            #expect(BuiltInViewer.matching(try FileItem(url: url)) == kind)
        }
    }
}
