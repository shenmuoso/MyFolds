import SwiftUI
import UniformTypeIdentifiers
import MyFoldsCore

struct OpeningSettings: View {
    @Bindable var preferences: Preferences
    @Environment(\.colorScheme) private var scheme
    @State private var suffix = ""
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("后缀规则优先，其次是精确类型规则和文件类别。各类别独立设置，仅在 MyFolds 中生效。").font(.system(size: 11)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("文件后缀").font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
                VStack(spacing: 0) {
                    HStack {
                        TextField("输入后缀，如 md、jpg、tar.gz", text: $suffix).textFieldStyle(.plain)
                            .accessibilityLabel("文件后缀").onSubmit(addRule)
                        Button("添加规则…", systemImage: "plus", action: addRule).disabled(suffix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.frame(minHeight: 44)
                    if let error { Text(error).font(.caption).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10) }
                    ForEach(preferences.extensionRules.keys.sorted(), id: \.self) { ext in
                        Divider().opacity(0.3)
                        ApplicationRuleRow(title: "." + ext, subtitle: "优先于文件类型规则", symbol: "doc", applicationPath: preferences.extensionRules[ext], contentTypes: [UTType(filenameExtension: ext) ?? .data], resetTitle: "删除此后缀规则", allowsBuiltIn: true) {
                            preferences.extensionRules[ext] = $0
                        }
                    }
                }.padding(.horizontal, 12).background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("文件类型").font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
                VStack(spacing: 0) {
                    ForEach(OpeningCategory.allCases) { category in
                        if category != OpeningCategory.allCases.first { Divider().opacity(0.3) }
                        ApplicationRuleRow(title: category.title, subtitle: category.sampleDescription, symbol: category.symbol, applicationPath: preferences.categoryRules[category.rawValue], contentTypes: category.contentTypes, fallbackTitle: category.supportsBuiltIn ? Preferences.builtInTitle : "系统默认应用", resetTitle: "恢复此类别默认值", allowsBuiltIn: category.supportsBuiltIn) {
                            preferences.categoryRules[category.rawValue] = $0
                        }
                    }
                }.padding(.horizontal, 12).background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
            }
            if !preferences.applicationRules.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已有的精确类型规则").font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12)
                    VStack(spacing: 0) {
                        ForEach(preferences.applicationRules.keys.sorted(), id: \.self) { type in
                            ApplicationRuleRow(title: UTType(type)?.localizedDescription ?? type, subtitle: type, symbol: "doc", applicationPath: preferences.applicationRules[type], contentTypes: [UTType(type) ?? .data], resetTitle: "删除此类型规则", allowsBuiltIn: true) {
                                preferences.applicationRules[type] = $0
                            }
                        }
                    }.padding(.horizontal, 12).background(Color.white.opacity(scheme == .dark ? 0.11 : 0.27), in: .rect(cornerRadius: 12))
                }
            }
        }.font(.system(size: 13)).controlSize(.small)
    }
    private func addRule() {
        guard let ext = OpeningRules.normalizedExtension(suffix) else { error = "请输入有效后缀，例如 md 或 tar.gz，不要输入文件路径。"; return }
        error = nil
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "添加规则"; panel.message = "选择打开 .\(ext) 文件的应用。"
        if panel.runModal() == .OK, let app = panel.url { preferences.extensionRules[ext] = app.path; suffix = "" }
    }
}
