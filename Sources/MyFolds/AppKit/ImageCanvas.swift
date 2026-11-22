import SwiftUI

struct ImageCanvas: NSViewRepresentable {
    let image: NSImage
    let actualSize: Bool
    func makeNSView(context: Context) -> ZoomingImageScrollView { ZoomingImageScrollView() }
    func updateNSView(_ view: ZoomingImageScrollView, context: Context) { view.show(image, actualSize: actualSize) }
}
