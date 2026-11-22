import Foundation

enum LineSyntaxHighlighter {
    private static let logFields = try! NSRegularExpression(pattern: #"\b(?:TRACE|DEBUG|INFO|NOTICE|WARN(?:ING)?|ERROR|FATAL|CRITICAL|SEVERE)\b|\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:?\d{2})?|\b\d{2}:\d{2}:\d{2}(?:[.,]\d+)?|\b(?:VERBOSE|[VDIWEF])(?=\s*/|\s+[\w.]+\s*:)"#, options: [.caseInsensitive])
    private static let configValues = try! NSRegularExpression(pattern: #""(?:\\.|[^"\\])*"|'[^']*'|\$\([^)\r\n]*\)|\$\{[^}\r\n]*\}|\b(?:true|false|yes|no|on|off|\d+(?:\.\d+)?)\b"#, options: [.caseInsensitive])
    private static let dockerInstructions = Set("FROM RUN CMD LABEL MAINTAINER EXPOSE ENV ADD COPY ENTRYPOINT VOLUME USER WORKDIR ARG ONBUILD STOPSIGNAL HEALTHCHECK SHELL".split(separator: " ").map(String.init))

    static func highlight(_ text: String, language: SyntaxLanguage, offset: Int) throws -> [SyntaxToken] {
        let source = text as NSString
        var tokens: [SyntaxToken] = [], cursor = 0
        func append(_ range: NSRange, _ kind: SyntaxToken.Kind) {
            guard range.length > 0 else { return }
            tokens.append(SyntaxToken(range: NSRange(location: range.location + offset, length: range.length), kind: kind))
        }
        while cursor < source.length {
            try Task.checkCancellation()
            let lineRange = source.lineRange(for: NSRange(location: cursor, length: 0))
            let line = source.substring(with: lineRange).trimmingCharacters(in: .newlines)
            let range = NSRange(location: cursor, length: (line as NSString).length)
            defer { cursor = NSMaxRange(lineRange) }
            if language == .diff {
                if line.hasPrefix("diff ") || line.hasPrefix("index ") || line.hasPrefix("--- ") || line.hasPrefix("+++ ") || line.hasPrefix("*** ") || line.hasPrefix("===") { append(range, .property) }
                else if line.hasPrefix("@@") { append(range, .heading) }
                else if line.hasPrefix("+") { append(range, .addition) }
                else if line.hasPrefix("-") { append(range, .deletion) }
                else if line.hasPrefix("!") { append(range, .warning) }
                else if line.hasPrefix("\\") || line.hasPrefix("Binary files ") || line.hasPrefix("rename ") || line.hasPrefix("new file ") || line.hasPrefix("deleted file ") { append(range, .comment) }
                continue
            }
            if language == .log {
                for match in logFields.matches(in: text, range: range) {
                    let value = source.substring(with: match.range).uppercased()
                    let kind: SyntaxToken.Kind
                    if ["ERROR", "FATAL", "CRITICAL", "SEVERE", "E", "F"].contains(value) { kind = .error }
                    else if ["WARN", "WARNING", "W"].contains(value) { kind = .warning }
                    else if ["INFO", "NOTICE", "I"].contains(value) { kind = .addition }
                    else if ["TRACE", "DEBUG", "VERBOSE", "D", "V"].contains(value) { kind = .comment }
                    else { kind = .number }
                    append(match.range, kind)
                }
                continue
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || language == .ini && trimmed.hasPrefix(";") { append(range, .comment); continue }
            if language == .ini && trimmed.hasPrefix("[") && trimmed.contains("]") { append(range, .heading); continue }
            var valueStart = cursor
            if language == .dockerfile, let instruction = trimmed.split(whereSeparator: \.isWhitespace).first, dockerInstructions.contains(instruction.uppercased()) {
                let word = (line as NSString).range(of: String(instruction))
                append(NSRange(location: cursor + word.location, length: word.length), .keyword)
                valueStart = cursor + NSMaxRange(word)
            } else if let separator = line.firstIndex(of: "="), language == .ini || language == .makefile {
                let prefix = String(line[..<separator])
                append(NSRange(location: cursor, length: (prefix as NSString).length), .property)
                valueStart = cursor + (prefix as NSString).length + 1
            } else if language == .makefile && !line.hasPrefix("\t"), let colon = line.firstIndex(of: ":") {
                let length = (String(line[..<colon]) as NSString).length
                append(NSRange(location: cursor, length: length), .function)
                valueStart = cursor + length + 1
            }
            let values = NSRange(location: valueStart, length: max(0, NSMaxRange(range) - valueStart))
            for match in configValues.matches(in: text, range: values) {
                let value = source.substring(with: match.range)
                append(match.range, value.hasPrefix("$") ? .property : value.first?.isNumber == true ? .number : .string)
            }
        }
        return tokens
    }
}
