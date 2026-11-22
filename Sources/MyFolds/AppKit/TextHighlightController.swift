import AppKit
import MyFoldsCore

@MainActor
final class TextHighlightController {
    private var task: Task<Void, Never>?
    private var revision = 0
    private var requestedRevision = -1
    private var requestedLanguage: SyntaxLanguage?
    private var requestedDark: Bool?
    private var generation = UUID()

    func invalidate() { revision += 1; task?.cancel(); generation = UUID() }
    func cancel() { task?.cancel(); generation = UUID() }

    func refresh(_ view: NSTextView, text: String, language: SyntaxLanguage, dark: Bool) {
        guard !view.hasMarkedText(), revision != requestedRevision || language != requestedLanguage || dark != requestedDark else { return }
        requestedRevision = revision; requestedLanguage = language; requestedDark = dark
        task?.cancel()
        let request = UUID(); generation = request
        task = Task { [weak self, weak view] in
            do {
                try await Task.sleep(for: .milliseconds(90))
                let tokens = try await SyntaxHighlighter.highlight(text, language: language)
                try Task.checkCancellation()
                guard let self, self.generation == request, let view, !view.hasMarkedText(), let layout = view.layoutManager else { return }
                let length = (text as NSString).length
                layout.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(location: 0, length: length))
                // Temporary drawing attributes preserve selection, undo history,
                // marked text and the document's plain-text saving semantics.
                for (index, token) in tokens.enumerated() {
                    if index % 512 == 0 {
                        await Task.yield()
                        try Task.checkCancellation()
                        guard self.generation == request else { return }
                    }
                    layout.addTemporaryAttribute(.foregroundColor, value: SyntaxPalette.color(token.kind, dark: dark), forCharacterRange: token.range)
                }
            } catch { /* A newer edit or language/theme change owns the next result. */ }
        }
    }
}
