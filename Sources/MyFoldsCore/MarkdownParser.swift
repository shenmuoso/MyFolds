import Foundation

public struct MarkdownBlock: Identifiable, Sendable {
    public let id: Int
    public let kind: Kind
    public let text: AttributedString
    public enum Kind: Sendable {
        case paragraph, heading(Int), code(String), quote, list(String), divider, image(String, String), table([[String]])
    }
}

public enum MarkdownParser {
    @concurrent public static func parse(_ text: String) async throws -> [MarkdownBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [MarkdownBlock] = [], index = 0, paragraph: [String] = []
        func append(_ kind: MarkdownBlock.Kind, _ text: String = "") {
            let attributed = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
            blocks.append(MarkdownBlock(id: blocks.count, kind: kind, text: attributed))
        }
        func flush() {
            if !paragraph.isEmpty { append(.paragraph, paragraph.joined(separator: "\n")); paragraph = [] }
        }
        while index < lines.count {
            try Task.checkCancellation()
            let line = lines[index], trimmed = line.trimmingCharacters(in: .whitespaces)
            index += 1
            if trimmed.isEmpty { flush(); continue }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                flush(); let marker = String(trimmed.prefix(3)); var code: [String] = []
                while index < lines.count && !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(marker) {
                    code.append(lines[index]); index += 1
                }
                if index < lines.count { index += 1 }
                append(.code(code.joined(separator: "\n"))); continue
            }
            let level = trimmed.prefix(while: { $0 == "#" }).count
            if (1...6).contains(level), trimmed.dropFirst(level).hasPrefix(" ") {
                flush(); append(.heading(level), String(trimmed.dropFirst(level + 1))); continue
            }
            if ["---", "***", "___"].contains(trimmed) { flush(); append(.divider); continue }
            if trimmed.hasPrefix(">") { flush(); append(.quote, String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)); continue }
            if trimmed.hasPrefix("!["), let middle = trimmed.range(of: "]("), trimmed.hasSuffix(")") {
                flush(); let alt = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<middle.lowerBound])
                let path = String(trimmed[middle.upperBound..<trimmed.index(before: trimmed.endIndex)])
                append(.image(path, alt)); continue
            }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                flush(); append(.list("•"), String(trimmed.dropFirst(2))); continue
            }
            if let end = trimmed.firstIndex(of: "."), !trimmed[..<end].isEmpty, trimmed[..<end].allSatisfy(\.isNumber), trimmed[end...].hasPrefix(". ") {
                flush(); append(.list(String(trimmed[...end])), String(trimmed[trimmed.index(end, offsetBy: 2)...])); continue
            }
            if trimmed.contains("|"), index < lines.count, lines[index].contains("-"), lines[index].filter({ !$0.isWhitespace }).allSatisfy({ "|-:".contains($0) }) {
                flush(); var rows = [tableCells(trimmed)]; index += 1
                while index < lines.count && lines[index].contains("|") && !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                    rows.append(tableCells(lines[index])); index += 1
                }
                append(.table(rows)); continue
            }
            paragraph.append(line)
        }
        flush(); return blocks
    }
    private static func tableCells(_ row: String) -> [String] {
        var row = row.trimmingCharacters(in: .whitespaces)
        if row.hasPrefix("|") { row.removeFirst() }; if row.hasSuffix("|") { row.removeLast() }
        return row.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
