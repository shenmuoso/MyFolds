import SwiftUI

struct FileViewerView: View {
    @Bindable var state: FileViewerState
    @Bindable var preferences: Preferences
    let save: () -> Void
    let saveCopy: () -> Void
    let reload: () -> Void
    let external: () -> Void
    @Environment(\.myfoldsReduceMotion) private var reduced
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                WindowControls().frame(width: 70, height: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.item.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    if let document = state.document { Text(document.saving ? "正在保存…" : document.dirty ? "已编辑" : document.encoding.label).font(.system(size: 10)).foregroundStyle(.secondary) }
                }
                Spacer()
                if state.kind == .markdown {
                    Picker("Markdown 显示方式", selection: $state.markdownMode) {
                        Text("编辑").tag("edit"); Text("分栏").tag("split"); Text("预览").tag("preview")
                    }.pickerStyle(.segmented).labelsHidden().frame(width: 180)
                }
                if state.kind == .image { Button(state.actualSize ? "适合窗口" : "100%") { state.actualSize.toggle() }.buttonStyle(.borderless) }
                if let document = state.document {
                    Menu("查找与替换", systemImage: "magnifyingglass") {
                        Button("查找… \(preferences.editor.findShortcut.label)") { state.openSearch(replace: false) }
                        Button("替换… \(preferences.editor.replaceShortcut.label)") { state.openSearch(replace: true) }
                    }.labelStyle(.iconOnly).disabled(document.loading)
                    EditorLanguageMenu(document: document)
                    Button(action: save) { Label("保存", systemImage: "square.and.arrow.down") }
                        .disabled(document.loading || document.saving || !document.dirty)
                        .help("保存 ⌘S")
                }
                Button(action: external) { Image(systemName: "arrow.up.forward.app") }.help("用其他应用打开").accessibilityLabel("用其他应用打开")
            }.tint(.primary).padding(.horizontal, 18).frame(height: 60).background { WindowDragArea() }
            if let document = state.document {
                if document.loading { ProgressView("正在读取文稿…").frame(maxWidth: .infinity, maxHeight: .infinity) }
                else if document.revision != nil {
                    if document.search.visible { EditorSearchBar(search: document.search).transition(.opacity) }
                    HStack(spacing: 0) {
                        if state.kind == .text || state.markdownMode != "preview" {
                            NativeTextEditor(document: document, preferences: preferences).frame(maxWidth: .infinity).transition(.opacity)
                        }
                        if state.kind == .markdown && state.markdownMode != "edit" {
                            if state.markdownMode == "split" { Divider().opacity(0.25) }
                            MarkdownPreview(text: document.text, url: state.item.url).frame(maxWidth: .infinity).transition(.opacity)
                        }
                    }.animation(BrowserMotion.content(reduced), value: state.markdownMode)
                    if document.search.visible && document.search.showsResults { EditorSearchResults(search: document.search) }
                    EditorStatusBar(document: document, preferences: preferences)
                }
                if let error = document.error {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(error).font(.system(size: 12))
                        HStack {
                            Button("重新载入…", action: reload)
                            if document.revision != nil { Button("另存为…", action: saveCopy) }
                            Button("用其他应用打开", action: external)
                        }
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.045))
                }
            } else {
                Group {
                    switch state.kind {
                    case .image: ImagePreview(url: state.item.url, actualSize: state.actualSize)
                    case .video: VideoPreview(url: state.item.url)
                    case .pdf: PDFPreview(url: state.item.url)
                    default: EmptyView()
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.frame(minWidth: 620, minHeight: 420).ignoresSafeArea()
            .animation(BrowserMotion.content(reduced), value: state.document?.search.visible)
            .animation(BrowserMotion.content(reduced), value: state.document?.search.showsReplace)
            .animation(BrowserMotion.content(reduced), value: state.document?.search.showsResults)
            .task { await state.document?.load() }
            .onChange(of: preferences.editor.fontSize) { state.document?.fontSizeOverride = nil }
            .onChange(of: state.markdownMode) { if state.markdownMode == "preview" { state.document?.search.close() } }
    }
}
