import SwiftUI

struct EditorResultsDivider: NSViewRepresentable {
    @Binding var height: CGFloat
    var maximum: CGFloat
    func makeNSView(context: Context) -> EditorResultsDividerView { EditorResultsDividerView() }
    func updateNSView(_ view: EditorResultsDividerView, context: Context) {
        view.height = height; view.maximum = maximum
        view.onResize = { height = $0 }
    }
}
