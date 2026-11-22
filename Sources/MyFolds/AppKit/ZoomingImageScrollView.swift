import AppKit

final class ZoomingImageScrollView: NSScrollView {
    private let imageView = NSImageView()
    private var actualSize = false
    private var lastViewport = NSSize.zero
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        drawsBackground = false; hasVerticalScroller = true; hasHorizontalScroller = true
        allowsMagnification = true; minMagnification = 0.02; maxMagnification = 8
        let clip = CenteredImageClipView(); clip.drawsBackground = false; contentView = clip
        imageView.imageScaling = .scaleNone; documentView = imageView
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    func show(_ image: NSImage, actualSize: Bool) {
        guard imageView.image !== image || self.actualSize != actualSize else { return }
        imageView.image = image; imageView.frame = NSRect(origin: .zero, size: image.size)
        self.actualSize = actualSize; fit()
    }
    override func layout() {
        super.layout()
        if contentSize != lastViewport { lastViewport = contentSize; fit() }
    }
    private func fit() {
        guard let image = imageView.image, contentSize.width > 0, contentSize.height > 0 else { return }
        let pixels = window?.backingScaleFactor ?? 2
        let scale = actualSize ? 1 / pixels : min(contentSize.width / image.size.width, contentSize.height / image.size.height, 1)
        magnification = max(minMagnification, scale)
        let bounds = contentView.bounds
        contentView.scroll(to: NSPoint(x: (image.size.width - bounds.width) / 2, y: (image.size.height - bounds.height) / 2))
    }
}
