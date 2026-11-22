import Foundation
import Testing
import MyFoldsCore

@Suite("Native editor syntax")
struct SyntaxHighlighterTests {
    @Test(arguments: [SyntaxLanguage.swift, .python, .javascript, .typescript, .java, .kotlin, .c, .cpp, .csharp, .go, .rust, .shell, .sql])
    func stringsAndCommentsProtectKeywords(_ language: SyntaxLanguage) async throws {
        let comment = [.python, .shell].contains(language) ? "#" : language == .sql ? "--" : "//"
        let source = "return \"return 123\"\n\(comment) return 456\n42"
        let tokens = try await SyntaxHighlighter.highlight(source, language: language)
        let text = source as NSString
        #expect(tokens.filter { $0.kind == .keyword }.count == 1)
        #expect(tokens.contains { $0.kind == .string && text.substring(with: $0.range) == "\"return 123\"" })
        #expect(tokens.contains { $0.kind == .comment && text.substring(with: $0.range).contains("456") })
        #expect(tokens.filter { $0.kind == .number }.map { text.substring(with: $0.range) } == ["42"])
    }
    @Test func unicodeRangesAndStructuredDocuments() async throws {
        let source = "{\"名称😀\": \"你好\", \"count\": 12, \"enabled\": true}"
        let tokens = try await SyntaxHighlighter.highlight(source, language: .json)
        let text = source as NSString
        #expect(tokens.contains { $0.kind == .property && text.substring(with: $0.range) == "\"名称😀\"" })
        #expect(tokens.contains { $0.kind == .string && text.substring(with: $0.range) == "\"你好\"" })
        #expect(tokens.allSatisfy { NSMaxRange($0.range) <= text.length && Range($0.range, in: source) != nil })
        for language in [SyntaxLanguage.yaml, .toml, .css] {
            let content = language == .toml ? "title = \"hello\"" : "title: \"hello\""
            #expect(try await SyntaxHighlighter.highlight(content, language: language).contains { $0.kind == .property })
        }
        for language in [SyntaxLanguage.html, .xml] {
            let content = "<title class=\"test\">return</title><!-- hi -->"
            let values = try await SyntaxHighlighter.highlight(content, language: language)
            #expect(values.contains { $0.kind == .tag })
            #expect(values.contains { $0.kind == .property })
            #expect(!values.contains { $0.kind == .keyword })
        }
    }
    @Test func markdownFencesAndIncompleteInput() async throws {
        let source = "# 文稿\n```swift\nlet answer = 42\n```\n[链接](https://example.com)\n`code`"
        let tokens = try await SyntaxHighlighter.highlight(source, language: .markdown)
        #expect(tokens.contains { $0.kind == .heading })
        #expect(tokens.contains { $0.kind == .keyword && (source as NSString).substring(with: $0.range) == "let" })
        #expect(tokens.contains { $0.kind == .link })
        #expect(tokens.contains { $0.kind == .code })
        for text in ["\"unfinished", "/* nested /* comment */", "😀 let x = '你好", "```swift\nlet x = 1"] {
            let result = try await SyntaxHighlighter.highlight(text, language: text.hasPrefix("```") ? .markdown : .swift)
            #expect(result.allSatisfy { NSMaxRange($0.range) <= (text as NSString).length })
        }
    }
    @Test func detectionAndCancellation() async throws {
        #expect(SyntaxLanguage.detect(url: URL(fileURLWithPath: "/tmp/INDEX.HTML"), text: "") == .html)
        #expect(SyntaxLanguage.detect(url: URL(fileURLWithPath: "/tmp/script"), text: "#!/usr/bin/env python3\nprint(1)") == .python)
        #expect(SyntaxLanguage.detect(url: URL(fileURLWithPath: "/tmp/file.kt"), text: "") == .kotlin)
        #expect(try await SyntaxHighlighter.highlight("let x = 1", language: .plain).isEmpty)
        let task = Task { try await SyntaxHighlighter.highlight(String(repeating: "let x = 1\n", count: 100_000), language: .swift) }
        task.cancel()
        do { _ = try await task.value; Issue.record("Cancelled highlighting should not publish a result") }
        catch is CancellationError { }
    }
}
