import Foundation
import MyFoldsCore

@MainActor @Observable
final class ArchiveState {
    let url: URL
    private(set) var entries: [ArchiveItem] = []
    private(set) var visible: [ArchiveItem] = []
    var folder = "" { didSet { if oldValue != folder { project() } } }
    var selection: Set<String> = []
    var error: String?
    var loading = true
    @ObservationIgnored private var projectionTask: Task<Void, Never>?
    @ObservationIgnored private var projectionID = UUID()
    init(url: URL) { self.url = url }
    func load() async {
        do { entries = try await ArchiveService().list(url); project(); await projectionTask?.value }
        catch { self.error = error.localizedDescription; loading = false }
    }
    func enter(_ item: ArchiveItem) { if item.isDirectory { folder = item.path; selection = [] } }
    private func project() {
        projectionTask?.cancel()
        let snapshot = entries, directory = folder, request = UUID()
        projectionID = request; loading = true; visible = []
        projectionTask = Task {
            do {
                let result = try await ArchiveProjection.contents(snapshot, in: directory)
                try Task.checkCancellation()
                guard projectionID == request else { return }
                visible = result; loading = false
            } catch { /* Superseded folder projections never overwrite current content. */ }
        }
    }
}
