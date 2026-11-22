import Foundation
import Testing
@testable import MyFoldsCore

struct FileOperationsTests {
    private func fixture(_ work: (URL, URL, URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "MyFolds-tests-" + UUID().uuidString)
        let source = root.appending(path: "来源 中文"); let target = root.appending(path: "目标")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try await work(root, source, target)
    }
    @Test func copyPreservesSourceAndBytes() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "照片 空格.txt"); let data = Data("你好 MyFolds".utf8)
            try data.write(to: file)
            let result = await FileOperations().transfer([file], to: target, move: false, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            #expect(result.failures.isEmpty); #expect(result.receipts.count == 1)
            #expect(try Data(contentsOf: file) == data)
            #expect(try Data(contentsOf: target.appending(path: file.lastPathComponent)) == data)
        }
    }
    @Test func moveCanUndo() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "move.txt"); try Data("move".utf8).write(to: file)
            let ops = FileOperations()
            let result = await ops.transfer([file], to: target, move: true, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            #expect(result.failures.isEmpty); #expect(!FileManager.default.fileExists(atPath: file.path))
            try await ops.undo(result.receipts)
            #expect(try String(contentsOf: file, encoding: .utf8) == "move")
            #expect(!FileManager.default.fileExists(atPath: target.appending(path: "move.txt").path))
        }
    }
    @Test func keepBothDoesNotReplace() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "file.txt"); try Data("new".utf8).write(to: file)
            try Data("old".utf8).write(to: target.appending(path: "file.txt"))
            let result = await FileOperations().transfer([file], to: target, move: false, conflict: { _, _, _ in .keepBoth }, progress: { _, _, _ in })
            #expect(result.receipts.count == 1)
            #expect(try String(contentsOf: target.appending(path: "file.txt"), encoding: .utf8) == "old")
            #expect(try String(contentsOf: target.appending(path: "file 2.txt"), encoding: .utf8) == "new")
        }
    }
    @Test func skippedConflictRetainsBoth() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "same"); try Data("new".utf8).write(to: file)
            try Data("old".utf8).write(to: target.appending(path: "same"))
            let result = await FileOperations().transfer([file], to: target, move: true, conflict: { _, _, _ in .skip }, progress: { _, _, _ in })
            #expect(result.skipped == 1); #expect(result.receipts.isEmpty)
            #expect(try String(contentsOf: file, encoding: .utf8) == "new")
        }
    }
    @Test func replacementKeepsBackup() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "same"); try Data("new".utf8).write(to: file)
            let destination = target.appending(path: "same"); try Data("old".utf8).write(to: destination)
            let result = await FileOperations().transfer([file], to: target, move: false, conflict: { _, _, _ in .replace }, progress: { _, _, _ in })
            let receipt = try #require(result.receipts.first); let backup = try #require(receipt.backup)
            #expect(try String(contentsOf: destination, encoding: .utf8) == "new")
            #expect(try String(contentsOf: backup, encoding: .utf8) == "old")
        }
    }
    @Test func cannotMoveIntoDescendant() async throws {
        try await fixture { _, source, _ in
            let inside = source.appending(path: "child"); try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: false)
            let result = await FileOperations().transfer([source], to: inside, move: true, conflict: { _, _, _ in .replace }, progress: { _, _, _ in })
            #expect(result.failures.count == 1); #expect(result.receipts.isEmpty)
            #expect(FileManager.default.fileExists(atPath: source.path))
        }
    }
    @Test func symbolicLinkIsCopiedWithoutTraversal() async throws {
        try await fixture { _, source, target in
            let link = source.appending(path: "loop"); try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
            let result = await FileOperations().transfer([link], to: target, move: false, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            #expect(result.failures.isEmpty)
            #expect(try target.appending(path: "loop").resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
        }
    }
    @Test func cancelledMoveLeavesSource() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "keep"); try Data(repeating: 7, count: 1_000_000).write(to: file)
            let ops = FileOperations()
            let task = Task { await ops.transfer([file], to: target, move: true, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in }) }
            task.cancel(); let result = await task.value
            #expect(result.cancelled); #expect(FileManager.default.fileExists(atPath: file.path))
            #expect(try FileManager.default.contentsOfDirectory(atPath: target.path).isEmpty)
        }
    }
    @Test func directoryCopyPreservesEmptyFolders() async throws {
        try await fixture { _, source, target in
            try FileManager.default.createDirectory(at: source.appending(path: "空文件夹"), withIntermediateDirectories: false)
            let result = await FileOperations().transfer([source], to: target, move: false, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            #expect(result.failures.isEmpty)
            #expect(FileManager.default.fileExists(atPath: target.appending(path: source.lastPathComponent + "/空文件夹").path))
        }
    }
    @Test func undoRefusesModifiedDestination() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "edit"); try Data("first".utf8).write(to: file)
            let ops = FileOperations()
            let result = await ops.transfer([file], to: target, move: true, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            let destination = target.appending(path: "edit"); try Data("externally changed".utf8).write(to: destination)
            await #expect(throws: (any Error).self) { try await ops.undo(result.receipts) }
            #expect(try String(contentsOf: destination, encoding: .utf8) == "externally changed")
        }
    }
    @Test func undoRefusesNestedEditsEvenIfDatesWereRestored() async throws {
        try await fixture { _, source, target in
            let file = source.appending(path: "child.txt"); try Data("first".utf8).write(to: file)
            let ops = FileOperations()
            let result = await ops.transfer([source], to: target, move: true, conflict: { _, _, _ in .cancel }, progress: { _, _, _ in })
            let copied = try #require(result.receipts.first).destination.appending(path: "child.txt")
            let oldDate = try FileManager.default.attributesOfItem(atPath: copied.path)[.modificationDate]
            try Data("other".utf8).write(to: copied)
            if let oldDate { try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: copied.path) }
            await #expect(throws: (any Error).self) { try await ops.undo(result.receipts) }
            #expect(try String(contentsOf: copied, encoding: .utf8) == "other")
        }
    }
    @Test func trashRetainsSuccessfulReceiptsWhenAnotherItemFails() async throws {
        try await fixture { _, source, _ in
            let file = source.appending(path: "trash-test-" + UUID().uuidString); try Data("restore".utf8).write(to: file)
            let ops = FileOperations()
            let result = await ops.trash([file, source.appending(path: "missing")])
            #expect(result.receipts.count == 1); #expect(result.failures.count == 1)
            try await ops.undo(result.receipts)
            #expect(try String(contentsOf: file, encoding: .utf8) == "restore")
        }
    }
    @Test func invalidNamesAreRejected() throws {
        for value in ["", ".", "..", "a/b", "a:b", "a\0b"] { #expect(throws: (any Error).self) { try FileOperations.validateName(value) } }
        try FileOperations.validateName("中文 name.txt")
    }
    @Test func pathsResolveWithoutShellInterpretation() throws {
        let root = URL(fileURLWithPath: "/tmp")
        #expect(try DirectoryService.resolve("~/Pictures", relativeTo: root).path == URL.homeDirectory.appending(path: "Pictures").path)
        #expect(try DirectoryService.resolve("literal $(pwd)", relativeTo: root).path == "/tmp/literal $(pwd)")
        #expect(try DirectoryService.resolve("file:///tmp/a%20b", relativeTo: root).path == "/tmp/a b")
    }
}
