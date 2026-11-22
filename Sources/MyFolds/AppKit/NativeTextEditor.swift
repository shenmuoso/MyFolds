import SwiftUI

struct NativeTextEditor: NSViewRepresentable {
    @Bindable var document: TextDocumentSession
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme
    func makeCoordinator() -> EditorCoordinator { EditorCoordinator(document: document, preferences: preferences) }
    func makeNSView(context: Context) -> EditorScrollView {
        let scroll = EditorScrollView(); scroll.drawsBackground = false
        scroll.clipsToBounds = true
        scroll.contentView.clipsToBounds = true
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = false
        let text = EditorTextView(frame: .zero)
        text.isRichText = false; text.importsGraphics = false; text.allowsUndo = true
        text.isAutomaticQuoteSubstitutionEnabled = false; text.isAutomaticDashSubstitutionEnabled = false
        text.isAutomaticTextReplacementEnabled = false; text.isAutomaticSpellingCorrectionEnabled = false
        text.drawsBackground = false; text.textContainerInset = NSSize(width: 16, height: 20)
        text.font = preferences.editor.font(size: document.fontSizeOverride)
        text.textColor = .labelColor; text.insertionPointColor = .labelColor
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]; text.textContainer?.widthTracksTextView = true
        text.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        text.minSize = .zero; text.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        text.layoutManager?.allowsNonContiguousLayout = true
        text.layoutManager?.backgroundLayoutEnabled = false
        text.delegate = context.coordinator; text.string = document.text
        text.setSelectedRange(NSRange(location: 0, length: 0))
        text.setAccessibilityLabel("文稿内容")
        scroll.documentView = text
        let ruler = EditorLineNumberRuler(scrollView: scroll, orientation: .verticalRuler)
        ruler.clipsToBounds = true
        ruler.clientView = text; scroll.verticalRulerView = ruler
        scroll.hasVerticalRuler = true; scroll.rulersVisible = preferences.editor.showLineNumbers
        scroll.onZoom = { [weak document, weak preferences] delta in
            guard let document, let preferences else { return }
            document.fontSizeOverride = min(72, max(8, (document.fontSizeOverride ?? preferences.editor.fontSize) + delta))
        }
        scroll.onViewportChange = { [weak document, weak coordinator = context.coordinator] in
            document?.search.redrawHighlights()
            coordinator?.highlighting.redraw()
        }
        context.coordinator.token = document.reloadToken
        context.coordinator.dark = scheme == .dark
        context.coordinator.refreshLines(text)
        document.search.attach(text)
        return scroll
    }
    func updateNSView(_ scroll: EditorScrollView, context: Context) {
        guard let text = scroll.documentView as? EditorTextView else { return }
        let font = preferences.editor.font(size: document.fontSizeOverride)
        context.coordinator.applyFont(font, to: text)
        text.insertionPointColor = .labelColor
        scroll.zoomEnabled = preferences.editor.scrollToZoom
        if scroll.rulersVisible != preferences.editor.showLineNumbers { scroll.rulersVisible = preferences.editor.showLineNumbers }
        (scroll.verticalRulerView as? EditorLineNumberRuler)?.update(index: context.coordinator.lineIndex, fontSize: font.pointSize)
        context.coordinator.dark = scheme == .dark
        if context.coordinator.token != document.reloadToken {
            text.string = document.text; text.undoManager?.removeAllActions(); context.coordinator.token = document.reloadToken
            text.setSelectedRange(NSRange(location: 0, length: 0))
            context.coordinator.highlighting.invalidate(); context.coordinator.refreshLines(text)
            document.search.contentChanged(reloaded: true)
        }
        context.coordinator.highlighting.refresh(text, text: document.text, language: document.syntaxLanguage, dark: scheme == .dark)
    }
    static func dismantleNSView(_ view: EditorScrollView, coordinator: EditorCoordinator) {
        view.onZoom = nil; view.onViewportChange = nil; coordinator.cancel()
    }
}
