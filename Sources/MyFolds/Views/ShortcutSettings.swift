import SwiftUI

struct ShortcutSettings: View {
    let preferences: Preferences
    private let shortcuts = [
        ["编辑完整路径", "⌘ L"], ["搜索当前文件夹", "⌘ F"], ["打开文件夹", "⌘ O"], ["新建标签页", "⌘ T"], ["关闭标签或窗口", "⌘ W"], ["切换标签", "⌃ Tab / ⇧ ⌃ Tab"],
        ["保存文稿 / 另存为", "⌘ S / ⇧ ⌘ S"],
        ["剪切 / 复制 / 粘贴", "⌘ X / ⌘ C / ⌘ V"], ["复制文件路径", "⌥ ⌘ C"], ["重命名", "Return"],
        ["新建文件夹", "⇧ ⌘ N"], ["移到废纸篓", "⌘ Delete"], ["撤销", "⌘ Z"],
        ["快速预览 / 关闭", "Space / Esc"], ["上一级", "⌘ ↑"], ["显示隐藏文件", "⇧ ⌘ ."], ["设置", "⌘ ,"]
    ]
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text("编辑器查找 / 替换"); Spacer(); Text("\(preferences.editor.findShortcut.label) / \(preferences.editor.replaceShortcut.label)").foregroundStyle(.secondary) }.padding(.vertical, 11)
            HStack { Text("上一个 / 下一个匹配"); Spacer(); Text("⇧ ⌘ G / ⌘ G").foregroundStyle(.secondary) }.padding(.vertical, 11)
            ForEach(shortcuts, id: \.first) { row in
                HStack { Text(row[0]); Spacer(); Text(row[1]).foregroundStyle(.secondary) }.padding(.vertical, 11)
                if row != shortcuts.last { Divider().opacity(0.3) }
            }
        }.font(.system(size: 12))
    }
}
