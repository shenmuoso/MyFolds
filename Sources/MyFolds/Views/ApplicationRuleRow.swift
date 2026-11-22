import SwiftUI
import UniformTypeIdentifiers

struct ApplicationRuleRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let applicationPath: String?
    let contentTypes: [UTType]
    var fallbackTitle = "系统默认"
    var resetTitle = "使用系统默认"
    var allowsBuiltIn = false
    let change: (String?) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(.secondary).frame(width: 23)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                if !subtitle.isEmpty { Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 14)
            Menu {
                Button(resetTitle) { change(nil) }
                if allowsBuiltIn { Button(Preferences.builtInTitle, systemImage: "doc.viewfinder") { change(Preferences.builtInApplication) } }
                Button("系统默认应用", systemImage: "app") { change(Preferences.systemApplication) }
                Divider()
                ForEach(applications, id: \.self) { app in
                    Button { change(app.path) } label: {
                        Label { Text(app.deletingPathExtension().lastPathComponent) } icon: { Image(nsImage: NSWorkspace.shared.icon(forFile: app.path)) }
                    }
                }
                Divider()
                Button("选择其他应用…", systemImage: "folder") { choose() }
            } label: {
                HStack(spacing: 6) {
                    if let applicationPath, applicationPath.hasPrefix("/") {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: applicationPath)).resizable().frame(width: 16, height: 16)
                    }
                    Text(displayTitle).lineLimit(1)
                }.frame(maxWidth: 178, alignment: .trailing)
            }.menuStyle(.borderlessButton).fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("\(title)打开方式")
        }.frame(minHeight: 49)
    }
    private var displayTitle: String {
        switch applicationPath {
        case Preferences.builtInApplication: Preferences.builtInTitle
        case Preferences.systemApplication: "系统默认应用"
        case .some(let path): URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        case nil: fallbackTitle
        }
    }
    private var applications: [URL] {
        Array(Set(contentTypes.flatMap { NSWorkspace.shared.urlsForApplications(toOpen: $0) })).sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
    private func choose() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "选择应用"
        panel.message = "为\(title)选择在 MyFolds 中使用的应用。"
        if panel.runModal() == .OK, let url = panel.url { change(url.path) }
    }
}
