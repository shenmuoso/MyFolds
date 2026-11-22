import Testing
@testable import MyFoldsCore

struct ArchiveProjectionTests {
    @Test func foldersAreInferredAndSiblingPrefixesStaySeparate() async throws {
        let entries = [
            ArchiveItem(path: "docs/nested/a.txt", size: 7, isDirectory: false),
            ArchiveItem(path: "docs/readme.md", size: 12, isDirectory: false),
            ArchiveItem(path: "docs-old/other.txt", size: 4, isDirectory: false),
            ArchiveItem(path: "root.txt", size: 3, isDirectory: false)
        ]
        let root = try await ArchiveProjection.contents(entries, in: "")
        #expect(root.map(\.path) == ["docs", "docs-old", "root.txt"])
        let docs = try await ArchiveProjection.contents(entries, in: "docs")
        #expect(docs.map(\.path) == ["docs/nested", "docs/readme.md"])
        #expect(docs[0].isDirectory)
        #expect(docs[1].size == 12)
    }
}
