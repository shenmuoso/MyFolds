import SwiftUI

struct InspectorView: View {
    @Bindable var model: BrowserModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if model.selected.count == 1, let item = model.selected.first {
                    FileThumbnail(item: item).frame(maxWidth: .infinity).frame(height: 160)
                    Text(item.name).font(.headline).textSelection(.enabled)
                    LabeledContent("类型", value: item.kind)
                    LabeledContent("大小", value: ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                    LabeledContent("修改", value: item.modified.formatted(date: .abbreviated, time: .shortened))
                    if !item.isDirectory {
                        Button("快速预览", systemImage: "eye", action: model.quickLook)
                        Menu("打开方式") {
                            ForEach(model.applications(for: item), id: \.self) { app in
                                Button(app.deletingPathExtension().lastPathComponent) { model.openExternally(item, application: app) }
                            }
                            Button("其他应用…") { model.otherApplication(item) }
                        }
                        Menu("MyFolds 默认应用") {
                            ForEach(model.applications(for: item), id: \.self) { app in
                                Button(app.deletingPathExtension().lastPathComponent) { model.preferences.rememberApplication(app, for: item) }
                            }
                            Button("清除此文件类型的单独规则") { model.preferences.clearApplication(for: item) }
                        }
                    }
                    Text(item.url.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                } else {
                    Image(systemName: model.selected.isEmpty ? "folder" : "doc.on.doc").font(.system(size: 48)).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 30)
                    Text(model.selected.isEmpty ? model.active.directory.lastPathComponent : "已选 \(model.selected.count) 项").font(.headline)
                    Text("\(model.active.visible.count) 个项目").foregroundStyle(.secondary)
                }
            }.font(.system(size: 12)).padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }.background(Color.primary.opacity(0.025))
    }
}
