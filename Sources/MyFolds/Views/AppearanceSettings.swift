import SwiftUI

struct AppearanceSettings: View {
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    Text("外观").padding(.top, 4); Spacer()
                    AppearanceChoice(title: "浅色", mode: "light", preferences: preferences)
                    AppearanceChoice(title: "深色", mode: "dark", preferences: preferences)
                    AppearanceChoice(title: "自动", mode: "system", preferences: preferences)
                }.padding(.horizontal, 14).padding(.top, 16)
                Text("选择“自动”时，外观跟随系统变化。").font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 14).padding(.bottom, 12)
            }
            AccentColorSettings(preferences: preferences)
            VStack(alignment: .leading, spacing: 8) {
                Text("浏览").font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
                VStack(spacing: 0) {
                    HStack {
                        Text("列表密度"); Spacer()
                        Picker("列表密度", selection: $preferences.compact) { Text("舒适").tag(false); Text("紧凑").tag(true) }
                            .labelsHidden().pickerStyle(.menu).frame(width: 85)
                    }.frame(minHeight: 46)
                    Divider().opacity(preferences.increaseContrast ? 1 : 0.25)
                    HStack { Text("显示隐藏文件"); Spacer(); Toggle("显示隐藏文件", isOn: $preferences.showHidden).labelsHidden() }.frame(minHeight: 46)
                }.padding(.horizontal, 12).background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(preferences.increaseContrast ? 0.22 : 0), lineWidth: 1).allowsHitTesting(false) }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("辅助功能").font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("减少透明度")
                            Text("使用更实的背景，让内容更容易辨认。").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("减少透明度", isOn: $preferences.reduceTransparency).labelsHidden()
                    }.padding(.vertical, 10)
                    Divider().opacity(preferences.increaseContrast ? 1 : 0.25)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("减少动态效果")
                            Text("用轻微淡入替代位移，也遵循系统设置。").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("减少动态效果", isOn: $preferences.reduceMotion).labelsHidden()
                    }.padding(.vertical, 10)
                    Divider().opacity(preferences.increaseContrast ? 1 : 0.25)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("提高对比度")
                            Text("增强内容与控件边界的对比。").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("提高对比度", isOn: $preferences.increaseContrast).labelsHidden()
                    }.padding(.vertical, 10)
                }.padding(.horizontal, 12).background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(preferences.increaseContrast ? 0.22 : 0), lineWidth: 1).allowsHitTesting(false) }
            }
        }.font(.system(size: 13)).toggleStyle(.switch).controlSize(.small)
    }
}
