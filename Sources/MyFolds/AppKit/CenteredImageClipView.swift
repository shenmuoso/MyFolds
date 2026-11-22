import AppKit

final class CenteredImageClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let documentView {
            if documentView.frame.width < rect.width { rect.origin.x = (documentView.frame.width - rect.width) / 2 }
            if documentView.frame.height < rect.height { rect.origin.y = (documentView.frame.height - rect.height) / 2 }
        }
        return rect
    }
}
