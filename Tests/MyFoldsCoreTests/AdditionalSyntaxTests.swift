import Foundation
import Testing
import MyFoldsCore

@Suite("Additional document syntax")
struct AdditionalSyntaxTests {
    @Test func diffDistinguishesHeadersHunksAndChangedLines() async throws {
        let text = "diff --git a/你好 b/你好\r\n--- a/你好\r\n+++ b/你好\r\n@@ -1 +1 @@\r\n-旧值😀\r\n+新值😀\r\n unchanged\r\n"
        let tokens = try await SyntaxHighlighter.highlight(text, language: .diff)
        let source = text as NSString
        #expect(tokens.filter { $0.kind == .property }.count == 3)
        #expect(tokens.filter { $0.kind == .heading }.count == 1)
        #expect(tokens.filter { $0.kind == .deletion }.map { source.substring(with: $0.range) } == ["-旧值😀"])
        #expect(tokens.filter { $0.kind == .addition }.map { source.substring(with: $0.range) } == ["+新值😀"])
        #expect(tokens.allSatisfy { Range($0.range, in: text) != nil })
    }
    @Test func logLevelsTimestampsAndLogcatAreRecognized() async throws {
        let text = "2026-11-22T12:30:45.012Z INFO 已完成😀\n12:30:46 WARN retry\nERROR failure\nDEBUG details\n11-22 12:31:00.123 100 101 E MyApp: stopped\n"
        let tokens = try await SyntaxHighlighter.highlight(text, language: .log)
        #expect(tokens.contains { $0.kind == .number && (text as NSString).substring(with: $0.range).hasPrefix("2026-") })
        #expect(tokens.filter { $0.kind == .error }.count == 2)
        #expect(tokens.filter { $0.kind == .warning }.count == 1)
        #expect(tokens.filter { $0.kind == .addition }.count == 1)
        #expect(tokens.contains { $0.kind == .comment })
    }
    @Test func configurationAndBuildFiles() async throws {
        let ini = try await SyntaxHighlighter.highlight("[section]\n; note\nname=\"Hello\"\nport=8080\n", language: .ini)
        #expect(ini.contains { $0.kind == .heading })
        #expect(ini.contains { $0.kind == .comment })
        #expect(ini.contains { $0.kind == .property })
        #expect(ini.contains { $0.kind == .number })
        let docker = try await SyntaxHighlighter.highlight("FROM alpine\nENV PORT=8080\n# note\n", language: .dockerfile)
        #expect(docker.filter { $0.kind == .keyword }.count == 2)
        let make = try await SyntaxHighlighter.highlight("CC=clang\nall: main\n\t$(CC) main.c\n", language: .makefile)
        #expect(make.contains { $0.kind == .function })
        #expect(make.filter { $0.kind == .property }.count == 2)
    }
    @Test func extensionlessAndRotatedFilesOpenInTextEditor() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let files: [(String, SyntaxLanguage)] = [("change.patch", .diff), ("change.diff", .diff), ("app.log.1", .log), ("config.ini", .ini), (".env.local", .ini), ("Dockerfile", .dockerfile), ("Makefile", .makefile)]
        for (name, language) in files {
            let url = root.appendingPathComponent(name)
            try Data("example".utf8).write(to: url)
            #expect(SyntaxLanguage.detect(url: url, text: "") == language)
            #expect(BuiltInViewer.matching(try FileItem(url: url)) == .text)
        }
    }
    @Test func nestedDiffInMarkdownKeepsUnicodeOffsets() async throws {
        let text = "# 中文😀\n```diff\n-old\n+new\n```\n"
        let tokens = try await SyntaxHighlighter.highlight(text, language: .markdown)
        #expect(tokens.contains { $0.kind == .addition && (text as NSString).substring(with: $0.range) == "+new" })
    }
}
