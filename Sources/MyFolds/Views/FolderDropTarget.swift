import SwiftUI
import MyFoldsCore

struct FolderDropTarget: ViewModifier {
    let item: FileItem
    let model: BrowserModel
    @State private var targeted = false
    @Environment(\.myfoldsAccentColor) private var accent
    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            .background(targeted ? accent.opacity(0.16) : .clear, in: .rect(cornerRadius: 8))
            .overlay {
                if targeted { RoundedRectangle(cornerRadius: 8).strokeBorder(accent, lineWidth: 1.5).allowsHitTesting(false) }
            }
            .onDrop(of: [.fileURL], delegate: FileDropDelegate(model: model, directory: item.directoryTarget, targeted: $targeted))
    }
}
