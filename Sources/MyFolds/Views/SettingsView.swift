import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: Preferences
    let access: FileAccessManager
    @Environment(\.myfoldsReduceMotion) private var reduced
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack { WindowControls().frame(width: 70, height: 22); Spacer() }.padding(.horizontal, 17).frame(height: 52)
                    .background { WindowDragArea() }
                VStack(spacing: 4) {
                    settingTab("外观", symbol: "circle.lefthalf.filled")
                    settingTab("打开方式", symbol: "app")
                    settingTab("文本编辑器", symbol: "doc.text")
                    settingTab("快捷键", symbol: "keyboard")
                    settingTab("文件访问", symbol: "lock.shield")
                }.padding(.horizontal, 10).padding(.top, 8)
                Spacer()
                HStack(spacing: 7) {
                    Image(AppIconProvider.assetName, bundle: .main).resizable().frame(width: 20, height: 20)
                    Text("MyFolds").font(.system(size: 12)).foregroundStyle(.secondary)
                    Spacer()
                }.padding(18)
            }.frame(width: 190).background(Color.white.opacity(0.035))
            VStack(alignment: .leading, spacing: 0) {
                Text(preferences.settingsSection).font(.system(size: 16, weight: .semibold)).padding(.horizontal, 24).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background { WindowDragArea() }
                ScrollView {
                    Group {
                        switch preferences.settingsSection {
                        case "打开方式": OpeningSettings(preferences: preferences)
                        case "文本编辑器": EditorSettings(preferences: preferences)
                        case "快捷键": ShortcutSettings(preferences: preferences)
                        case "文件访问": AccessSettings(access: access)
                        default: AppearanceSettings(preferences: preferences)
                        }
                    }.id(preferences.settingsSection).transition(.opacity).padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background((scheme == .dark ? Color(white: 0.12) : Color(red: 0.945, green: 0.941, blue: 0.929)).opacity(preferences.increaseContrast ? 0.45 : 0.08))
        }
        .animation(BrowserMotion.content(reduced), value: preferences.settingsSection)
        .appAccentPreference(preferences)
        .modifier(AppIconAppearance())
        .frame(width: 760, height: 552)
        .ignoresSafeArea()
        .onExitCommand { NSApp.keyWindow?.performClose(nil) }
    }
    private func settingTab(_ title: String, symbol: String) -> some View {
        SidebarAction(title, symbol: symbol, selected: preferences.settingsSection == title) { preferences.settingsSection = title }.padding(.vertical, 2)
    }
}
