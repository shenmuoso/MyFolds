import SwiftUI

enum BrowserMotion {
    static func feedback(_ reduced: Bool) -> Animation { .easeOut(duration: reduced ? 0.10 : 0.14) }
    static func content(_ reduced: Bool) -> Animation { .easeOut(duration: reduced ? 0.10 : 0.20) }
    static func layout(_ reduced: Bool) -> Animation { .easeInOut(duration: reduced ? 0.10 : 0.28) }
    static func insertion(_ reduced: Bool, edge: Edge = .trailing) -> AnyTransition {
        reduced ? .opacity : .move(edge: edge).combined(with: .opacity)
    }
}

private struct MyFoldsReduceMotionKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var myfoldsReduceMotion: Bool {
        get { self[MyFoldsReduceMotionKey.self] }
        set { self[MyFoldsReduceMotionKey.self] = newValue }
    }
}
private struct MotionPreference: ViewModifier {
    let preferences: Preferences
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    func body(content: Content) -> some View {
        content.environment(\.myfoldsReduceMotion, systemReduced || preferences.reduceMotion)
    }
}
extension View {
    func browserMotionPreference(_ preferences: Preferences) -> some View { modifier(MotionPreference(preferences: preferences)) }
}
