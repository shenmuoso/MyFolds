import SwiftUI

struct ToolbarSymbol: View {
    let title: String
    let symbol: String
    var selected = false
    var width: CGFloat = 31
    let action: () -> Void
    init(_ title: String, symbol: String, selected: Bool = false, width: CGFloat = 31, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.selected = selected; self.width = width; self.action = action
    }
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .regular))
                .frame(width: width, height: 29)
                .background(selected ? Color.primary.opacity(0.09) : .clear, in: .capsule)
        }.buttonStyle(QuietButtonStyle()).help(title).accessibilityLabel(title)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
