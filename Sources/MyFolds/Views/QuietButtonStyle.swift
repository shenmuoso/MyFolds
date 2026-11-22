import SwiftUI

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        QuietButtonBody(configuration: configuration)
    }
    private struct QuietButtonBody: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var enabled
        @State private var hovered = false
        var body: some View {
            configuration.label.foregroundStyle(.primary)
                .background(Color.primary.opacity(configuration.isPressed ? 0.12 : hovered ? 0.055 : 0), in: .capsule)
                .opacity(enabled ? 1 : 0.32).contentShape(.capsule).onHover { hovered = $0 }
        }
    }
}
