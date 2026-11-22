import Foundation

public enum SyntaxHighlighter {
    @concurrent public static func highlight(_ text: String, language: SyntaxLanguage) async throws -> [SyntaxToken] {
        try Task.checkCancellation()
        if language == .plain { return [] }
        return try tokenize(Array(text.utf16), language: language)
    }

    // UTF-16 offsets map directly to NSTextView. Strings and comments are
    // consumed as units, so keywords inside them cannot overwrite their color.
    private static func tokenize(_ input: [UInt16], language: SyntaxLanguage, offset: Int = 0) throws -> [SyntaxToken] {
        let count = input.count, keywords = SyntaxKeywords.words(for: language)
        var tokens: [SyntaxToken] = [], i = 0, insideTag = false
        let hashComments: Set<SyntaxLanguage> = [.python, .shell, .yaml, .toml]
        let slashComments: Set<SyntaxLanguage> = [.swift, .javascript, .typescript, .java, .kotlin, .c, .cpp, .csharp, .go, .rust, .css, .json]
        func matches(_ value: String, at index: Int) -> Bool {
            let units = Array(value.utf16)
            return index + units.count <= count && input[index..<(index + units.count)].elementsEqual(units)
        }
        func word(_ c: UInt16) -> Bool { (65...90).contains(c) || (97...122).contains(c) || c == 95 || c >= 128 }
        func digit(_ c: UInt16) -> Bool { (48...57).contains(c) }
        func space(_ c: UInt16) -> Bool { c == 32 || c == 9 || c == 10 || c == 13 }
        func nextNonspace(_ start: Int) -> Int { var j = start; while j < count && space(input[j]) { j += 1 }; return j }
        func append(_ start: Int, _ end: Int, _ kind: SyntaxToken.Kind) {
            if end > start { tokens.append(SyntaxToken(range: NSRange(location: start + offset, length: end - start), kind: kind)) }
        }
        func endOfLine(_ start: Int) -> Int { var j = start; while j < count && input[j] != 10 { j += 1 }; return j }
        while i < count {
            if i % 1024 == 0 { try Task.checkCancellation() }
            let start = i, value = input[i]
            if language == .markdown {
                let lineStart = i == 0 || input[i - 1] == 10
                if lineStart && (matches("```", at: i) || matches("~~~", at: i)) {
                    let marker = input[i]; var width = 3
                    while i + width < count && input[i + width] == marker { width += 1 }
                    let firstEnd = endOfLine(i), bodyStart = min(count, firstEnd + 1)
                    let name = String(decoding: input[(i + width)..<firstEnd], as: UTF16.self).trimmingCharacters(in: .whitespaces)
                    var bodyEnd = bodyStart
                    while bodyEnd < count {
                        try Task.checkCancellation()
                        if bodyEnd + width <= count && input[bodyEnd..<(bodyEnd + width)].allSatisfy({ $0 == marker }) { break }
                        bodyEnd = min(count, endOfLine(bodyEnd) + 1)
                    }
                    append(i, firstEnd, .comment)
                    if let nested = SyntaxLanguage.named(name), nested != .markdown && nested != .plain {
                        tokens += try tokenize(Array(input[bodyStart..<bodyEnd]), language: nested, offset: offset + bodyStart)
                    } else { append(bodyStart, bodyEnd, .code) }
                    i = endOfLine(bodyEnd); append(bodyEnd, i, .comment); continue
                }
                if lineStart && value == 35 { i = endOfLine(i); append(start, i, .heading); continue }
                if value == 96 {
                    i += 1; while i < count && input[i] != 96 && input[i] != 10 { i += 1 }
                    if i < count && input[i] == 96 { i += 1 }
                    append(start, i, .code); continue
                }
                if value == 91 {
                    var end = i + 1; while end < count && input[end] != 93 && input[end] != 10 { end += 1 }
                    if end + 1 < count && input[end] == 93 && input[end + 1] == 40 {
                        end += 2; while end < count && input[end] != 41 && input[end] != 10 { end += 1 }
                        if end < count && input[end] == 41 { i = end + 1; append(start, i, .link); continue }
                    }
                }
                i += 1; continue
            }
            if (language == .html || language == .xml) && matches("<!--", at: i) {
                i += 4; while i < count && !matches("-->", at: i) { if i % 1024 == 0 { try Task.checkCancellation() }; i += 1 }
                i = min(count, i + 3); append(start, i, .comment); continue
            }
            if hashComments.contains(language) && value == 35 || slashComments.contains(language) && language != .css && matches("//", at: i) || language == .sql && matches("--", at: i) {
                i = endOfLine(i); append(start, i, .comment); continue
            }
            if (slashComments.contains(language) || language == .sql) && matches("/*", at: i) {
                i += 2; var depth = 1
                while i < count && depth > 0 {
                    if i % 1024 == 0 { try Task.checkCancellation() }
                    if matches("*/", at: i) { depth -= 1; i += 2 }
                    else if [.swift, .rust].contains(language) && matches("/*", at: i) { depth += 1; i += 2 }
                    else { i += 1 }
                }
                append(start, i, .comment); continue
            }
            if value == 34 || value == 39 || value == 96 && [.javascript, .typescript, .go, .shell].contains(language) {
                let triple = [.python, .swift].contains(language) && i + 2 < count && input[i + 1] == value && input[i + 2] == value
                let width = triple ? 3 : 1; i += width
                while i < count {
                    if i % 1024 == 0 { try Task.checkCancellation() }
                    if input[i] == 92 { i = min(count, i + 2); continue }
                    if input[i] == value && (!triple || i + 2 < count && input[i + 1] == value && input[i + 2] == value) {
                        i += width
                        if language == .sql && i < count && input[i] == value { i += 1; continue }
                        break
                    }
                    i += 1
                }
                let next = nextNonspace(i)
                append(start, i, [.json, .yaml, .toml].contains(language) && next < count && [58, 61].contains(input[next]) ? .property : .string)
                continue
            }
            if (language == .html || language == .xml) && value == 60 {
                insideTag = true; i += 1
                if i < count && [47, 33, 63].contains(input[i]) { i += 1 }
                while i < count && (word(input[i]) || digit(input[i]) || [45, 58].contains(input[i])) { i += 1 }
                append(start, i, .tag); continue
            }
            if insideTag && value == 62 { insideTag = false; i += 1; append(start, i, .tag); continue }
            if [.html, .xml].contains(language) && !insideTag { i += 1; continue }
            if digit(value) {
                i += 1
                while i < count && (digit(input[i]) || [46, 95, 120, 88, 101, 69].contains(input[i]) || (65...70).contains(input[i]) || (97...102).contains(input[i])) { i += 1 }
                append(start, i, .number); continue
            }
            if word(value) {
                i += 1; while i < count && (word(input[i]) || digit(input[i]) || insideTag && [45, 58].contains(input[i])) { i += 1 }
                let name = String(decoding: input[start..<i], as: UTF16.self), next = nextNonspace(i)
                if insideTag || [.yaml, .toml, .css].contains(language) && next < count && [58, 61].contains(input[next]) { append(start, i, .property) }
                else if keywords.contains(language == .sql ? name.lowercased() : name) { append(start, i, .keyword) }
                else if ![.html, .xml, .json, .yaml, .toml].contains(language) && next < count && input[next] == 40 { append(start, i, .function) }
                else if (65...90).contains(value) && ![.html, .xml, .json, .yaml, .toml].contains(language) { append(start, i, .type) }
                continue
            }
            i += 1
        }
        try Task.checkCancellation()
        return tokens
    }
}
