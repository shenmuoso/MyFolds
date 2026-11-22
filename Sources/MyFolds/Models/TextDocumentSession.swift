import Foundation
import Observation
import MyFoldsCore

@MainActor @Observable
final class TextDocumentSession {
    let url: URL
    var text = "" { didSet { onChange?() } }
    private(set) var savedText = ""
    private(set) var encoding: TextFileEncoding = .utf8
    private(set) var revision: Data?
    private(set) var loading = true
    private(set) var saving = false
    var error: String?
    var reloadToken = UUID()
    var languageOverride: SyntaxLanguage?
    let search = EditorSearchModel()
    var fontSizeOverride: Double?
    var cursorLine = 1
    var cursorColumn = 1
    var syntaxLanguage: SyntaxLanguage { languageOverride ?? SyntaxLanguage.detect(url: url, text: text) }
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let store = TextDocumentStore()
    init(url: URL) { self.url = url }
    var dirty: Bool { text != savedText }
    func load() async {
        guard !saving else { return }
        loading = true; error = nil
        do {
            let snapshot = try await store.read(url)
            try Task.checkCancellation()
            savedText = snapshot.text; text = snapshot.text
            encoding = snapshot.encoding; revision = snapshot.revision; reloadToken = UUID()
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
        loading = false; onChange?()
    }
    @discardableResult func save() async -> Bool {
        guard !loading, !saving, revision != nil else { return false }
        saving = true; error = nil
        let contents = text
        defer { saving = false; onChange?() }
        do {
            revision = try await store.save(contents, to: url, encoding: encoding, expectedRevision: revision)
            savedText = contents
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func saveCopy(to destination: URL) async throws {
        _ = try await store.save(text, to: destination, encoding: encoding, expectedRevision: nil)
    }
}
