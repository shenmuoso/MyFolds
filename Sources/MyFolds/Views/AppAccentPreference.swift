import SwiftUI

extension EnvironmentValues {
    @Entry var myfoldsAccentColor: Color = .accentColor
    @Entry var myfoldsSelectionText: Color = .white
    @Entry var myfoldsSubtleAccent: Color = .accentColor.opacity(0.16)
    @Entry var myfoldsAccentInk: Color = .accentColor
}

struct AppAccentPreference: ViewModifier {
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme
    @State private var systemColorRevision = 0

    func body(content: Content) -> some View {
        let palette = resolvedPalette(revision: systemColorRevision)
        content.tint(palette.fill)
            .environment(\.myfoldsAccentColor, palette.fill)
            .environment(\.myfoldsSelectionText, palette.text)
            .environment(\.myfoldsSubtleAccent, palette.fill.opacity(scheme == .dark ? 0.24 : 0.16))
            .environment(\.myfoldsAccentInk, palette.fill.mix(with: scheme == .dark ? .white : .black, by: scheme == .dark ? 0.45 : 0.55))
            .onReceive(NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)) { _ in systemColorRevision += 1 }
    }

    private func resolvedPalette(revision: Int) -> SelectionPalette {
        preferences.accent.palette(appearance: NSAppearance(named: scheme == .dark ? .darkAqua : .aqua))
    }
}

extension View {
    func appAccentPreference(_ preferences: Preferences) -> some View { modifier(AppAccentPreference(preferences: preferences)) }
}
