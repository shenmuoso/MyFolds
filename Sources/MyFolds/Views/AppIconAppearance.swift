import SwiftUI

struct AppIconAppearance: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.onChange(of: scheme, initial: true) {
            AppIconProvider.updateRunningIcon(dark: scheme == .dark)
        }
    }
}
