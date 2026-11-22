import SwiftUI

/// The scroll viewport grows with the tabs until the trailing button needs
/// the remaining space. Overflow never pushes the button out of the pane.
struct TabStripLayout: Layout {
    let contentWidth: CGFloat
    private let spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let button = subviews[1].sizeThatFits(.unspecified)
        return CGSize(width: proposal.width ?? contentWidth + spacing + button.width,
                      height: BrowserChrome.controlHeight + 8)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let button = subviews[1].sizeThatFits(.unspecified)
        let viewport = min(contentWidth, max(0, bounds.width - spacing - button.width))
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: viewport, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.minX + viewport + spacing, y: bounds.midY),
                          anchor: .leading, proposal: ProposedViewSize(button))
    }
}
