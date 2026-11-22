import SwiftUI
import MyFoldsCore

struct EditorLanguageMenu: View {
    @Bindable var document: TextDocumentSession
    var body: some View {
        Menu {
            Picker("语法高亮", selection: $document.languageOverride) {
                Text("自动识别").tag(SyntaxLanguage?.none)
                Divider()
                ForEach(SyntaxLanguage.allCases) { language in Text(language.title).tag(Optional(language)) }
            }
        } label: {
            Label(document.syntaxLanguage.title, systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 11)).foregroundStyle(.primary).lineLimit(1)
        }.menuStyle(.borderlessButton).fixedSize().help("语法高亮语言").accessibilityLabel("语法高亮语言")
    }
}
