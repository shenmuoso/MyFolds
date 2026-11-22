import SwiftUI

struct AppearanceChoice: View {
    @Environment(\.myfoldsAccentColor) private var accent
    let title: String
    let mode: String
    @Bindable var preferences: Preferences
    var body: some View {
        Button { preferences.appearance = mode } label: {
            VStack(spacing: 7) {
                ZStack {
                    miniature(dark: mode == "dark")
                    if mode == "system" { miniature(dark: true).mask { HStack(spacing: 0) { Color.clear; Color.black } } }
                }.frame(width: 84, height: 56).clipShape(.rect(cornerRadius: 6))
                    .overlay { RoundedRectangle(cornerRadius: 7).stroke(preferences.appearance == mode ? accent : Color.clear, lineWidth: 3).padding(-3) }
                Text(title).font(.system(size: 11, weight: preferences.appearance == mode ? .semibold : .regular)).foregroundStyle(.primary)
            }
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityAddTraits(preferences.appearance == mode ? .isSelected : [])
    }
    private func miniature(dark: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Color(red: dark ? 0.24 : 0.78, green: dark ? 0.27 : 0.74, blue: dark ? 0.29 : 0.69)
            if let url = Bundle.main.url(forResource: "wallpaper", withExtension: "svg"), let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFill().opacity(dark ? 0.15 : 0.7)
            }
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Rectangle().fill(accent).frame(height: 3)
                    Rectangle().fill(Color.gray.opacity(0.45)).frame(height: 3)
                    Rectangle().fill(Color.gray.opacity(0.45)).frame(height: 3)
                }.padding(3).frame(width: 18, height: 46).background(dark ? Color(white: 0.27) : Color(white: 0.86))
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 3)
                    Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 25, height: 3)
                    Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 3)
                }.padding(.horizontal, 5).frame(width: 54, height: 46).background(dark ? Color(white: 0.19) : Color(white: 0.95))
            }.clipShape(.rect(cornerRadius: 4)).offset(x: 4, y: 5)
        }
    }
}
