import SwiftUI

struct AccentColorSwatch: View {
    let choice: AppAccent
    let selected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = choice.palette(appearance: NSAppearance(named: scheme == .dark ? .darkAqua : .aqua))
        Button(action: action) {
            ZStack {
                if choice == .system {
                    Circle().fill(AngularGradient(colors: [.blue, .purple, .pink, .red, .orange, .yellow, .green, .blue], center: .center))
                } else { Circle().fill(palette.fill) }
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(choice == .system ? Color.white : palette.text)
                }
            }.frame(width: 18, height: 18)
                .padding(4)
                .overlay { Circle().strokeBorder(selected ? Color.primary.opacity(0.65) : .clear, lineWidth: 1.5) }
                .contentShape(.circle)
        }.buttonStyle(.plain).help(choice.title)
            .accessibilityLabel("强调色：" + choice.title)
            .accessibilityIdentifier("accent." + choice.rawValue)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
