import AppKit

final class EditorScrollView: NSScrollView {
    var zoomEnabled = true
    var onZoom: ((Double) -> Void)?
    var onViewportChange: (() -> Void)?
    private var accumulatedScroll = 0.0
    override func scrollWheel(with event: NSEvent) {
        guard zoomEnabled, !event.modifierFlags.intersection([.command, .control]).isEmpty else {
            accumulatedScroll = 0; super.scrollWheel(with: event); return
        }
        guard event.momentumPhase.isEmpty else { return }
        accumulatedScroll += Double(event.scrollingDeltaY) / (event.hasPreciseScrollingDeltas ? 12 : 1)
        let steps = accumulatedScroll.rounded(.towardZero)
        if steps != 0 { accumulatedScroll -= steps; onZoom?(steps) }
    }
    override func reflectScrolledClipView(_ clipView: NSClipView) {
        super.reflectScrolledClipView(clipView)
        verticalRulerView?.needsDisplay = true
        onViewportChange?()
    }
}
