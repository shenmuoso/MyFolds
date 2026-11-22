import SwiftUI

struct TaskHistoryView: View {
    @Bindable var model: BrowserModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("文件任务").font(.title2); Spacer(); Button("完成") { dismiss() }.keyboardShortcut(.cancelAction) }
            if model.busy { OperationBar(model: model) }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if model.taskHistory.isEmpty { Text("本次会话暂无已完成任务。 ").foregroundStyle(.secondary) }
                    ForEach(Array(model.taskHistory.enumerated()), id: \.offset) { _, text in Text(text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                }
            }
        }.padding(24).frame(width: 560, height: 360)
    }
}
