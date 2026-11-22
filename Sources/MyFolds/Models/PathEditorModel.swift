import Foundation
import MyFoldsCore

@MainActor @Observable
final class PathEditorModel {
    var editing = false
    var draft = ""
    private(set) var suggestions: [PathCompletion] = []
    var highlighted: Int?
    var completionError: String?
    @ObservationIgnored private var task: Task<Void, Never>?
    func begin(_ url: URL) {
        cancel(); draft = url.path; editing = true
    }
    func cancel() {
        task?.cancel(); editing = false; suggestions = []; highlighted = nil; completionError = nil
    }
    func typed(relativeTo base: URL, showHidden: Bool) {
        task?.cancel(); suggestions = []; highlighted = nil; completionError = nil
        let input = draft
        task = Task {
            do {
                try await Task.sleep(for: .milliseconds(120))
                let result = try await PathCompletionService.suggestions(for: input, relativeTo: base, showHidden: showHidden)
                try Task.checkCancellation()
                guard editing, draft == input else { return }
                suggestions = result
            } catch is CancellationError { }
            catch {
                guard editing, draft == input else { return }
                completionError = "无法读取候选路径，可直接输入完整路径后回车。"
            }
        }
    }
    func step(_ offset: Int) {
        guard !suggestions.isEmpty else { return }
        highlighted = min(suggestions.count - 1, max(0, (highlighted ?? (offset > 0 ? -1 : suggestions.count)) + offset))
    }
    func complete(relativeTo base: URL, showHidden: Bool) {
        let index = highlighted ?? 0
        guard suggestions.indices.contains(index) else { return }
        draft = suggestions[index].path
        typed(relativeTo: base, showHidden: showHidden)
    }
    var submittedPath: String {
        if let highlighted, suggestions.indices.contains(highlighted) { return suggestions[highlighted].path }
        return draft
    }
}
