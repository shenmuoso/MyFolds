import AppKit
import Observation
import MyFoldsCore

@MainActor @Observable
final class EditorSearchModel {
    var visible = false
    var showsReplace = false
    var showsResults = false
    var focusRequest = UUID()
    var query = "" { didSet { if query != oldValue { refresh() } } }
    var replacement = "" {
        didSet {
            guard replacement != oldValue else { return }
            replacementTask?.cancel(); replacementGeneration = UUID(); replacing = false
            if !result.ranges.isEmpty { error = nil }
            message = nil
        }
    }
    var options = TextSearchOptions() { didSet { if options != oldValue { refresh() } } }
    var wrap = true
    var selectionOnly = false {
        didSet {
            if selectionOnly && !oldValue { scope = selection.length > 0 ? selection : nil }
            if !selectionOnly { scope = nil }
            refresh()
        }
    }
    private(set) var result = TextSearchResult.empty
    private(set) var currentIndex: Int?
    private(set) var searching = false
    private(set) var replacing = false
    private(set) var selection = NSRange(location: 0, length: 0)
    private(set) var error: String?
    private(set) var message: String?
    @ObservationIgnored private weak var view: EditorTextView?
    @ObservationIgnored private var scope: NSRange?
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var replacementTask: Task<Void, Never>?
    @ObservationIgnored private var revision = 0
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var replacementGeneration = UUID()
    @ObservationIgnored private var highlightViewport: NSRange?

    var ready: Bool { visible && !searching && !replacing && error == nil && !result.ranges.isEmpty }
    var status: String {
        if searching { return "正在查找…" }
        if query.isEmpty { return "输入查找内容" }
        if let currentIndex { return "\(currentIndex + 1) / \(result.ranges.count)" }
        return "\(result.ranges.count) 处匹配"
    }
    func attach(_ textView: EditorTextView) {
        view = textView; selection = textView.selectedRange()
        if visible { refresh() }
    }
    func detach() { cancel(); clearHighlights(); view = nil }
    func cancel() { searchTask?.cancel(); replacementTask?.cancel(); generation = UUID(); searching = false; replacing = false }
    func open(replace: Bool) {
        showsReplace = replace; visible = true
        if let view, selection.length > 0, selection.length < 512, !selectionOnly {
            query = (view.string as NSString).substring(with: selection)
        }
        focusRequest = UUID(); refresh()
    }
    func close() {
        visible = false; showsResults = false; cancel(); clearHighlights()
        if let view { view.window?.makeFirstResponder(view) }
    }
    func contentChanged(reloaded: Bool = false) {
        revision += 1
        if reloaded { scope = nil; selectionOnly = false }
        refresh()
    }
    func willEdit(_ range: NSRange, replacement: String?) {
        guard let old = scope, let replacement else { return }
        let delta = (replacement as NSString).length
        let end = NSMaxRange(range), oldEnd = NSMaxRange(old)
        let start = range.location < old.location ? (end <= old.location ? old.location + delta - range.length : range.location) : old.location
        let newEnd = end <= oldEnd ? oldEnd + delta - range.length : (range.location < oldEnd ? range.location + delta : oldEnd)
        scope = NSRange(location: max(0, start), length: max(0, newEnd - start))
    }
    func selectionChanged(_ value: NSRange) {
        selection = value
        currentIndex = result.ranges.firstIndex(of: value)
    }
    func refresh() {
        searchTask?.cancel(); replacementTask?.cancel(); replacing = false
        let request = UUID(); generation = request
        result = .empty; currentIndex = nil; error = nil; message = nil; clearHighlights()
        guard visible, !query.isEmpty, let view else { searching = false; return }
        if selectionOnly && scope == nil { searching = false; error = "请先在文稿中选择要查找的范围。"; return }
        let text = view.string, query = query, options = options, scope = scope, revision = revision
        searching = true
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(120))
                let result = try await TextSearchEngine.search(text, query: query, options: options, scope: scope)
                try Task.checkCancellation()
                guard let self, generation == request, self.revision == revision else { return }
                self.result = result; currentIndex = result.ranges.firstIndex(of: selection); searching = false
                redrawHighlights(force: true)
            } catch is CancellationError { }
            catch {
                guard let self, generation == request else { return }
                self.error = error.localizedDescription; searching = false
            }
        }
    }
    func navigate(backward: Bool = false) {
        guard ready, let index = target(backward: backward) else { return }
        select(index)
    }
    private func target(backward: Bool) -> Int? {
        let ranges = result.ranges
        guard !ranges.isEmpty else { return nil }
        if let currentIndex, ranges.indices.contains(currentIndex), ranges[currentIndex] == selection {
            let next = currentIndex + (backward ? -1 : 1)
            if ranges.indices.contains(next) { return next }
        } else if backward {
            if let index = ranges.lastIndex(where: { NSMaxRange($0) <= selection.location && $0 != selection }) { return index }
        } else if let index = ranges.firstIndex(where: { $0.location >= NSMaxRange(selection) }) { return index }
        if wrap { message = backward ? "已从末尾继续查找" : "已从开头继续查找"; return backward ? ranges.count - 1 : 0 }
        message = backward ? "已到文件开头" : "已到文件末尾"
        return nil
    }
    func select(_ index: Int) {
        guard ready, result.ranges.indices.contains(index), let view else { return }
        currentIndex = index; selection = result.ranges[index]
        view.setSelectedRange(selection); view.scrollRangeToVisible(selection)
        view.showFindIndicator(for: selection)
        redrawHighlights(force: true)
    }
    func replace(all: Bool) {
        guard ready, let view, !view.hasMarkedText() else { return }
        var single: NSRange?
        if !all {
            guard let index = currentIndex ?? target(backward: false) else { return }
            single = result.ranges[index]
        }
        let text = view.string, query = query, replacement = replacement, options = options, scope = scope
        let revision = revision, request = generation, operation = UUID()
        replacementGeneration = operation
        replacing = true; message = nil; error = nil
        replacementTask = Task { [weak self, weak view] in
            do {
                let plan = try await TextSearchEngine.replacement(text, query: query, replacement: replacement, options: options, scope: scope, only: single)
                try Task.checkCancellation()
                guard let self, let view, self.revision == revision, generation == request, replacementGeneration == operation else { return }
                replacing = false
                guard let plan else { return }
                if view.apply(plan, actionName: all ? "全部替换" : "替换") {
                    view.window?.makeFirstResponder(view)
                    message = "已替换 \(plan.count) 处 · ⌘Z 撤销"
                }
            } catch is CancellationError {
                if self?.replacementGeneration == operation { self?.replacing = false }
            } catch {
                guard let self, generation == request, replacementGeneration == operation else { return }
                self.error = error.localizedDescription; replacing = false
            }
        }
    }
    func redrawHighlights(force: Bool = false) {
        guard visible, let view, let layout = view.layoutManager, let container = view.textContainer else { return }
        let bounds = view.visibleRect.offsetBy(dx: -view.textContainerOrigin.x, dy: -view.textContainerOrigin.y)
        let glyphs = layout.glyphRange(forBoundingRect: bounds, in: container)
        let visibleRange = layout.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
        guard force || visibleRange != highlightViewport else { return }
        clearHighlights(); highlightViewport = visibleRange
        let ranges = result.ranges
        var low = 0, high = ranges.count
        while low < high {
            let middle = (low + high) / 2
            if NSMaxRange(ranges[middle]) < visibleRange.location { low = middle + 1 } else { high = middle }
        }
        for range in ranges.dropFirst(low) {
            if range.location > NSMaxRange(visibleRange) { break }
            if range.length > 0, NSMaxRange(range) <= (view.string as NSString).length { layout.addTemporaryAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.28), forCharacterRange: range) }
        }
    }
    private func clearHighlights() {
        highlightViewport = nil
        guard let view else { return }
        view.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: (view.string as NSString).length))
    }
}
