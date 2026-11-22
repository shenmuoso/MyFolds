import AppKit
import Testing
import MyFoldsCore
@testable import MyFolds

@MainActor @Suite("Context menu targeting", .serialized)
struct FileMenuTests {
    @Test("Blank right pane resets only its selection and targets that pane")
    func blankPane() {
        _ = NSApplication.shared
        let model = BrowserModel(); model.split = true
        let leftURL = URL(fileURLWithPath: "/tmp/left.txt")
        model.primary.selection = [leftURL]
        model.right.selection = [URL(fileURLWithPath: "/tmp/right.txt")]
        let menu = FileMenuFactory.make(model: model, session: model.right, item: nil)
        #expect(model.active === model.right)
        #expect(model.right.selection.isEmpty)
        #expect(model.primary.selection == [leftURL])
        #expect(menu.item(withTitle: "新建文件夹…")?.isEnabled == true)
        #expect(menu.item(withTitle: "移到废纸篓") == nil)
        #expect(menu.items.filter { !$0.isSeparatorItem }.allSatisfy { $0.image != nil })
    }

    @Test("Right click preserves a selected batch, replaces it for another target, and disables mutation while busy")
    func selectedBatch() async throws {
        _ = NSApplication.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = try (1...3).map { index in
            let url = directory.appendingPathComponent("\(index).txt")
            try Data("fixture".utf8).write(to: url)
            return try FileItem(url: url)
        }
        let model = BrowserModel(); let session = model.primary
        session.navigate(directory, hidden: false)
        for _ in 0..<100 where session.loading { try await Task.sleep(for: .milliseconds(10)) }
        session.selection = Set(files.prefix(2).map(\.url))
        let multi = FileMenuFactory.make(model: model, session: session, item: files[1])
        #expect(session.selection.count == 2)
        #expect(multi.item(withTitle: "重命名…")?.isEnabled == false)
        #expect(multi.item(withTitle: "复制")?.isEnabled == true)
        #expect(multi.items.filter { !$0.isSeparatorItem }.allSatisfy { $0.image != nil })
        model.busy = true
        let single = FileMenuFactory.make(model: model, session: session, item: files[2])
        #expect(session.selection == [files[2].url])
        #expect(single.item(withTitle: "移到废纸篓")?.isEnabled == false)
        #expect(single.item(withTitle: "剪切")?.isEnabled == false)
    }
}
