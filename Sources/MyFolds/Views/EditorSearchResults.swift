import SwiftUI

struct EditorSearchResults: View {
    @Bindable var search: EditorSearchModel
    @Environment(\.myfoldsAccentColor) private var accent
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("当前文件 · \(search.result.ranges.count) 处匹配").fontWeight(.medium)
                if search.result.ranges.count > search.result.rows.count { Text("显示前 500 条").foregroundStyle(.secondary) }
                Spacer()
                Button("关闭结果列表", systemImage: "xmark") { search.showsResults = false }.labelStyle(.iconOnly).buttonStyle(.borderless)
            }.padding(.horizontal, 18).frame(height: 32)
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(search.result.rows) { row in
                        Button { search.select(row.id) } label: {
                            HStack(spacing: 12) {
                                Text("\(row.line):\(row.column)").monospacedDigit().foregroundStyle(.secondary).frame(width: 66, alignment: .trailing)
                                Text(row.preview.isEmpty ? "（空行）" : row.preview).font(.system(size: 11, design: .monospaced)).lineLimit(1)
                                Spacer(minLength: 0)
                            }.padding(.vertical, 5).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(search.currentIndex == row.id ? accent.opacity(0.18) : .clear, in: .rect(cornerRadius: 5))
                        }.buttonStyle(.plain).accessibilityLabel("第 \(row.line) 行，第 \(row.column) 列：\(row.preview)")
                    }
                }.padding(.horizontal, 8)
            }
        }.font(.system(size: 11)).frame(height: 175).background(.primary.opacity(0.035))
    }
}
