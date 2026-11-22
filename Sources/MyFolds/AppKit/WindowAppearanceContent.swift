import SwiftUI

struct WindowAppearanceContent<Content: View>: View {
    @Bindable var appearance: WindowAppearanceState
    let content: Content
    var body: some View { content.environment(\.colorScheme, appearance.scheme) }
}
