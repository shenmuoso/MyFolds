import SwiftUI

struct AccentColorSettings: View {
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("强调色")
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    ForEach(AppAccent.allCases, id: \.self) { choice in
                        AccentColorSwatch(choice: choice, selected: preferences.accent == choice) { preferences.accent = choice }
                    }
                }
            }
            HStack {
                Text("用于标签页、地址栏、侧边栏、文件选中和权限提示。")
                Spacer(minLength: 4)
                Text(preferences.accent.title)
            }.font(.system(size: 11)).foregroundStyle(.secondary)
        }.padding(12)
            .background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
    }
}
