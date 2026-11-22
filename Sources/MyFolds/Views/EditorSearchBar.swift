import SwiftUI
import MyFoldsCore

struct EditorSearchBar: View {
    @Bindable var search: EditorSearchModel
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                EditorSearchField(text: $search.query, focusRequest: search.focusRequest) { search.navigate() }
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                if search.searching || search.replacing { ProgressView().controlSize(.small).frame(width: 16) }
                Text(search.status).foregroundStyle(.secondary).monospacedDigit().lineLimit(1).frame(minWidth: 75)
                Button("上一个", systemImage: "chevron.up") { search.navigate(backward: true) }.labelStyle(.iconOnly).disabled(!search.ready).help("上一个匹配 ⇧⌘G")
                Button("下一个", systemImage: "chevron.down") { search.navigate() }.labelStyle(.iconOnly).disabled(!search.ready).help("下一个匹配 ⌘G / Return")
                Button("关闭查找", systemImage: "xmark") { search.close() }.labelStyle(.iconOnly).buttonStyle(.borderless).help("关闭查找 Esc")
            }
            if search.showsReplace {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.secondary).accessibilityHidden(true)
                    TextField("替换为（留空即删除）", text: $search.replacement).textFieldStyle(.roundedBorder)
                        .onSubmit { search.replace(all: false) }.accessibilityIdentifier("editor.replace")
                    Button("替换") { search.replace(all: false) }.disabled(!search.ready)
                    Button("全部替换") { search.replace(all: true) }.disabled(!search.ready)
                }
            }
            HStack(spacing: 12) {
                Picker("搜索模式", selection: $search.options.mode) {
                    ForEach(TextSearchOptions.Mode.allCases) { Text($0.title).tag($0) }
                }.labelsHidden().frame(width: 112)
                Toggle("区分大小写", isOn: $search.options.caseSensitive)
                Toggle("全词匹配", isOn: $search.options.wholeWord)
                Toggle("循环", isOn: $search.wrap)
                Toggle("仅选区", isOn: $search.selectionOnly).disabled(!search.selectionOnly && search.selection.length == 0)
                Spacer(minLength: 0)
                Button("查找全部") { search.showsResults = true }.disabled(!search.ready)
            }.toggleStyle(.checkbox)
            if search.options.mode == .regularExpression {
                HStack {
                    Toggle(". 匹配换行", isOn: $search.options.dotMatchesNewline).toggleStyle(.checkbox)
                    Text("捕获组：$1、\\1").foregroundStyle(.secondary)
                }
            } else if search.options.mode == .extended {
                Text("\\n 换行 · \\t 制表符 · \\r 回车 · \\\\ 反斜杠").foregroundStyle(.secondary)
            }
            if let error = search.error { Label(error, systemImage: "exclamationmark.circle").foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            else if let message = search.message { Text(message).foregroundStyle(.secondary) }
        }.font(.system(size: 11)).controlSize(.small).padding(.horizontal, 18).padding(.vertical, 12)
            .background(.primary.opacity(0.035))
            .onExitCommand { search.close() }
    }
}
