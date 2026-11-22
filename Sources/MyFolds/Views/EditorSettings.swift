import SwiftUI

struct EditorSettings: View {
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme
    @State private var fontFamilies: [String] = []
    @State private var shortcutError: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            section("文本显示") {
                HStack {
                    Text("显示行号"); Spacer()
                    Toggle("显示行号", isOn: $preferences.editor.showLineNumbers).labelsHidden()
                }
                HStack {
                    Text("字体"); Spacer()
                    Picker("字体", selection: $preferences.editor.fontFamily) {
                        Text("系统等宽字体").tag("system-monospace")
                        Divider()
                        ForEach(fontFamilies, id: \.self) { Text($0).tag($0) }
                    }.labelsHidden().frame(maxWidth: 230)
                }
                HStack {
                    Text("字号"); Spacer()
                    TextField("字号", value: $preferences.editor.fontSize, format: .number)
                        .textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing).frame(width: 52)
                    Text("pt").foregroundStyle(.secondary)
                    Stepper("调整字号", value: $preferences.editor.fontSize, in: 8...72, step: 1).labelsHidden().fixedSize()
                }
                Text("Aa 你好 0123  { file: \"MyFolds\" }")
                    .font(Font(preferences.editor.font())).lineLimit(1).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 10).background(.primary.opacity(0.04), in: .rect(cornerRadius: 6))
            }
            section("外观与缩放") {
                HStack {
                    Text("外观"); Spacer()
                    Picker("外观", selection: $preferences.editor.appearance) {
                        Text("跟随 MyFolds").tag("app")
                        Text("跟随系统").tag("system")
                        Text("浅色").tag("light")
                        Text("深色").tag("dark")
                    }.labelsHidden().frame(width: 142)
                }
                HStack {
                    Text("⌃ / ⌘ + 滚轮缩放"); Spacer()
                    Toggle("Control / Command + 滚轮调整字号", isOn: $preferences.editor.scrollToZoom).labelsHidden()
                }.help("仅调整当前文稿；点击底部字号恢复默认。")
            }
            section("快捷键") {
                HStack {
                    Text("查找"); Spacer()
                    EditorShortcutRecorder(shortcut: $preferences.editor.findShortcut, other: preferences.editor.replaceShortcut, label: "设置查找快捷键", error: $shortcutError).frame(width: 142, height: 26)
                }
                HStack {
                    Text("替换"); Spacer()
                    EditorShortcutRecorder(shortcut: $preferences.editor.replaceShortcut, other: preferences.editor.findShortcut, label: "设置替换快捷键", error: $shortcutError).frame(width: 142, height: 26)
                }
                if let shortcutError { Text(shortcutError).foregroundStyle(.red).font(.system(size: 11)) }
                HStack {
                    Text("点击录入，Esc 取消。").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Button("恢复默认") {
                        var editor = preferences.editor; editor.findShortcut = .find; editor.replaceShortcut = .replace
                        preferences.editor = editor; shortcutError = nil
                    }.buttonStyle(.borderless)
                }
            }
        }.font(.system(size: 13)).controlSize(.small).toggleStyle(.switch)
            .task { fontFamilies = NSFontManager.shared.availableFontFamilies.sorted { $0.localizedStandardCompare($1) == .orderedAscending } }
    }
    private func section<Content: View>(_ title: String, @ContentBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
            VStack(alignment: .leading, spacing: 12, content: content)
                .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
        }
    }
}
