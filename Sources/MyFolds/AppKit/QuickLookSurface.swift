import SwiftUI
import Quartz

struct QuickLookSurface: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> QLPreviewView { QLPreviewView(frame: .zero, style: .normal) }
    func updateNSView(_ view: QLPreviewView, context: Context) { view.previewItem = url as NSURL; view.autostarts = false }
    static func dismantleNSView(_ view: QLPreviewView, coordinator: ()) { view.close() }
}
