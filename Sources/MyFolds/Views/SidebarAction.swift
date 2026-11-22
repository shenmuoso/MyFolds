import SwiftUI

struct SidebarAction: View {
    @Environment(\.myfoldsSelectionText) private var selectionText
    @Environment(\.myfoldsAccentColor) private var accent
    let title: String
    let symbol: String
    var helpText: String?
    var selected = false
    var trailingAction: (() -> Void)?
    var trailingBusy = false
    let action: () -> Void
    @State private var hovered = false
    init(_ title: String, symbol: String, helpText: String? = nil, selected: Bool = false, trailingAction: (() -> Void)? = nil, trailingBusy: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.selected = selected; self.action = action
        self.helpText = helpText
        self.trailingAction = trailingAction; self.trailingBusy = trailingBusy
    }
    var body: some View {
        HStack(spacing: 0) {
          Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(selected ? selectionText : Color.secondary).frame(width: 19)
                Text(title).font(.system(size: 13, weight: selected ? .medium : .regular)).lineLimit(1)
                Spacer(minLength: 0)
            }.padding(.leading, 10).padding(.trailing, trailingAction == nil ? 10 : 0).frame(height: 30).contentShape(.rect)
          }.accessibilityAddTraits(selected ? .isSelected : []).help(helpText ?? title)
          if let trailingAction {
              Button(action: trailingAction) {
                  Group {
                      if trailingBusy { ProgressView().controlSize(.mini) }
                      else { Image(systemName: "eject").font(.system(size: 12, weight: .medium)) }
                  }.frame(width: 27, height: 30).contentShape(.rect)
              }.disabled(trailingBusy).help("弹出“\(title)”").accessibilityLabel("弹出“\(title)”")
          }
        }.foregroundStyle(selected ? selectionText : Color.primary)
            .background(selected ? accent : Color.primary.opacity(hovered ? 0.08 : 0), in: .rect(cornerRadius: 7))
            .buttonStyle(.plain).onHover { hovered = $0 }
    }
}
