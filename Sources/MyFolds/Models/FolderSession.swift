import Foundation
import MyFoldsCore

@MainActor @Observable
final class FolderSession: Identifiable {
    let id = UUID()
    var directory: URL
    private(set) var entries: [FileItem] = []
    private(set) var visible: [FileItem] = []
    var selection: Set<URL> = []
    var query = "" { didSet { if oldValue != query { project(debounce: true) } } }
    var resolving = false
    @ObservationIgnored var navigationRequest = UUID()
    var grid = false
    var sort = "name" { didSet { if oldValue != sort { project() } } }
    var ascending = true { didSet { if oldValue != ascending { project() } } }
    var foldersFirst = true { didSet { if oldValue != foldersFirst { project() } } }
    var history: [URL] = []
    var future: [URL] = []
    private(set) var loading = false
    private(set) var filtering = false
    var error: String?
    var archive: ArchiveState?
    let pathEditor = PathEditorModel()
    @ObservationIgnored private let service = DirectoryService()
    @ObservationIgnored private let loadContents: (@Sendable (URL, Bool) async throws -> [FileItem])?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var projectionTask: Task<Void, Never>?
    @ObservationIgnored private var loadedDirectory: URL?
    @ObservationIgnored private var readingDirectory: URL?
    @ObservationIgnored private var readingHidden = false
    @ObservationIgnored private var loadID = UUID()
    @ObservationIgnored private var projectionID = UUID()
    @ObservationIgnored var navigationTask: Task<Void, Never>?
    init(directory: URL, loadContents: (@Sendable (URL, Bool) async throws -> [FileItem])? = nil) {
        self.directory = directory; self.loadContents = loadContents
    }
    var isInTrash: Bool { TrashLocation.contains(directory) }
    var displayName: String { directory.standardizedFileURL == TrashLocation.root ? "废纸篓" : directory.lastPathComponent.isEmpty ? "/" : directory.lastPathComponent }
    var selected: [FileItem] { visible.filter { selection.contains($0.url) } }
    var projection: DirectoryProjection { DirectoryProjection(query: query, sort: sort, ascending: ascending, foldersFirst: foldersFirst) }
    func navigate(_ url: URL, hidden: Bool, record: Bool = true) {
        navigationTask?.cancel(); navigationRequest = UUID(); resolving = false
        let url = url.standardizedFileURL
        if record && url != directory { history.append(directory); future = [] }
        if directory != url { entries = []; visible = []; loadedDirectory = nil }
        directory = url; selection = []; query = ""; archive = nil; pathEditor.cancel()
        reload(hidden: hidden)
    }
    func reload(hidden: Bool) {
        // Never repeatedly cancel a slow disk read from the periodic refresh.
        guard readingDirectory != directory || readingHidden != hidden else { return }
        loadTask?.cancel(); projectionTask?.cancel()
        let url = directory, request = UUID()
        loadID = request; readingDirectory = url; readingHidden = hidden
        loading = loadedDirectory != url; error = nil
        loadTask = Task {
            do {
                let result: [FileItem]
                if let loadContents { result = try await loadContents(url, hidden) }
                else { result = try await service.contents(of: url, showHidden: hidden) }
                try Task.checkCancellation()
                guard loadID == request, directory == url else { return }
                entries = result
                selection.formIntersection(Set(result.map(\.url)))
                loadedDirectory = url; readingDirectory = nil
                project()
            } catch is CancellationError { }
            catch {
                guard loadID == request, directory == url else { return }
                self.error = error.localizedDescription; entries = []; visible = []
                loadedDirectory = url; readingDirectory = nil; loading = false; filtering = false
            }
        }
    }
    private func project(debounce: Bool = false) {
        projectionTask?.cancel()
        let request = UUID(), url = directory, snapshot = entries, options = projection
        projectionID = request; filtering = true
        projectionTask = Task {
            do {
                if debounce { try await Task.sleep(for: .milliseconds(90)) }
                let result = try await options.apply(to: snapshot)
                try Task.checkCancellation()
                guard projectionID == request, directory == url else { return }
                visible = result; filtering = false
                if loadedDirectory == url { loading = false }
            } catch { /* A superseded projection never replaces the newer result. */ }
        }
    }
    func cancelWork() {
        loadTask?.cancel(); projectionTask?.cancel(); navigationTask?.cancel(); pathEditor.cancel()
    }
    func back(hidden: Bool) {
        if let archive {
            if archive.folder.isEmpty { self.archive = nil }
            else { archive.folder = (archive.folder as NSString).deletingLastPathComponent; archive.selection = [] }
            return
        }
        guard let previous = history.popLast() else { return }
        future.append(directory); navigate(previous, hidden: hidden, record: false)
    }
    func forward(hidden: Bool) {
        guard let next = future.popLast() else { return }
        history.append(directory); navigate(next, hidden: hidden, record: false)
    }
}
