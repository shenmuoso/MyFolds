import SwiftUI

@MainActor @Observable
final class WindowAppearanceState {
    var scheme: ColorScheme = .light
    func update(_ appearance: NSAppearance) {
        scheme = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
    }
}
