import Foundation
import Observation
import MyFoldsCore

@MainActor @Observable
final class FileViewerState {
    let item: FileItem
    let kind: BuiltInViewer
    let document: TextDocumentSession?
    var actualSize = false
    var markdownMode = "split"
    func openSearch(replace: Bool) {
        if markdownMode == "preview" { markdownMode = "edit" }
        document?.search.open(replace: replace)
    }
    init(item: FileItem, kind: BuiltInViewer) {
        self.item = item; self.kind = kind
        document = kind.isEditable ? TextDocumentSession(url: item.url) : nil
    }
}
