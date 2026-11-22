import Foundation

public enum TextSearchEngine {
    public static func search(_ text: String, query: String, options: TextSearchOptions, scope: NSRange? = nil) async throws -> TextSearchResult {
        let worker = Task.detached(priority: .userInitiated) {
            let (_, matches) = try find(text, query: query, options: options, scope: scope)
            let lines = try TextLineIndex(text), source = text as NSString
            let rows = try matches.prefix(500).enumerated().map { index, match in
                try Task.checkCancellation()
                let line = lines.line(at: match.range.location)
                let lineStart = lines.starts[line]
                let lineEnd = line + 1 < lines.starts.count ? lines.starts[line + 1] : source.length
                let start = max(lineStart, match.range.location - 48)
                let length = max(0, min(lineEnd - start, 180))
                let safeRange = source.rangeOfComposedCharacterSequences(for: NSRange(location: start, length: length))
                let preview = source.substring(with: safeRange).trimmingCharacters(in: .newlines)
                let prefix = source.substring(with: NSRange(location: lineStart, length: match.range.location - lineStart))
                return TextSearchResult.Row(id: index, range: match.range, line: line + 1, column: prefix.count + 1, preview: preview)
            }
            return TextSearchResult(ranges: matches.map(\.range), rows: rows)
        }
        return try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
    }

    public static func replacement(_ text: String, query: String, replacement: String, options: TextSearchOptions, scope: NSRange? = nil, only range: NSRange? = nil) async throws -> TextReplacementPlan? {
        let worker = Task.detached(priority: .userInitiated) {
            let (expression, allMatches) = try find(text, query: query, options: options, scope: scope)
            let matches = range.map { selected in allMatches.filter { $0.range == selected } } ?? allMatches
            guard let first = matches.first, let last = matches.last else { return nil as TextReplacementPlan? }
            let span = NSRange(location: first.range.location, length: NSMaxRange(last.range) - first.range.location)
            let template = try replacementTemplate(replacement, mode: options.mode, captures: expression?.numberOfCaptureGroups ?? 0)
            let source = text as NSString
            let budget = 8 * 1024 * 1024 - text.utf8.count + source.substring(with: span).utf8.count
            var result = "", bytes = 0, cursor = span.location
            func append(_ part: String) throws {
                bytes += part.utf8.count
                guard bytes <= budget else { throw TextSearchError.tooLarge }
                result += part
            }
            for match in matches {
                try Task.checkCancellation()
                try append(source.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
                let value = options.mode == .regularExpression
                    ? expression!.replacementString(for: match, in: text, offset: 0, template: template)
                    : template
                try append(value)
                cursor = NSMaxRange(match.range)
            }
            return TextReplacementPlan(range: span, replacement: result, count: matches.count)
        }
        return try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
    }

    private static func find(_ text: String, query: String, options: TextSearchOptions, scope: NSRange?) throws -> (NSRegularExpression?, [NSTextCheckingResult]) {
        try Task.checkCancellation()
        guard !query.isEmpty else { return (nil, []) }
        let length = (text as NSString).length, range = scope ?? NSRange(location: 0, length: (text as NSString).length)
        guard range.location != NSNotFound, range.location >= 0, range.length >= 0, range.location <= length, range.length <= length - range.location else { throw TextSearchError.invalidRange }
        var pattern = options.mode == .regularExpression ? query : NSRegularExpression.escapedPattern(for: options.mode == .extended ? try decodeEscapes(query) : query)
        if options.wholeWord { pattern = "(?<![\\p{L}\\p{N}_])(?:" + pattern + ")(?![\\p{L}\\p{N}_])" }
        var flags: NSRegularExpression.Options = [.anchorsMatchLines, .useUnicodeWordBoundaries]
        if !options.caseSensitive { flags.insert(.caseInsensitive) }
        if options.mode == .regularExpression && options.dotMatchesNewline { flags.insert(.dotMatchesLineSeparators) }
        let expression: NSRegularExpression
        do { expression = try NSRegularExpression(pattern: pattern, options: flags) }
        catch { throw TextSearchError.invalidPattern(error.localizedDescription) }
        var matches: [NSTextCheckingResult] = [], failure: Error?
        let deadline = ContinuousClock.now + .seconds(3)
        expression.enumerateMatches(in: text, options: [.reportProgress, .withTransparentBounds, .withoutAnchoringBounds], range: range) { match, _, stop in
            if Task.isCancelled { failure = CancellationError(); stop.pointee = true; return }
            if ContinuousClock.now > deadline { failure = TextSearchError.timedOut; stop.pointee = true; return }
            if let match {
                if matches.count >= 100_000 { failure = TextSearchError.tooManyMatches; stop.pointee = true }
                else { matches.append(match) }
            }
        }
        if let failure { throw failure }
        return (expression, matches)
    }

    private static func decodeEscapes(_ input: String) throws -> String {
        var result = "", iterator = input.makeIterator()
        while let character = iterator.next() {
            guard character == "\\" else { result.append(character); continue }
            guard let escaped = iterator.next() else { throw TextSearchError.invalidEscape }
            switch escaped {
            case "n": result.append("\n")
            case "r": result.append("\r")
            case "t": result.append("\t")
            case "\\": result.append("\\")
            default: throw TextSearchError.invalidEscape
            }
        }
        return result
    }

    private static func replacementTemplate(_ input: String, mode: TextSearchOptions.Mode, captures: Int) throws -> String {
        guard mode == .regularExpression else { return mode == .extended ? try decodeEscapes(input) : input }
        let characters = Array(input)
        var index = 0, output = ""
        while index < characters.count {
            let character = characters[index]; index += 1
            if character == "$" || character == "\\" {
                guard index < characters.count else {
                    if character == "$" { output += "\\$"; continue }
                    throw TextSearchError.invalidEscape
                }
                if characters[index].isASCII && characters[index].isNumber {
                    var digits = ""
                    while index < characters.count, characters[index].isASCII, characters[index].isNumber { digits.append(characters[index]); index += 1 }
                    guard let group = Int(digits), group <= captures else { throw TextSearchError.invalidCapture(Int(digits) ?? Int.max) }
                    output += "$" + digits
                } else if character == "\\" {
                    let next = characters[index]; index += 1
                    switch next {
                    case "n": output += "\n"
                    case "r": output += "\r"
                    case "t": output += "\t"
                    case "\\": output += "\\\\"
                    case "$": output += "\\$"
                    default: throw TextSearchError.invalidEscape
                    }
                } else if characters[index] == "$" { output += "\\$"; index += 1 }
                else { output += "\\$" }
            } else { output.append(character) }
        }
        return output
    }
}
