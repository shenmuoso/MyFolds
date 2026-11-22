import AppKit
import MyFoldsCore

@MainActor
final class TextHighlightController {
    private var task: Task<Void, Never>?
    private var revision = 0
    private var requestedRevision = -1
    private var requestedLanguage: SyntaxLanguage?
    private var dark = false
    private var generation = UUID()
    private var tokens: [SyntaxToken] = []
    private var paintedRange: NSRange?
    private weak var view: NSTextView?

    func invalidate() { revision += 1; task?.cancel(); generation = UUID() }
    func cancel() { task?.cancel(); generation = UUID(); view = nil }

    func refresh(_ view: NSTextView, text: String, language: SyntaxLanguage, dark: Bool) {
        self.view = view
        let themeChanged = self.dark != dark
        self.dark = dark
        guard !view.hasMarkedText() else { return }
        guard revision != requestedRevision || language != requestedLanguage else {
            if themeChanged { redraw(force: true) }
            return
        }
        requestedRevision = revision; requestedLanguage = language
        task?.cancel()
        let request = UUID(); generation = request
        task = Task { [weak self, weak view] in
            do {
                try await Task.sleep(for: .milliseconds(90))
                let tokens = try await SyntaxHighlighter.highlight(text, language: language)
                try Task.checkCancellation()
                guard let self, self.generation == request, let view, !view.hasMarkedText() else { return }
                // Keep parsing off the main actor; only paint the visible lines.
                // Font changes and scrolling reuse these tokens.
                self.tokens = tokens
                view.layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(location: 0, length: view.textStorage?.length ?? 0))
                paintedRange = nil
                redraw(force: true)
            } catch { }
        }
    }

    func redraw(force: Bool = false) {
        guard let view, !view.hasMarkedText(), let layout = view.layoutManager, let container = view.textContainer else { return }
        let length = view.textStorage?.length ?? 0
        let bounds = view.visibleRect.offsetBy(dx: -view.textContainerOrigin.x, dy: -view.textContainerOrigin.y)
        guard bounds.width > 0, bounds.height > 0 else { return }
        let glyphs = layout.glyphRange(forBoundingRect: bounds, in: container)
        let visible = NSIntersectionRange(layout.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil), NSRange(location: 0, length: length))
        guard force || visible != paintedRange else { return }
        if let paintedRange {
            layout.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSIntersectionRange(paintedRange, NSRange(location: 0, length: length)))
        }
        paintedRange = visible
        var low = 0, high = tokens.count
        while low < high {
            let middle = (low + high) / 2
            if NSMaxRange(tokens[middle].range) <= visible.location { low = middle + 1 } else { high = middle }
        }
        for token in tokens.dropFirst(low) {
            if token.range.location >= NSMaxRange(visible) { break }
            let range = NSIntersectionRange(token.range, visible)
            if range.length > 0 { layout.addTemporaryAttribute(.foregroundColor, value: SyntaxPalette.color(token.kind, dark: dark), forCharacterRange: range) }
        }
    }
}
