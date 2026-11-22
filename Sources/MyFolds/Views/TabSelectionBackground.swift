import SwiftUI

// The selection travels within the tab strip; the files themselves crossfade.
// Reduce Motion makes this position change immediate while text keeps its short
// color feedback. Debug traces sample the actual interpolated position.
struct TabSelectionBackground: View, Animatable {
    @Environment(\.myfoldsAccentColor) private var accent
    nonisolated var position: CGFloat
    nonisolated let reduced: Bool
    nonisolated var animatableData: CGFloat {
        get { position }
        set {
            position = newValue
            #if DEBUG
            MotionDiagnostics.record(position: Double(newValue), reduced: reduced)
            #endif
        }
    }
    var body: some View {
        RoundedRectangle(cornerRadius: 8).fill(accent)
            .frame(width: BrowserChrome.tabWidth, height: BrowserChrome.controlHeight).offset(x: position)
            .allowsHitTesting(false)
    }
}
