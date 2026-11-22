import SwiftUI

struct EditorStatusBar: View {
    @Bindable var document: TextDocumentSession
    @Bindable var preferences: Preferences
    var body: some View {
        HStack(spacing: 16) {
            Text("行 \(document.cursorLine)，列 \(document.cursorColumn)").monospacedDigit()
            Text(document.encoding.label)
            Spacer()
            Button("\((document.fontSizeOverride ?? preferences.editor.fontSize).formatted()) pt") { document.fontSizeOverride = nil }
                .buttonStyle(.borderless).help("恢复默认字号 \(preferences.editor.fontSize.formatted()) pt")
                .accessibilityLabel("当前字号，点击恢复默认大小")
        }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 18).frame(height: 28)
    }
}
