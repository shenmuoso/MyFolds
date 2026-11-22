import SwiftUI
import MyFoldsCore

struct PathBar: View {
    @Environment(\.myfoldsAccentColor) private var accent
    @Environment(\.myfoldsSubtleAccent) private var subtleAccent
    @Environment(\.myfoldsAccentInk) private var focusColor
    @Bindable var model: BrowserModel
    @Bindable var session: FolderSession
    let isRight: Bool
    @Environment(\.myfoldsReduceMotion) private var reduced
    @State private var fieldFocused = false
    private var active: Bool { !model.split || model.rightActive == isRight }
    var body: some View {
        @Bindable var editor = session.pathEditor
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: session.archive == nil ? "folder" : "doc.zipper")
                    .foregroundStyle(BrowserChrome.pathText)
                if editor.editing {
                    NativePathField(text: $editor.draft, submit: submit, cancel: editor.cancel,
                                    changed: { editor.typed(relativeTo: session.directory, showHidden: model.preferences.showHidden) },
                                    step: editor.step, complete: { editor.complete(relativeTo: session.directory, showHidden: model.preferences.showHidden) },
                                    focusChanged: { fieldFocused = $0 })
                        .frame(height: 24)
                } else {
                    Button {
                        model.rightActive = isRight
                        editor.begin(session.archive?.url ?? session.directory)
                    } label: {
                        HStack {
                            Text(session.archive.map { $0.url.path + " › /" + $0.folder } ?? session.directory.path)
                                .lineLimit(1).truncationMode(.middle)
                            Spacer(minLength: 0)
                            if active { Text("⌘L").font(.system(size: 10)).foregroundStyle(BrowserChrome.pathText) }
                        }.frame(maxWidth: .infinity, minHeight: BrowserChrome.controlHeight).contentShape(.rect)
                    }.buttonStyle(.plain).accessibilityLabel("编辑完整路径").help(session.directory.path)
                        .accessibilityIdentifier(isRight ? "path.right" : "path.primary")
                }
            }.padding(.horizontal, 10).frame(height: BrowserChrome.controlHeight)
                .foregroundStyle(BrowserChrome.pathText)
                .background(subtleAccent, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(focusColor.opacity(editor.editing && fieldFocused ? 0.85 : 0), lineWidth: 2)
                        .allowsHitTesting(false)
                }
                .animation(BrowserMotion.feedback(reduced), value: fieldFocused && editor.editing)
                .onChange(of: editor.editing) { if !editor.editing { fieldFocused = false } }
                .contentShape(.rect)
                .onTapGesture { model.rightActive = isRight; if !editor.editing { editor.begin(session.directory) } }
                .overlay(alignment: .topLeading) {
                    if editor.editing && !editor.suggestions.isEmpty {
                        VStack(spacing: 2) {
                            ForEach(Array(editor.suggestions.enumerated()), id: \.element.id) { index, match in
                                Button { editor.draft = match.path; editor.highlighted = nil; submit() } label: {
                                    Label(match.path, systemImage: match.isDirectory ? "folder" : "doc")
                                        .lineLimit(1).truncationMode(.middle).frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10).frame(height: 29)
                                        .background(editor.highlighted == index ? accent.opacity(0.22) : .clear, in: .rect(cornerRadius: 6))
                                }.buttonStyle(.plain)
                            }
                            Text("↑ ↓ 选择 · Tab 补全 · 回车前往").font(.system(size: 10)).foregroundStyle(.secondary).padding(.vertical, 6)
                        }.foregroundStyle(Color.primary).padding(5).background(.regularMaterial, in: .rect(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                            .offset(y: 38).transition(.opacity)
                    }
                }
            Button {
                model.rightActive = isRight
                NSPasteboard.general.clearContents(); NSPasteboard.general.setString(session.directory.path, forType: .string)
            } label: { Image(systemName: "doc.on.doc").frame(width: 26, height: BrowserChrome.controlHeight) }
                .buttonStyle(.plain).help("复制当前文件夹完整路径").accessibilityLabel("复制当前文件夹完整路径")
                .accessibilityIdentifier(isRight ? "copyPath.right" : "copyPath.primary")
        }.font(.system(size: 11, design: .monospaced)).padding(.horizontal, 10).padding(.vertical, 6)
            .animation(BrowserMotion.feedback(reduced), value: active)
    }
    private func submit() {
        model.rightActive = isRight
        do { model.go(try DirectoryService.resolve(session.pathEditor.submittedPath, relativeTo: session.directory), session: session) }
        catch { model.message = error.localizedDescription }
    }
}
