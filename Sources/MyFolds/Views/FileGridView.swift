import SwiftUI
import MyFoldsCore

struct FileGridView: View {
    @Environment(\.myfoldsSelectionText) private var selectionText
    @Environment(\.myfoldsAccentColor) private var accent
    @Bindable var session: FolderSession
    @Bindable var model: BrowserModel
    let isRight: Bool
    @FocusState private var focused: Bool
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 124, maximum: 155))], spacing: 22) {
                    ForEach(session.visible) { item in
                        Button { select(item) } label: {
                            VStack(spacing: 6) {
                                FileThumbnail(item: item).frame(width: 100, height: 78)
                                Text(item.name).font(.system(size: 12)).lineLimit(2)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .foregroundStyle(session.selection.contains(item.url) ? selectionText : Color.primary)
                                    .background(session.selection.contains(item.url) ? accent : .clear, in: .rect(cornerRadius: 4))
                                Text(item.isDirectory ? "文件夹" : ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file)).font(.caption).foregroundStyle(.secondary)
                            }.frame(width: 124, height: 130).contentShape(.rect)
                                .opacity(model.cutURLs.contains(item.url) ? 0.5 : 1)
                        }
                        .buttonStyle(.plain).focusEffectDisabled()
                        .accessibilityAddTraits(session.selection.contains(item.url) ? .isSelected : [])
                        .simultaneousGesture(TapGesture(count: 2).onEnded { model.rightActive = isRight; model.open(item) })
                        .modifier(FolderDropTarget(item: item, model: model))
                        .onDrag { NSItemProvider(object: item.url as NSURL) }
                        .anchorPreference(key: GridItemBounds.self, value: .bounds) { [item.url: $0] }
                    }
                }.padding(18)
            }.focusable().focused($focused).focusEffectDisabled()
                .onKeyPress(.space) { model.quickLook(); return .handled }
                .onKeyPress(.return) { model.requestName(rename: true); return .handled }
                .onKeyPress(.leftArrow) { step(-1); return .handled }
                .onKeyPress(.rightArrow) { step(1); return .handled }
                .onKeyPress(.upArrow) { step(-max(1, Int(geometry.size.width / 142))); return .handled }
                .onKeyPress(.downArrow) { step(max(1, Int(geometry.size.width / 142))); return .handled }
        }
        .overlayPreferenceValue(GridItemBounds.self) { anchors in
            GeometryReader { geometry in
                ContextMenuArea { point, window in
                    let item = session.visible.first { item in anchors[item.url].map { geometry[$0].contains(point) } ?? false }
                    return FileMenuFactory.make(model: model, session: session, item: item, window: window)
                }
            }
        }
    }
    private func select(_ item: FileItem) {
        focused = true
        model.rightActive = isRight
        if NSEvent.modifierFlags.contains(.command) {
            if !session.selection.insert(item.url).inserted { session.selection.remove(item.url) }
        } else if NSEvent.modifierFlags.contains(.shift), let anchor = session.visible.firstIndex(where: { session.selection.contains($0.url) }), let index = session.visible.firstIndex(of: item) {
            session.selection.formUnion(session.visible[min(anchor, index)...max(anchor, index)].map(\.url))
        } else { session.selection = [item.url] }
    }
    private func step(_ delta: Int) {
        let items = session.visible; guard !items.isEmpty else { return }
        let index = items.firstIndex { session.selection.contains($0.url) } ?? 0
        session.selection = [items[min(items.count - 1, max(0, index + delta))].url]
    }
}
