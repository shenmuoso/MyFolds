import SwiftUI

struct OperationBar: View {
    @Bindable var model: BrowserModel
    var body: some View {
        HStack(spacing: 12) {
            if model.busy {
                if model.taskProgress > 0 { ProgressView(value: model.taskProgress).frame(width: 90) }
                else { ProgressView().controlSize(.small).frame(width: 26) }
                VStack(alignment: .leading, spacing: 3) { Text(model.taskTitle); Text(model.taskDetail).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                Spacer(); Button("取消", action: model.cancelTask)
            } else {
                Image(systemName: "scissors"); Text("\(model.cutURLs.count) 项等待移动")
                Spacer(); Button("移动到这里", action: model.paste)
                Button("取消待移动") { model.cutURLs = [] }
            }
        }.font(.callout).padding(12).background(.regularMaterial)
    }
}
