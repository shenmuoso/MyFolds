import AppKit

final class EditorResultsDividerView: NSView {
    var height: CGFloat = 175
    var maximum: CGFloat = 400
    var onResize: ((CGFloat) -> Void)?
    private var startY: CGFloat = 0
    private var startHeight: CGFloat = 0
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.splitter)
        setAccessibilityLabel("搜索结果高度")
        setAccessibilityHelp("向上或向下拖动以调整结果区域")
    }
    required init?(coder: NSCoder) { nil }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeUpDown) }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.separatorColor.withAlphaComponent(0.45).setFill()
        NSRect(x: 0, y: floor(bounds.midY), width: bounds.width, height: 1).fill()
    }
    override func mouseDown(with event: NSEvent) { startY = event.locationInWindow.y; startHeight = height }
    override func mouseDragged(with event: NSEvent) { resize(to: startHeight + event.locationInWindow.y - startY) }
    override func accessibilityValue() -> Any? { Int(height) }
    override func accessibilityPerformIncrement() -> Bool { resize(to: height + 24); return true }
    override func accessibilityPerformDecrement() -> Bool { resize(to: height - 24); return true }
    func resize(to value: CGFloat) { onResize?(min(maximum, max(80, value))) }
}
