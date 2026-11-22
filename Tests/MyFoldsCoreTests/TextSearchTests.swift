import Foundation
import Testing
@testable import MyFoldsCore

@Suite("Single-file search and replacement")
struct TextSearchTests {
    @Test func literalCaseWordsAndUnicodeOffsets() async throws {
        let text = "😀 Cat cat scatter cat_ cat.\n中文 cat"
        var options = TextSearchOptions()
        options.wholeWord = true
        let result = try await TextSearchEngine.search(text, query: "cat", options: options)
        #expect(result.ranges.count == 4)
        #expect(result.ranges.first == NSRange(location: 3, length: 3))
        #expect(result.rows.first?.column == 3)
        #expect(result.rows.last?.line == 2)
        options.caseSensitive = true
        #expect(try await TextSearchEngine.search(text, query: "cat", options: options).ranges.count == 3)
        #expect(try await TextSearchEngine.search("a.b axb", query: "a.b", options: TextSearchOptions()).ranges.count == 1)
    }
    @Test func escapedNewlinesAndLiteralReplacement() async throws {
        var options = TextSearchOptions(); options.mode = .extended
        let plan = try #require(try await TextSearchEngine.replacement("a\r\nb\r\nc", query: #"\r\n"#, replacement: #"\t"#, options: options))
        #expect(apply(plan, to: "a\r\nb\r\nc") == "a\tb\tc")
        let literal = try #require(try await TextSearchEngine.replacement("a a", query: "a", replacement: #"$1\n"#, options: TextSearchOptions()))
        #expect(apply(literal, to: "a a") == #"$1\n $1\n"#)
    }
    @Test func capturesReplaceAllAndSingle() async throws {
        var options = TextSearchOptions(); options.mode = .regularExpression
        let text = "name=张三\nname=李四"
        let plan = try #require(try await TextSearchEngine.replacement(text, query: "name=(.+)", replacement: #"[$1] \1 $$"#, options: options))
        #expect(plan.count == 2)
        #expect(apply(plan, to: text) == "[张三] 张三 $\n[李四] 李四 $")
        let result = try await TextSearchEngine.search(text, query: "name=(.+)", options: options)
        let single = try #require(try await TextSearchEngine.replacement(text, query: "name=(.+)", replacement: "$1", options: options, only: result.ranges[1]))
        #expect(apply(single, to: text) == "name=张三\n李四")
        await #expect(throws: TextSearchError.self) { try await TextSearchEngine.replacement(text, query: "name=(.+)", replacement: "$2", options: options) }
    }
    @Test func selectionDoesNotInventWordOrLineBoundaries() async throws {
        let text = "cat scatter cat"
        var options = TextSearchOptions(); options.wholeWord = true
        let insideWord = NSRange(location: 5, length: 3)
        #expect(try await TextSearchEngine.search(text, query: "cat", options: options, scope: insideWord).ranges.isEmpty)
        let plan = try #require(try await TextSearchEngine.replacement(text, query: "cat", replacement: "dog", options: options, scope: NSRange(location: 12, length: 3)))
        #expect(apply(plan, to: text) == "cat scatter dog")
        options.mode = .regularExpression; options.wholeWord = false
        #expect(try await TextSearchEngine.search(text, query: "^cat", options: options, scope: NSRange(location: 12, length: 3)).ranges.isEmpty)
    }
    @Test func zeroLengthMatchesAndDotNewline() async throws {
        var options = TextSearchOptions(); options.mode = .regularExpression
        let text = "a\nb\n"
        let result = try await TextSearchEngine.search(text, query: "^", options: options)
        #expect(result.ranges.count >= 2)
        let plan = try #require(try await TextSearchEngine.replacement(text, query: "(?=a|b)", replacement: ">", options: options))
        #expect(apply(plan, to: text) == ">a\n>b\n")
        #expect(try await TextSearchEngine.search(text, query: "a.b", options: options).ranges.isEmpty)
        options.dotMatchesNewline = true
        #expect(try await TextSearchEngine.search(text, query: "a.b", options: options).ranges.count == 1)
    }
    @Test func invalidAndExcessivePatternsNeverProducePartialReplacement() async throws {
        var options = TextSearchOptions(); options.mode = .regularExpression
        await #expect(throws: TextSearchError.self) { try await TextSearchEngine.search("abc", query: "[", options: options) }
        await #expect(throws: TextSearchError.self) { try await TextSearchEngine.replacement(String(repeating: "a", count: 100_001), query: "a", replacement: "b", options: options) }
        await #expect(throws: TextSearchError.self) { try await TextSearchEngine.replacement("a a", query: "a", replacement: String(repeating: "x", count: 5 * 1024 * 1024), options: TextSearchOptions()) }
        let task = Task { try await TextSearchEngine.search(String(repeating: "a", count: 100_000), query: "(a+)+$", options: options) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }
    @Test func logicalLinesIncludeCRLFAndTrailingEmptyLine() throws {
        let index = try TextLineIndex("😀a\r\nb\rc\n")
        #expect(index.starts == [0, 5, 7, 9])
        #expect(index.line(at: 3) == 0)
        #expect(index.line(at: 9) == 3)
        #expect(try TextLineIndex("").starts == [0])
    }
    private func apply(_ plan: TextReplacementPlan, to text: String) -> String { (text as NSString).replacingCharacters(in: plan.range, with: plan.replacement) }
}
