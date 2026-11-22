import AppKit
import MyFoldsCore

final class EditorLineNumberRuler: NSRulerView {
    var lineIndex = TextLineIndex()
    private var numberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        bounds.clip()
        drawHashMarksAndLabels(in: dirtyRect)
        NSGraphicsContext.restoreGraphicsState()
    }
    func update(index: TextLineIndex, fontSize: Double) {
        lineIndex = index
        numberFont = .monospacedDigitSystemFont(ofSize: min(14, max(9, fontSize - 2)), weight: .regular)
        let digits = max(3, String(index.starts.count).count)
        ruleThickness = ceil((String(repeating: "8", count: digits) as NSString).size(withAttributes: [.font: numberFont]).width) + 24
        needsDisplay = true
    }
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let text = clientView as? NSTextView, let layout = text.layoutManager, let container = text.textContainer else { return }
        NSColor.labelColor.withAlphaComponent(0.025).setFill(); bounds.fill()
        let length = (text.string as NSString).length
        let glyphs = layout.glyphRange(forBoundingRect: text.visibleRect.offsetBy(dx: -text.textContainerOrigin.x, dy: -text.textContainerOrigin.y), in: container)
        let visible = layout.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
        let first = lineIndex.line(at: visible.location)
        let activeLine = lineIndex.line(at: text.selectedRange().location)
        for index in first..<lineIndex.starts.count {
            let offset = lineIndex.starts[index]
            if offset > NSMaxRange(visible) || offset > length { break }
            let fragment: NSRect
            if offset == length { fragment = layout.extraLineFragmentRect }
            else { fragment = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: offset), effectiveRange: nil) }
            let origin = convert(NSPoint(x: text.textContainerOrigin.x, y: text.textContainerOrigin.y + fragment.minY), from: text)
            let label = "\(index + 1)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: numberFont, .foregroundColor: index == activeLine ? NSColor.labelColor : NSColor.secondaryLabelColor]
            let size = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: ruleThickness - 12 - size.width, y: origin.y + max(0, (fragment.height - size.height) / 2)), withAttributes: attributes)
        }
    }
}
