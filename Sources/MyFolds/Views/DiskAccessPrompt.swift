import SwiftUI

struct DiskAccessPrompt: View {
    let action: () -> Void
    @Environment(\.myfoldsAccentColor) private var accent
    @Environment(\.myfoldsSubtleAccent) private var subtleAccent
    @Environment(\.myfoldsAccentInk) private var accentInk
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            Label("打开磁盘权限", systemImage: "exclamationmark.shield")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accentInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).frame(height: 30).contentShape(.rect)
                .background(accent.opacity(hovered ? 0.10 : 0), in: .rect(cornerRadius: 7))
                .background(subtleAccent, in: .rect(cornerRadius: 7))
        }.buttonStyle(.plain).onHover { hovered = $0 }
            .help("前往系统设置，为 MyFolds 开启完全磁盘访问权限")
            .accessibilityIdentifier("sidebar.diskAccess")
    }
}
